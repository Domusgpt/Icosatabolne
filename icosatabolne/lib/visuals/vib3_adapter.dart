import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icosatabolne/visuals/vib3_shim.dart';
import 'fallback_painter.dart';

class Vib3Adapter extends StatefulWidget {
  final Vib3Config config;
  final double width;
  final double height;
  final bool animate;
  final double chaos;
  final double speed;
  final double hue;
  final double saturation;
  final double intensity;
  final Vib3Engine? sharedEngine; // Optional shared engine

  const Vib3Adapter({
    super.key,
    required this.config,
    this.width = 100,
    this.height = 100,
    this.animate = true,
    this.chaos = 0.0,
    this.speed = 1.0,
    this.hue = 200,
    this.saturation = 0.8,
    this.intensity = 0.9,
    this.sharedEngine,
  });

  @override
  State<Vib3Adapter> createState() => _Vib3AdapterState();
}

class _Vib3AdapterState extends State<Vib3Adapter> with SingleTickerProviderStateMixin {
  Vib3Engine? _engine;
  bool _useFallback = false;
  late AnimationController _controller;
  bool _isShared = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.animate) {
      _controller.repeat();
    }

    _initEngine();
  }

  Future<void> _initEngine() async {
    // Check platform first. We only support mobile for the native engine.
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      if (mounted) setState(() => _useFallback = true);
      return;
    }

    if (widget.sharedEngine != null) {
      _engine = widget.sharedEngine;
      _isShared = true;
      if (mounted) setState(() {});
      return;
    }

    // Otherwise create a new one (legacy/fallback behavior)
    try {
      _engine = Vib3Engine();
      await _engine!.initialize(widget.config);
      await _engine!.setVisualParams(
        intensity: widget.intensity,
        saturation: widget.saturation,
        chaos: widget.chaos,
        speed: widget.speed,
        hue: widget.hue,
      );
      await _engine!.startRendering();

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Vib3 Engine Init Failed: $e");
      if (mounted) setState(() => _useFallback = true);
    }
  }

  @override
  void didUpdateWidget(Vib3Adapter oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If using shared engine, we DO NOT update params here because it would affect all instances.
    // Shared engine params should be updated by the manager (GameScreen).
    if (_isShared) return;

    if (_engine != null && _engine!.isInitialized) {
      if (widget.config.system != oldWidget.config.system) {
        _engine!.setSystem(widget.config.system);
      }
      if (widget.config.geometry != oldWidget.config.geometry) {
        _engine!.setGeometry(widget.config.geometry);
      }

      if (widget.chaos != oldWidget.chaos ||
          widget.speed != oldWidget.speed ||
          widget.hue != oldWidget.hue ||
          widget.saturation != oldWidget.saturation ||
          widget.intensity != oldWidget.intensity) {
        _engine!.setVisualParams(
          chaos: widget.chaos,
          speed: widget.speed,
          hue: widget.hue,
          saturation: widget.saturation,
          intensity: widget.intensity,
        );
      }
    }
  }

  @override
  void dispose() {
    // Only dispose if we own the engine
    if (!_isShared) {
      _engine?.stopRendering();
      _engine?.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_useFallback) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: FallbackPainter(
              config: widget.config,
              animationValue: _controller.value * 2 * 3.14159,
              chaos: widget.chaos,
              speed: widget.speed,
              hue: widget.hue,
            ),
          );
        },
      );
    }

    if (_engine == null || !_engine!.isInitialized || _engine!.textureId == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.black12,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Vib3View(engine: _engine!),
    );
  }
}
