import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../shared/constants.dart';
import '../../shared/utils.dart';
import '../../shared/widgets/formula_widgets.dart';
import '../../shared/widgets/chart_titles.dart';

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
  bool _loop = false;

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

  /// Applies new values from input fields
  void apply() {
    setState(() {
      t0 = MathUtils.parseNumericInput(t0C.text, t0);
      ta = MathUtils.parseNumericInput(taC.text, ta);
      k = MathUtils.parseNumericInput(kC.text, k).abs();
      duration = MathUtils.parseNumericInput(dC.text, duration).clamp(1, 1e6);
      if (tMarker > duration) tMarker = duration;
    });
  }

  void _tick() {
    setState(() {
      tMarker =
          (tMarker + _speed * TemperatureConstants.simulationTickInterval);
      if (tMarker >= duration) {
        if (_loop) {
          tMarker = 0;
        } else {
          tMarker = duration;
          _stop();
        }
      }
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
    setState(() => tMarker = 0);
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
    final tau = 1.0 / (k == 0 ? 1e-9 : k);
    final tHalf = math.ln2 / (k == 0 ? 1e-9 : k);
    final t95 = math.log(20) / (k == 0 ? 1e-9 : k);

    return Padding(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputFields(),
            const SizedBox(height: UIConstants.defaultSpacing),
            _buildMetrics(tau, tHalf, t95),
            const SizedBox(height: 12),
            _buildChart(currentT, minY, maxY, tau, tHalf, t95),
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
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _numField('T₀ (°C)', t0C),
        _numField('Tₐ (°C)', taC),
        _numField('k (1/min)', kC),
        _numField('Duración (min)', dC),
        FilledButton.icon(
          onPressed: apply,
          icon: const Icon(Icons.check),
          label: const Text('Aplicar'),
        ),
      ],
    );
  }

  Widget _buildMetrics(double tau, double tHalf, double t95) {
    return Wrap(
      spacing: UIConstants.defaultSpacing,
      runSpacing: UIConstants.defaultSpacing,
      children: [
        Chip(label: Text('τ ≈ ${tau.toStringAsFixed(2)} min')),
        Chip(label: Text('t½ ≈ ${tHalf.toStringAsFixed(2)} min')),
        Chip(label: Text('t95% ≈ ${t95.toStringAsFixed(2)} min')),
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
              ta = TemperatureConstants.presets['drink']!['ta']!;
              taC.text = ta.toString();
              tMarker = 0;
            });
          },
        ),
      ],
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
    double tau,
    double tHalf,
    double t95,
  ) {
    return SizedBox(
      height: ChartConstants.defaultHeight,
      child: Card(
        elevation: UIConstants.defaultElevation,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultBorderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          child: LineChart(
            LineChartData(
              minX: -(math.max(
                0.5,
                duration * ChartConstants.chartMarginPercent,
              )),
              maxX:
                  duration +
                  math.max(0.5, duration * ChartConstants.chartMarginPercent),
              minY: minY,
              maxY: maxY,
              gridData: const FlGridData(show: true),
              titlesData: ChartTitlesConfig.create(
                duration,
                minY,
                maxY,
                xMin: 0,
                xMax: duration,
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
                        Colors.indigo.withOpacity(0.25),
                        Colors.indigo.withOpacity(0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              extraLinesData: _buildExtraLines(tau, tHalf, t95),
            ),
          ),
        ),
      ),
    );
  }

  ExtraLinesData _buildExtraLines(double tau, double tHalf, double t95) {
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
        if (tau <= duration)
          VerticalLine(
            x: tau,
            color: Colors.deepPurpleAccent,
            dashArray: const [4, 4],
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.topCenter,
              labelResolver: (_) => 'τ',
            ),
          ),
        if (tHalf <= duration)
          VerticalLine(
            x: tHalf,
            color: Colors.pinkAccent,
            dashArray: const [4, 4],
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.topCenter,
              labelResolver: (_) => 't½',
            ),
          ),
        if (t95 <= duration)
          VerticalLine(
            x: t95,
            color: Colors.greenAccent,
            dashArray: const [4, 4],
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.topCenter,
              labelResolver: (_) => '95%',
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
            const Text('Loop'),
            Switch(value: _loop, onChanged: (v) => setState(() => _loop = v)),
          ],
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
            onChanged: (v) => setState(() => tMarker = v),
          ),
        ),
      ],
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
        Math.tex(
          r"\tau = \frac{1}{k},\quad t_{1/2}=\frac{\ln 2}{k},\quad t_{95\%}=\frac{\ln 20}{k}",
          textStyle: const TextStyle(fontSize: 16),
        ),
        const Divider(),
        Math.tex(
          "T(t) = ${ta.toStringAsFixed(2)} + (${t0.toStringAsFixed(2)} - ${ta.toStringAsFixed(2)}) e^{-${k.toStringAsFixed(3)} t}",
          textStyle: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: UIConstants.defaultSpacing),
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
