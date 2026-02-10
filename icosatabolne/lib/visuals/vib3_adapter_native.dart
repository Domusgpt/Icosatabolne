import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:icosatabolne/visuals/game_config.dart';
import 'package:icosatabolne/visuals/fallback_painter.dart';
import 'package:icosatabolne/visuals/shader_painter.dart';
import 'package:vib3_flutter/vib3_flutter.dart';

class Vib3Adapter extends StatefulWidget {
  final GameVib3Config config;
  final double width;
  final double height;
  final bool animate;
  final double chaos;
  final double speed;
  final double hue;
  final double saturation;
  final double intensity;

  // Advanced Params (Optional - if null, auto-derived)
  final double? rotXY;
  final double? rotXZ;
  final double? rotYZ;
  final double? rotXW;
  final double? rotYW;
  final double? rotZW;
  final double? distortion;
  final double? zoom;
  final double? geometryMorph;

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
    this.rotXY,
    this.rotXZ,
    this.rotYZ,
    this.rotXW,
    this.rotYW,
    this.rotZW,
    this.distortion,
    this.zoom,
    this.geometryMorph,
  });

  @override
  State<Vib3Adapter> createState() => _Vib3AdapterState();
}

class _Vib3AdapterState extends State<Vib3Adapter> with SingleTickerProviderStateMixin {
  Vib3Engine? _engine;
  bool _useNative = false;
  ui.FragmentProgram? _program;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Slower cycle for shader time
    );
    if (widget.animate) {
      _controller.repeat();
    }

    // Attempt to load shader first as it provides the most reliable "Bombastic" visuals
    // given the current state of the C++ engine integration.
    _loadShader();

    // Also try to init native engine, but we might prioritize shader
    // _initEngine();
  }

  Future<void> _loadShader() async {
    try {
      _program = await ui.FragmentProgram.fromAsset('shaders/vib3_visuals.frag');
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Shader Load Failed: $e");
      // Fallback to native or basic painter
      _initEngine();
    }
  }

  Future<void> _initEngine() async {
    try {
      _engine = Vib3Engine();
      await _engine!.initialize(Vib3Config(
        system: widget.config.system,
        geometry: widget.config.geometry,
        gridDensity: widget.config.gridDensity,
        audioReactive: widget.config.audioReactive,
      ));
      await _engine!.setVisualParams(
        intensity: widget.intensity,
        saturation: widget.saturation,
        chaos: widget.chaos,
        speed: widget.speed,
        hue: widget.hue,
      );
      await _engine!.startRendering();
      if (mounted) setState(() => _useNative = true);
    } catch (e) {
      debugPrint("Vib3 Engine Init Failed: $e");
      // Stay on fallback
    }
  }

  @override
  void didUpdateWidget(Vib3Adapter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_useNative && _engine != null) {
       // Update native params...
       // (Keeping this logic in case we switch back to native)
       if (widget.config.system != oldWidget.config.system) {
        _engine!.setSystem(widget.config.system);
      }
      if (widget.chaos != oldWidget.chaos) {
         _engine!.setVisualParams(chaos: widget.chaos, speed: widget.speed, hue: widget.hue);
      }
    }
  }

  @override
  void dispose() {
    _engine?.stopRendering();
    _engine?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Prefer Shader (High Quality)
    if (_program != null) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Map system/geometry to float for shader
          // Holo = 0, Quantum = 1
          double geo = widget.geometryMorph ?? (widget.config.system == 'holographic' ? 0.0 : 1.0);
          double time = _controller.value * 20.0;

          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: ShaderPainter(
              shader: _program!.fragmentShader(),
              time: time,
              chaos: widget.chaos,
              geometry: geo,
              hue: widget.hue,
              saturation: widget.saturation,
              intensity: widget.intensity,
              // Map extra params dynamically based on input props or override
              rotXY: widget.rotXY ?? (time * widget.speed * 0.5),
              rotXZ: widget.rotXZ ?? (time * widget.speed * 0.3),
              rotYZ: widget.rotYZ ?? (time * widget.speed * 0.2),
              rotXW: widget.rotXW ?? (widget.chaos > 0.1 ? time * widget.chaos : 0.0),
              rotYW: widget.rotYW ?? (widget.chaos > 0.1 ? time * widget.chaos * 0.7 : 0.0),
              rotZW: widget.rotZW ?? (widget.chaos > 0.1 ? time * widget.chaos * 1.3 : 0.0),
              distortion: widget.distortion ?? (widget.chaos * 0.5),
              zoom: widget.zoom ?? (widget.chaos * 0.2),
            ),
          );
        },
      );
    }

    // 2. Native Engine (If shader failed)
    if (_useNative && _engine != null && _engine!.isInitialized) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Vib3View(engine: _engine!),
      );
    }

    // 3. Ultimate Fallback (Basic Painter)
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
}
