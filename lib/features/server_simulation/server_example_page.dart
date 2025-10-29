import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../shared/constants.dart';
import '../../shared/utils.dart';
import '../../shared/widgets/formula_widgets.dart';
import '../../shared/widgets/chart_titles.dart';
import 'widgets/datacenter_view.dart';
import 'widgets/server_rack_widget.dart';

class ServerExamplePage extends StatefulWidget {
  const ServerExamplePage({super.key});

  @override
  State<ServerExamplePage> createState() => _ServerExamplePageState();
}

class _ServerExamplePageState extends State<ServerExamplePage> {
  // Initial values from presets
  double t0 = TemperatureConstants.presets['server']!['t0']!;
  double ta = TemperatureConstants.presets['server']!['ta']!;
  double P = TemperatureConstants.presets['server']!['P']!;
  double C = TemperatureConstants.presets['server']!['C']!;
  double hA = TemperatureConstants.presets['server']!['hA']!;
  double duration = TemperatureConstants.presets['server']!['duration']!;

  // Computed properties
  double get k => (hA / C) * 60; // 1/min
  double get q => (P / C) * 60; // °C/min

  // Simulation state
  double tMarker = 0;
  bool _running = false;
  double _speed = TemperatureConstants.defaultSimulationSpeed;
  Timer? _timer;

  // Controllers for input fields
  final t0C = TextEditingController(
    text: TemperatureConstants.presets['server']!['t0']!.toString(),
  );
  final taC = TextEditingController(
    text: TemperatureConstants.presets['server']!['ta']!.toString(),
  );
  final pC = TextEditingController(
    text: TemperatureConstants.presets['server']!['P']!.toString(),
  );
  final cC = TextEditingController(
    text: TemperatureConstants.presets['server']!['C']!.toString(),
  );
  final haC = TextEditingController(
    text: TemperatureConstants.presets['server']!['hA']!.toString(),
  );
  final dC = TextEditingController(
    text: TemperatureConstants.presets['server']!['duration']!.toString(),
  );

  /// Calculates server temperature at time t
  double temp(double t) =>
      ta +
      (t0 - ta - q / (k == 0 ? 1 : k)) * math.exp(-k * t) +
      (k == 0 ? 0 : q / k);

  /// Generates data points for temperature curve
  List<FlSpot> series(int n) => List.generate(n + 1, (i) {
        final x = duration * i / n;
        return FlSpot(x, temp(x));
      });

  /// Applies new values from input fields
  void apply() {
    setState(() {
      t0 = MathUtils.parseNumericInput(t0C.text, t0);
      ta = MathUtils.parseNumericInput(taC.text, ta);
      P = MathUtils.parseNumericInput(pC.text, P);
      C = MathUtils.parseNumericInput(cC.text, C).abs();
      hA = MathUtils.parseNumericInput(haC.text, hA).abs();
      duration = MathUtils.parseNumericInput(dC.text, duration).clamp(1, 1e6);
      if (tMarker > duration) tMarker = duration;
    });
  }

  void _tick() {
    setState(() {
      tMarker = (tMarker + _speed * TemperatureConstants.simulationTickInterval)
          .clamp(0, duration);
      if (tMarker >= duration) _stop();
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
    t0C.dispose();
    taC.dispose();
    pC.dispose();
    cC.dispose();
    haC.dispose();
    dC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steady = ta + (hA > 0 ? P / hA : 0);
    final currentT = temp(tMarker);
    final minY =
        [temp(0), temp(duration), ta, steady].reduce((a, b) => math.min(a, b)) -
            ChartConstants.chartPadding;
    final maxY =
        [temp(0), temp(duration), ta, steady].reduce((a, b) => math.max(a, b)) +
            ChartConstants.chartPadding;

    return Padding(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final chartHeight = isWide ? 190.0 : 160.0;

          return _buildLayout(
            isWide: isWide,
            chartHeight: chartHeight,
            steady: steady,
            currentT: currentT,
            minY: minY,
            maxY: maxY,
          );
        },
      ),
    );
  }

  Widget _buildLayout({
    required bool isWide,
    required double chartHeight,
    required double steady,
    required double currentT,
    required double minY,
    required double maxY,
  }) {
    final content = _buildMainContent(
      chartHeight: chartHeight,
      steady: steady,
      currentT: currentT,
      minY: minY,
      maxY: maxY,
    );

    final dataCenterView = DataCenterView(
      ambient: ta,
      temperature: currentT,
      steady: steady,
      powerWatts: P,
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: content),
          const SizedBox(width: 16),
          Expanded(flex: 1, child: dataCenterView),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          content,
          const SizedBox(height: 12),
          SizedBox(height: 320, child: dataCenterView),
        ],
      ),
    );
  }

  Widget _buildMainContent({
    required double chartHeight,
    required double steady,
    required double currentT,
    required double minY,
    required double maxY,
  }) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputFields(steady),
          const SizedBox(height: 12),
          _buildChart(
            chartHeight: chartHeight,
            minY: minY,
            maxY: maxY,
            steady: steady,
          ),
          const SizedBox(height: UIConstants.defaultSpacing),
          _buildControls(currentT),
          const SizedBox(height: UIConstants.defaultSpacing),
          _buildTimeSlider(),
          _buildFormulas(),
        ],
      ),
    );
  }

  Widget _buildInputFields(double steady) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _numField('T₀ (°C)', t0C),
        _numField('Tₐ (°C)', taC),
        _numField('P (W)', pC),
        _numField('C (J/°C)', cC),
        _numField('hA (W/°C)', haC),
        _numField('Duración (min)', dC),
        FilledButton.icon(
          onPressed: apply,
          icon: const Icon(Icons.check),
          label: const Text('Aplicar'),
        ),
        Chip(label: Text('T∞ ≈ ${steady.toStringAsFixed(2)} °C')),
      ],
    );
  }

  Widget _buildChart({
    required double chartHeight,
    required double minY,
    required double maxY,
    required double steady,
  }) {
    return SizedBox(
      height: chartHeight + 20,
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
              maxX: duration +
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
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.25),
                        Colors.blue.withOpacity(0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              extraLinesData: _buildExtraLines(steady),
            ),
          ),
        ),
      ),
    );
  }

  ExtraLinesData _buildExtraLines(double steady) {
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
        HorizontalLine(
          y: steady,
          color: Colors.orangeAccent,
          dashArray: const [6, 4],
          label: HorizontalLineLabel(
            show: true,
            labelResolver: (_) => 'T∞ ${steady.toStringAsFixed(1)}°C',
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
          r"C\,\frac{dT}{dt} = -hA\,(T-T_a) + P",
          textStyle: const TextStyle(fontSize: 16),
        ),
        Math.tex(
          r"\text{Definimos } k=\frac{hA}{C},\; q=\frac{P}{C}\;\Rightarrow\; \frac{dT}{dt} = -k(T-T_a)+q",
          textStyle: const TextStyle(fontSize: 16),
        ),
        Math.tex(
          r"T(t) = T_a + \Big(T_0 - T_a - \frac{q}{k}\Big)e^{-kt} + \frac{q}{k}",
          textStyle: const TextStyle(fontSize: 16),
        ),
        Math.tex(
          r"T_{\infty} = T_a + \frac{P}{hA}",
          textStyle: const TextStyle(fontSize: 16),
        ),
        const Divider(),
        Math.tex(
          "T(t) = ${ta.toStringAsFixed(2)} + (${t0.toStringAsFixed(2)} - ${ta.toStringAsFixed(2)} - ${(q / (k == 0 ? 1 : k)).toStringAsFixed(2)}) e^{-${k.toStringAsFixed(3)} t} + ${(q / (k == 0 ? 1 : k)).toStringAsFixed(2)}",
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
              label: 'Potencia (W)',
              controller: pC,
              onSubmitted: apply,
            ),
            InlineNumField(
              label: 'Capacidad térmica (J/°C)',
              controller: cC,
              onSubmitted: apply,
            ),
            InlineNumField(
              label: 'Coef. hA',
              controller: haC,
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
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onSubmitted: (_) => apply(),
      ),
    );
  }
}
