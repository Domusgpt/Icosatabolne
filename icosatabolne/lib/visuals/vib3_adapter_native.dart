import 'package:flutter/material.dart';
import 'package:icosatabolne/visuals/game_config.dart';
import 'package:icosatabolne/visuals/fallback_painter.dart';
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
  });

  @override
  State<Vib3Adapter> createState() => _Vib3AdapterState();
}

class _Vib3AdapterState extends State<Vib3Adapter> with SingleTickerProviderStateMixin {
  Vib3Engine? _engine;
  bool _useFallback = false;
  late AnimationController _controller;

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
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Vib3 Engine Init Failed: $e");
      if (mounted) setState(() => _useFallback = true);
    }
  }

  @override
  void didUpdateWidget(Vib3Adapter oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    _engine?.stopRendering();
    _engine?.dispose();
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
        color: Colors.transparent,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Vib3View(engine: _engine!),
    );
  }
}
