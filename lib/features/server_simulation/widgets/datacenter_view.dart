import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'server_rack_widget.dart';

// Vista de Datacenter con varios racks y pasillos Cold/Hot
class DataCenterView extends StatefulWidget {
  const DataCenterView(
      {super.key,
      required this.ambient,
      required this.temperature,
      this.steady,
      this.powerWatts});
  final double ambient;
  final double temperature;
  final double? steady;
  final double? powerWatts;

  @override
  State<DataCenterView> createState() => _DataCenterViewState();
}

class _DataCenterViewState extends State<DataCenterView>
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
    final t = widget.temperature;
    final s = widget.steady ?? (widget.ambient + 10);
    // Pequeñas variaciones entre racks para dar naturalidad
    final temps = [t - 1.5, t, t + 1.5];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(children: [
          // Fondo con gradiente Cold->Hot (pasillos)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.lightBlueAccent.withValues(alpha: 0.18),
                    Colors.transparent,
                    Colors.orangeAccent.withValues(alpha: 0.18),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Etiquetas de pasillos
          Positioned(
            left: 8,
            top: 8,
            child: Row(children: const [
              Icon(Icons.ac_unit, size: 14, color: Colors.lightBlueAccent),
              SizedBox(width: 4),
              Text('Cold Aisle',
                  style:
                      TextStyle(fontSize: 12, color: Colors.lightBlueAccent)),
            ]),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Row(children: const [
              Icon(Icons.local_fire_department,
                  size: 14, color: Colors.orangeAccent),
              SizedBox(width: 4),
              Text('Hot Aisle',
                  style: TextStyle(fontSize: 12, color: Colors.orangeAccent)),
            ]),
          ),
          // Racks
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(3, (i) {
                  return Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ServerRackWidget(
                        ambient: widget.ambient,
                        temperature: temps[i],
                        steady: s,
                        powerWatts: widget.powerWatts,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          // Flechas de flujo general (entrada fría izquierda, salida caliente derecha)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) {
                  final ph = _c.value;
                  return Stack(children: [
                    Align(
                      alignment: Alignment(-1.0, (0.3 + 0.4 * ph) * 2 - 1),
                      child: Icon(Icons.arrow_forward_ios,
                          size: 18,
                          color: Colors.lightBlueAccent.withValues(alpha: 0.9)),
                    ),
                    Align(
                      alignment: Alignment(1.0, (0.7 - 0.4 * ph) * 2 - 1),
                      child: Transform.rotate(
                        angle: math.pi,
                        child: Icon(Icons.arrow_forward_ios,
                            size: 18,
                            color: Colors.orangeAccent.withValues(alpha: 0.9)),
                      ),
                    ),
                  ]);
                },
              ),
            ),
          ),
        ]);
      },
    );
  }
}