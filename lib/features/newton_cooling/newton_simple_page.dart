import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../shared/constants.dart';
import '../../shared/utils.dart';
import '../../shared/widgets/formula_widgets.dart';
import '../../shared/widgets/chart_titles.dart';
import '../../shared/widgets/section_card.dart';

class NewtonSimplePage extends StatefulWidget {
  const NewtonSimplePage({super.key});

  @override
  State<NewtonSimplePage> createState() => _NewtonSimplePageState();
}

/// State management for Newton's Cooling Law simulation
class _NewtonSimplePageState extends State<NewtonSimplePage> {
  // Initial temperatures and constants
  double t0 = TemperatureConstants.presets['drink']!['t0']!;
  double ta = TemperatureConstants.defaultAmbientTemp;
  double k = TemperatureConstants.presets['drink']!['k']!;
  double duration = TemperatureConstants.presets['drink']!['duration']!;

  // Simulation state
  double tMarker = 0;
  bool _running = false;
  double _speed = TemperatureConstants.defaultSimulationSpeed;
  Timer? _timer;
  // Para sincronizar la gráfica en pantalla completa con el movimiento
  final ValueNotifier<double> _markerNotifier = ValueNotifier<double>(0);

  // Controllers for input fields
  final t0C = TextEditingController(
    text: TemperatureConstants.presets['drink']!['t0']!.toString(),
  );
  final taC = TextEditingController(
    text: TemperatureConstants.defaultAmbientTemp.toString(),
  );
  final kC = TextEditingController(
    text: TemperatureConstants.presets['drink']!['k']!.toString(),
  );
  final dC = TextEditingController(
    text: TemperatureConstants.presets['drink']!['duration']!.toString(),
  );

  /// Calculates temperature at time t using Newton's Cooling Law
  double temp(double t) => ta + (t0 - ta) * math.exp(-k * t);

  /// Generates data points for the temperature curve
  List<FlSpot> series(int n) => List.generate(n + 1, (i) {
    final x = duration * i / n;
    return FlSpot(x, temp(x));
  });

  /// Applies new values from input fields with validation
  void apply() {
    String norm(String s) => s.replaceAll(',', '.').trim();
    double? p(String s) => double.tryParse(norm(s));

    final vT0 = p(t0C.text);
    final vTa = p(taC.text);
    final vK = p(kC.text);
    final vDur = p(dC.text);

    if (vT0 == null || vTa == null || vK == null || vDur == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos con números válidos.')),
      );
      return;
    }
    if (vK <= 0 || vDur <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('k y la duración deben ser mayores que 0.')),
      );
      return;
    }

    setState(() {
      t0 = vT0;
      ta = vTa;
      k = vK;
      duration = vDur.clamp(1, 1e6);
      if (tMarker > duration) tMarker = duration;
    });
  }

  void _tick() {
    setState(() {
      tMarker = (tMarker + _speed * TemperatureConstants.simulationTickInterval);
      if (tMarker >= duration) {
        tMarker = duration;
        _stop();
      }
      _markerNotifier.value = tMarker;
    });
  }

  void _start() {
    if (_running) return;
    _running = true;
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(milliseconds: TemperatureConstants.simulationUpdateRate),
      (_) => _tick(),
    );
    setState(() {});
  }

  void _stop() {
    _running = false;
    _timer?.cancel();
    setState(() {});
  }

  void _reset() {
    _stop();
    setState(() {
      tMarker = 0;
      _markerNotifier.value = tMarker;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentT = temp(tMarker);
    final minY =
        [temp(0), temp(duration), ta].reduce(math.min) -
        ChartConstants.chartPadding;
    final maxY =
        [temp(0), temp(duration), ta].reduce(math.max) +
        ChartConstants.chartPadding;
    // métricas internas opcionales removidas del UI

    return Padding(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputFields(),
            const SizedBox(height: 12),
            _buildChart(currentT, minY, maxY),
            const SizedBox(height: UIConstants.defaultSpacing),
            _buildControls(currentT),
            const SizedBox(height: UIConstants.defaultSpacing),
            _buildTimeSlider(),
            _buildFormulas(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    return SectionCard(
      title: 'Parámetros y presets',
      icon: Icons.thermostat,
      actions: [
        IconButton(
          tooltip: 'Definiciones',
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showNewtonInfo(context),
        ),
        FilledButton.icon(
          onPressed: apply,
          icon: const Icon(Icons.check),
          label: const Text('Aplicar'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _numField('T₀ (°C)', t0C),
              _numField('Tₐ (°C)', taC),
              _numField('k (1/min)', kC),
              _numField('Duración (min)', dC),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: UIConstants.defaultSpacing,
            runSpacing: UIConstants.defaultSpacing,
            children: [
              _buildPresetButton(
                'Bebida',
                Icons.local_cafe,
                TemperatureConstants.presets['drink']!,
              ),
              _buildPresetButton(
                'CPU',
                Icons.memory,
                TemperatureConstants.presets['cpu']!,
              ),
              ActionChip(
                avatar: const Icon(Icons.ac_unit, size: 16),
                label: const Text('Exterior frío'),
                onPressed: () {
                  setState(() {
                    ta = 5; // ambiente frío fijo
                    taC.text = ta.toString();
                    tMarker = 0;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  

  Widget _buildPresetButton(
    String label,
    IconData icon,
    Map<String, double> preset,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: () {
        setState(() {
          t0 = preset['t0']!;
          ta = preset['ta']!;
          k = preset['k']!;
          duration = preset['duration']!;
          t0C.text = t0.toString();
          taC.text = ta.toString();
          kC.text = k.toString();
          dC.text = duration.toString();
          tMarker = 0;
        });
      },
    );
  }

  Widget _buildChart(
    double currentT,
    double minY,
    double maxY,
  ) {
    final data = LineChartData(
      minX: -(math.max(0.5, duration * ChartConstants.chartMarginPercent)),
      maxX: duration + math.max(0.5, duration * ChartConstants.chartMarginPercent),
      minY: minY,
      maxY: maxY,
      gridData: const FlGridData(show: true),
      titlesData: ChartTitlesConfig.create(
        duration,
        minY,
        maxY,
        xMin: 0,
        xMax: duration,
        xAxisLabel: 'Tiempo [min]',
        yAxisLabel: 'Temperatura [°C]',
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border.symmetric(
          horizontal: BorderSide(color: Color(0x22000000)),
          vertical: BorderSide(color: Color(0x22000000)),
        ),
      ),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => spots
              .map(
                (s) => LineTooltipItem(
                  't = ${s.x.toStringAsFixed(2)} min\nT = ${s.y.toStringAsFixed(2)} °C',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: UIConstants.defaultFontSize,
                  ),
                ),
              )
              .toList(),
        ),
        touchCallback: (event, response) {
          if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
            final x = response.lineBarSpots!.first.x;
            setState(() {
              tMarker = x.clamp(0, duration);
              _markerNotifier.value = tMarker;
            });
          }
        },
      ),
      lineBarsData: [
        LineChartBarData(
          spots: series(TemperatureConstants.chartDataPoints),
          isCurved: true,
          color: Colors.indigo,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                        Colors.indigo.withValues(alpha: 0.25),
                        Colors.indigo.withValues(alpha: 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      extraLinesData: _buildExtraLines(),
    );

    return SizedBox(
      height: 240,
      child: Stack(
        children: [
          Card(
            elevation: UIConstants.defaultElevation,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UIConstants.defaultBorderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: LineChart(data),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Tooltip(
              message: 'Ver en grande',
              child: IconButton(
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.7)),
                onPressed: () => _openFullChart(minY: minY, maxY: maxY),
                icon: const Icon(Icons.fullscreen, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ExtraLinesData _buildExtraLines() {
    return ExtraLinesData(
      horizontalLines: [
        HorizontalLine(
          y: ta,
          color: Colors.teal,
          dashArray: const [6, 4],
          label: HorizontalLineLabel(
            show: true,
            labelResolver: (_) => 'Tₐ ${ta.toStringAsFixed(1)}°C',
          ),
        ),
      ],
      verticalLines: [
        VerticalLine(
          x: tMarker,
          color: Colors.orange,
          dashArray: const [6, 4],
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.topLeft,
            labelResolver: (_) => 't = ${tMarker.toStringAsFixed(1)} min',
          ),
        ),
      ],
    );
  }

  Widget _buildControls(double currentT) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: _running ? _stop : _start,
          icon: Icon(_running ? Icons.pause : Icons.play_arrow),
          label: Text(_running ? 'Pausar' : 'Iniciar'),
        ),
        OutlinedButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.replay),
          label: const Text('Reiniciar'),
        ),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Velocidad'),
            const SizedBox(width: UIConstants.defaultSpacing),
            DropdownButton<double>(
              value: _speed,
              items: AnimationConstants.speeds
                  .map(
                    (v) => DropdownMenuItem<double>(
                      value: v,
                      child: Text('${v}x'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _speed = v ?? 1.0),
            ),
          ],
        ),
        Text('T(t) = ${currentT.toStringAsFixed(2)} °C'),
      ],
    );
  }

  Widget _buildTimeSlider() {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: tMarker.clamp(0, duration),
            min: 0,
            max: duration,
            onChanged: (v) => setState(() {
              tMarker = v;
              _markerNotifier.value = tMarker;
            }),
          ),
        ),
      ],
    );
  }

  void _openFullChart({required double minY, required double maxY}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Evolución de temperatura',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 16, 16),
                    child: Card(
                      elevation: UIConstants.defaultElevation,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(UIConstants.defaultBorderRadius),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                        child: ValueListenableBuilder<double>(
                          valueListenable: _markerNotifier,
                          builder: (_, __, ___) {
                            // Reutilizamos la misma configuración, que depende de tMarker actual
                            final data = LineChartData(
                              minX: -(math.max(0.5, duration * ChartConstants.chartMarginPercent)),
                              maxX: duration + math.max(0.5, duration * ChartConstants.chartMarginPercent),
                              minY: minY,
                              maxY: maxY,
                              gridData: const FlGridData(show: true),
                              titlesData: ChartTitlesConfig.create(
                                duration,
                                minY,
                                maxY,
                                xMin: 0,
                                xMax: duration,
                                xAxisLabel: 'Tiempo [min]',
                                yAxisLabel: 'Temperatura [°C]',
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: const Border.symmetric(
                                  horizontal: BorderSide(color: Color(0x22000000)),
                                  vertical: BorderSide(color: Color(0x22000000)),
                                ),
                              ),
                              lineTouchData: LineTouchData(
                                handleBuiltInTouches: true,
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipItems: (spots) => spots
                                      .map(
                                        (s) => LineTooltipItem(
                                          't = ${s.x.toStringAsFixed(2)} min\nT = ${s.y.toStringAsFixed(2)} °C',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontSize: UIConstants.defaultFontSize,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                                touchCallback: (event, response) {
                                  if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
                                    final x = response.lineBarSpots!.first.x;
                                    setState(() {
                                      tMarker = x.clamp(0, duration);
                                      _markerNotifier.value = tMarker;
                                    });
                                  }
                                },
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: series(TemperatureConstants.chartDataPoints),
                                  isCurved: true,
                                  color: Colors.indigo,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.indigo.withValues(alpha: 0.25),
                                        Colors.indigo.withValues(alpha: 0.05),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                              extraLinesData: _buildExtraLines(),
                            );
                            return LineChart(data);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormulas() {
    return FormulaCard(
      title: 'Fórmulas y ecuaciones',
      lines: [
        Math.tex(
          r"\frac{dT}{dt} = -k\,(T- T_a)",
          textStyle: const TextStyle(fontSize: 16),
        ),
        Math.tex(
          r"T(t) = T_a + (T_0 - T_a)\,e^{-kt}",
          textStyle: const TextStyle(fontSize: 16),
        ),
        const Divider(),
        Math.tex(
          "T(t) = ${ta.toStringAsFixed(2)} + (${t0.toStringAsFixed(2)} - ${ta.toStringAsFixed(2)}) e^{-${k.toStringAsFixed(3)} t}",
          textStyle: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: UIConstants.defaultSpacing),
        Text('Definiciones', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('• T(t): temperatura del objeto [°C]'),
        const Text('• T₀: temperatura inicial del objeto [°C]'),
        const Text('• Tₐ: temperatura ambiente constante [°C]'),
        const Text('• k: coeficiente de enfriamiento [1/min], k > 0'),
        const SizedBox(height: 8),
        Text('Notas', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('• Medio con Tₐ constante y sin fuentes internas de calor.'),
        const Text('• k se asume constante (flujo de aire/entorno estable).'),
        const Text('• Convección dominante y sin cambio de fase.'),
        const Divider(),
        Wrap(
          spacing: UIConstants.defaultSpacing,
          runSpacing: UIConstants.defaultSpacing,
          children: [
            InlineNumField(
              label: 'T₀ (°C)',
              controller: t0C,
              onSubmitted: apply,
            ),
            InlineNumField(
              label: 'Tₐ (°C)',
              controller: taC,
              onSubmitted: apply,
            ),
            InlineNumField(
              label: 'k (1/min)',
              controller: kC,
              onSubmitted: apply,
            ),
          ],
        ),
      ],
    );
  }

  void _showNewtonInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Definiciones – Ley de Enfriamiento'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Variables'),
              SizedBox(height: 6),
              Text('• T(t): temperatura del objeto [°C]'),
              Text('• T₀: temperatura inicial [°C]'),
              Text('• Tₐ: temperatura ambiente [°C]'),
              Text('• k: coeficiente de enfriamiento [1/min], k > 0'),
              SizedBox(height: 12),
              Text('Ecuaciones'),
              SizedBox(height: 6),
              Text('dT/dt = −k (T − Tₐ)'),
              Text('T(t) = Tₐ + (T₀ − Tₐ) e^{−k t}'),
              SizedBox(height: 12),
              Text('Supuestos'),
              SizedBox(height: 6),
              Text('• Tₐ constante; sin fuentes internas de calor.'),
              Text('• k constante; entorno estable (flujo de aire).'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          )
        ],
      ),
    );
  }

  Widget _numField(String label, TextEditingController c) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          TextField(
            controller: c,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.all(12),
            ),
            onSubmitted: (_) => apply(),
          ),
        ],
      ),
    );
  }
}
