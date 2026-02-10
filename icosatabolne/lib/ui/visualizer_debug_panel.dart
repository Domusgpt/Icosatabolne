import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:icosatabolne/visuals/visualizer_controller.dart';

class VisualizerDebugPanel extends StatefulWidget {
  const VisualizerDebugPanel({super.key});

  @override
  State<VisualizerDebugPanel> createState() => _VisualizerDebugPanelState();
}

class _VisualizerDebugPanelState extends State<VisualizerDebugPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VisualizerController>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _expanded ? 400 : 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border(top: BorderSide(color: Colors.cyanAccent.withOpacity(0.5))),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "VIB3 DEBUG // ADVANCED CONTROLS",
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_more : Icons.expand_less, color: Colors.cyanAccent),
                ],
              ),
            ),
          ),
          if (_expanded)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _Slider("Chaos", 'chaos', controller),
                  _Slider("Speed", 'speed', controller, max: 5.0),
                  _Slider("Hue", 'hue', controller, max: 360.0),
                  _Slider("Saturation", 'saturation', controller),
                  _Slider("Intensity", 'intensity', controller, max: 2.0),
                  _Slider("Geo Morph", 'geometryMorph', controller),
                  const Divider(color: Colors.white24),
                  const Text("6D Rotation", style: TextStyle(color: Colors.white54)),
                  _Slider("XY", 'rotXY', controller, max: 6.28),
                  _Slider("XZ", 'rotXZ', controller, max: 6.28),
                  _Slider("YZ", 'rotYZ', controller, max: 6.28),
                  _Slider("XW", 'rotXW', controller, max: 6.28),
                  _Slider("YW", 'rotYW', controller, max: 6.28),
                  _Slider("ZW", 'rotZW', controller, max: 6.28),
                  const Divider(color: Colors.white24),
                  _Slider("Distortion", 'distortion', controller),
                  _Slider("Zoom", 'zoom', controller),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  final String label;
  final String paramKey;
  final VisualizerController controller;
  final double max;

  const _Slider(this.label, this.paramKey, this.controller, {this.max = 1.0});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        Expanded(
          child: Slider(
            value: controller.getParameter(paramKey),
            min: 0.0,
            max: max,
            activeColor: Colors.cyanAccent,
            inactiveColor: Colors.white10,
            onChanged: (v) => controller.setParameter(paramKey, v),
          ),
        ),
        SizedBox(width: 40, child: Text(controller.getParameter(paramKey).toStringAsFixed(2), style: const TextStyle(color: Colors.white30, fontSize: 10))),
      ],
    );
  }
}
