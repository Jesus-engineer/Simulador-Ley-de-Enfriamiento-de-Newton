import 'dart:math' as math;
import 'package:flutter/material.dart';

extension ColorExt on Color {
  Color withValues({int? red, int? green, int? blue, double? alpha}) {
    return Color.fromARGB(
      (alpha != null ? (alpha * 255).round() : this.alpha),
      red ?? this.red,
      green ?? this.green,
      blue ?? this.blue,
    );
  }
}

// Animación de rack de servidor con ventiladores, LEDs y flujo de aire
class ServerRackWidget extends StatefulWidget {
  const ServerRackWidget({
    super.key,
    required this.ambient,
    required this.temperature,
    this.steady,
    this.powerWatts,
  });
  final double ambient; // T_a
  final double temperature; // T(t)
  final double? steady; // T_infty opcional
  final double? powerWatts; // P opcional

  @override
  State<ServerRackWidget> createState() => _ServerRackWidgetState();
}

class _ServerRackWidgetState extends State<ServerRackWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Color map: colder -> blue, ambient -> teal, hot -> orange/red
    Color tempColor(double t) {
      final a = widget.ambient;
      final s = widget.steady ?? a + 10;
      final clamped = t.clamp(a - 5, s + 15);
      final ratio = (clamped - (a - 5)) / ((s + 15) - (a - 5));
      return Color.lerp(Colors.blue.shade400, Colors.red.shade400, ratio) ??
          Colors.orange;
    }

    final rack = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101217),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 8))
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Header with indicators
          Row(children: [
            Icon(Icons.dns, color: tempColor(widget.temperature)),
            const SizedBox(width: 8),
            Expanded(
                child: Container(
              height: 6,
              decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(6)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.7,
                  child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                          color: tempColor(widget.temperature),
                          borderRadius: BorderRadius.circular(6))),
                ),
              ),
            )),
            const SizedBox(width: 8),
            _BlinkLed(color: Colors.greenAccent, controller: _c, phase: 0.0),
            const SizedBox(width: 4),
            _BlinkLed(color: Colors.amberAccent, controller: _c, phase: 0.33),
            const SizedBox(width: 4),
            _BlinkLed(color: Colors.redAccent, controller: _c, phase: 0.66),
          ]),
          const SizedBox(height: 6),
          // 6 units with fans and grills
          Expanded(
            child: Column(
                children: List.generate(
                    6,
                    (i) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: _ServerUnit(
                                controller: _c,
                                color: tempColor(widget.temperature - i)),
                          ),
                        ))),
          ),
          const SizedBox(height: 4),
          // Footer labels (escala automática para caber en anchuras pequeñas)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tₐ ${widget.ambient.toStringAsFixed(1)}°C',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(width: 8),
                Text('T ${widget.temperature.toStringAsFixed(1)}°C',
                    style: TextStyle(
                        color: tempColor(widget.temperature),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                if (widget.steady != null) ...[
                  const SizedBox(width: 8),
                  Text('T∞ ${widget.steady!.toStringAsFixed(1)}°C',
                      style: const TextStyle(
                          color: Colors.orangeAccent, fontSize: 12)),
                ]
              ],
            ),
          )
        ],
      ),
    );

    // Air flow arrows animated
    final airflow = AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        final inY = 0.2 + 0.6 * t; // move cold air arrows upward
        final outY = 0.8 - 0.6 * t; // move hot air arrows downward
        return Stack(children: [
          Align(
            alignment: Alignment(-1.0, inY * 2 - 1),
            child: Icon(Icons.arrow_forward_ios,
                size: 18, color: Colors.lightBlueAccent.withValues(alpha: 0.9)),
          ),
          Align(
            alignment: Alignment(1.05, outY * 2 - 1),
            child: Transform.rotate(
              angle: math.pi,
              child: Icon(Icons.arrow_forward_ios,
                  size: 18, color: Colors.orangeAccent.withValues(alpha: 0.9)),
            ),
          ),
        ]);
      },
    );

    return Stack(children: [
      Positioned.fill(child: rack),
      Positioned.fill(child: airflow),
    ]);
  }
}

class _ServerUnit extends StatelessWidget {
  const _ServerUnit({required this.controller, required this.color});
  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171A21),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black87, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(children: [
        // Fans
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
                3,
                (i) => _Fan(
                    controller: controller,
                    color: color,
                    speed: 1.0 + i * 0.2)),
          ),
        ),
        // LEDs column (compact to avoid tiny-height overflows)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiniLed(
                color: Colors.lightGreenAccent,
                controller: controller,
                phase: 0.1),
            _MiniLed(
                color: Colors.cyanAccent, controller: controller, phase: 0.5),
            _MiniLed(
                color: Colors.deepPurpleAccent,
                controller: controller,
                phase: 0.8),
          ],
        )
      ]),
    );
  }
}

class _Fan extends StatelessWidget {
  const _Fan(
      {required this.controller, required this.color, required this.speed});
  final AnimationController controller;
  final Color color;
  final double speed;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
                colors: [color.withValues(alpha: 0.15), Colors.black],
                stops: const [0.3, 1.0]),
            border: Border.all(color: Colors.grey.shade800, width: 1),
          ),
        ),
        Center(
          child: RotationTransition(
            turns: Tween<double>(begin: 0, end: speed).animate(controller),
            child: Icon(Icons.settings,
                size: 20, color: Colors.white.withValues(alpha: 0.9)),
          ),
        ),
      ]),
    );
  }
}

class _BlinkLed extends StatelessWidget {
  const _BlinkLed(
      {required this.color, required this.controller, required this.phase});
  final Color color;
  final AnimationController controller;
  final double phase;
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: TweenSequence([
        TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.0), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.2), weight: 50),
      ]).animate(CurvedAnimation(
          parent: controller,
          curve: Interval(phase, (phase + 0.9).clamp(0.0, 1.0)))),
      child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)
              ])),
    );
  }
}

class _MiniLed extends StatelessWidget {
  const _MiniLed(
      {required this.color, required this.controller, required this.phase});
  final Color color;
  final AnimationController controller;
  final double phase;
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(CurvedAnimation(
          parent: controller,
          curve: Interval(phase, (phase + 0.5).clamp(0.0, 1.0)))),
      child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 3)
              ])),
    );
  }
}
