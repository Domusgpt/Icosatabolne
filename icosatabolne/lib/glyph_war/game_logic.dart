import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

enum GlyphWarPhase { scramble, attack, gameOver }

class Glyph {
  final String id;
  final String char;
  String? heldByPlayerId; // null if in pile
  bool isStashed = false;
  String? tuggedByPlayerId; // visual indicator of conflict

  Glyph(this.id, this.char);
}

class PlayerState {
  final String id;
  List<Glyph> currentWord = [];
  Glyph? stashedGlyph;
  bool isAttacking = false;

  PlayerState(this.id);

  String get wordString => currentWord.map((g) => g.char).join('');
  int get wordLength => currentWord.length;
}

class GlyphWarController extends ChangeNotifier {
  GlyphWarPhase phase = GlyphWarPhase.scramble;
  final List<Glyph> _allGlyphs = [];

  late final PlayerState player1;
  late final PlayerState player2;

  Timer? _gameTimer;
  Timer? _attackTimer;

  double tension = 0.0;
  int attackTimeRemaining = 0;
  String? winnerId;

  // Game Configuration
  static const int attackDurationSeconds = 10;

  GlyphWarController() {
    player1 = PlayerState('P1');
    player2 = PlayerState('P2');
    _initializeGame();
  }

  void _initializeGame() {
    // Initialize with a set of letters suitable for "STREAMLINE" example + extras
    // "S-T-R-E-A-M-L-I-N-E"
    const String initialPool = "STREAMLINE" "ABCDE" "XYZ";
    // Mix them up
    final List<String> chars = initialPool.split('')..shuffle();

    _allGlyphs.clear();
    for (int i = 0; i < chars.length; i++) {
      _allGlyphs.add(Glyph('g_$i', chars[i]));
    }

    phase = GlyphWarPhase.scramble;
    tension = 0.0;
    notifyListeners();
  }

  List<Glyph> get pile => _allGlyphs.where((g) => g.heldByPlayerId == null).toList();
  List<Glyph> get player1Word => player1.currentWord;
  List<Glyph> get player2Word => player2.currentWord;

  // Actions

  void grabGlyph(String glyphId, String playerId) {
    if (phase == GlyphWarPhase.gameOver) return;

    // Check if player is attacking (locked)
    final player = playerId == player1.id ? player1 : player2;
    if (player.isAttacking) return; // Locked during attack?
    // Design spec: "During these 10 seconds, your word is locked. You cannot change it."

    final glyph = _allGlyphs.firstWhere((g) => g.id == glyphId);

    // Can only grab from pile or if it's already yours (reordering)
    if (glyph.heldByPlayerId == null) {
      glyph.heldByPlayerId = playerId;
      glyph.isStashed = false;
      player.currentWord.add(glyph);
      _updateTension();
      notifyListeners();
    } else if (glyph.heldByPlayerId == playerId && !glyph.isStashed) {
      // Reordering handled by UI usually, but we can support move to end here
      player.currentWord.remove(glyph);
      player.currentWord.add(glyph);
      notifyListeners();
    }
  }

  void stashGlyph(String glyphId, String playerId) {
    if (phase == GlyphWarPhase.gameOver) return;
    final player = playerId == player1.id ? player1 : player2;
    if (player.isAttacking) return;

    final glyph = _allGlyphs.firstWhere((g) => g.id == glyphId);

    // Check ownership or availability
    if (glyph.heldByPlayerId != null && glyph.heldByPlayerId != playerId) return;

    // If grabbing from pile directly to stash
    if (glyph.heldByPlayerId == null) {
      glyph.heldByPlayerId = playerId;
    }

    // Swap with existing stash if any
    if (player.stashedGlyph != null) {
      final oldStash = player.stashedGlyph!;
      oldStash.isStashed = false;
      player.currentWord.add(oldStash); // Returns to word or pile? "Pivot: You stash the 'Y'... pull the 'Y' from your stash"
      // Let's say it swaps into the word for now
    }

    player.currentWord.remove(glyph);
    player.stashedGlyph = glyph;
    glyph.isStashed = true;
    _updateTension();
    notifyListeners();
  }

  void unstashGlyph(String playerId) {
    if (phase == GlyphWarPhase.gameOver) return;
    final player = playerId == player1.id ? player1 : player2;
    if (player.isAttacking) return;

    if (player.stashedGlyph != null) {
      final glyph = player.stashedGlyph!;
      glyph.isStashed = false;
      player.currentWord.add(glyph);
      player.stashedGlyph = null;
      notifyListeners();
    }
  }

  void dissolveWord(String playerId) {
    if (phase == GlyphWarPhase.gameOver) return;
    final player = playerId == player1.id ? player1 : player2;
    if (player.isAttacking) return; // Locked

    // Release all non-stashed glyphs
    for (final glyph in List<Glyph>.from(player.currentWord)) {
      glyph.heldByPlayerId = null;
      glyph.tuggedByPlayerId = null;
    }
    player.currentWord.clear();

    // Visual effect trigger (handled by UI listening to change)
    _updateTension();
    notifyListeners();
  }

  void tugGlyph(String glyphId, String requestingPlayerId) {
    final glyph = _allGlyphs.firstWhere((g) => g.id == glyphId);
    if (glyph.heldByPlayerId != null && glyph.heldByPlayerId != requestingPlayerId) {
      glyph.tuggedByPlayerId = requestingPlayerId;
      notifyListeners();

      // Clear tug after short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (glyph.tuggedByPlayerId == requestingPlayerId) {
          glyph.tuggedByPlayerId = null;
          notifyListeners();
        }
      });
    }
  }

  void startAttack(String playerId) {
    if (phase != GlyphWarPhase.scramble) return;
    final attacker = playerId == player1.id ? player1 : player2;
    if (!isValidWord(attacker.wordString)) return;

    phase = GlyphWarPhase.attack;
    attacker.isAttacking = true;
    attackTimeRemaining = attackDurationSeconds;

    _attackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      attackTimeRemaining--;
      if (attackTimeRemaining <= 0) {
        _endAttack(playerId); // Attacker wins if defender didn't beat them
      } else {
        notifyListeners();
      }
    });

    notifyListeners();
  }

  void _checkForCounterAttack() {
    if (phase != GlyphWarPhase.attack) return;

    final attacker = player1.isAttacking ? player1 : player2;
    final defender = player1.isAttacking ? player2 : player1;

    if (defender.wordLength > attacker.wordLength) {
      // Defender successfully countered!
      _attackTimer?.cancel();
      attacker.isAttacking = false;
      // Roles switch immediately
      phase = GlyphWarPhase.scramble; // Reset phase to allow new attack
      startAttack(defender.id);
    }
  }

  bool isValidWord(String word) {
    return word.length >= 2;
  }

  void _endAttack(String attackerId) {
    _attackTimer?.cancel();
    final attacker = attackerId == player1.id ? player1 : player2;
    final defender = attackerId == player1.id ? player2 : player1;

    // If timer runs out and defender hasn't countered
    // Also check if attacker has a valid word still?
    // "If they fail, you win."

    if (defender.wordLength <= attacker.wordLength) {
      phase = GlyphWarPhase.gameOver;
      winnerId = attackerId;
    } else {
        // Defender won by waiting out clock with longer word?
        // "If they succeed... the timer resets" -> handled in _checkForCounterAttack
        // So here we only reach if defender FAILED to counter in time.
    }
    notifyListeners();
  }

  void _updateTension() {
    _checkForCounterAttack();
    // Simple heuristic for tension based on letters in play vs pile
    final totalLetters = _allGlyphs.length;
    final lettersInPlay = player1.wordLength + player2.wordLength;
    tension = lettersInPlay / totalLetters;
    // Clamp
    if (tension > 1.0) tension = 1.0;
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _attackTimer?.cancel();
    super.dispose();
  }
}
