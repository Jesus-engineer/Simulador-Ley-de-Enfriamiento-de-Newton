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
import 'widgets/datacenter_view.dart';
// import 'widgets/server_rack_widget.dart';

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

  /// Applies new values from input fields with validation
  void apply() {
    String norm(String s) => s.replaceAll(',', '.').trim();
    double? p(String s) => double.tryParse(norm(s));

    final vT0 = p(t0C.text);
    final vTa = p(taC.text);
    final vP = p(pC.text);
    final vC = p(cC.text);
    final vHA = p(haC.text);
    final vDur = p(dC.text);

    if (vT0 == null || vTa == null || vP == null || vC == null || vHA == null || vDur == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos con números válidos.')),
      );
      return;
    }
    if (vC <= 0 || vHA <= 0 || vDur <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('C, hA y la duración deben ser mayores que 0.')),
      );
      return;
    }

    setState(() {
      t0 = vT0;
      ta = vTa;
      P = vP;
      C = vC;
      hA = vHA;
      duration = vDur.clamp(1, 1e6);
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
          // Aumenta la altura en vertical para una gráfica más llamativa
          final chartHeight = isWide ? 220.0 : 240.0;

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
    // Siempre mostramos los racks debajo de la gráfica (dentro de _buildMainContent)
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [content],
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
          // Servidores inmediatamente debajo de la gráfica
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, cts) {
              return SizedBox(
                width: cts.maxWidth,
                height: 340,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: cts.maxWidth),
                    child: SizedBox(
                      width: cts.maxWidth, // un solo rack: ajusta al ancho disponible
                      height: 340,
                      child: DataCenterView(
                        ambient: ta,
                        temperature: currentT,
                        steady: steady,
                        powerWatts: P,
                        rackCount: 1,
                      ),
                    ),
                  ),
                ),
              );
            },
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
    return SectionCard(
      title: 'Parámetros del servidor',
      icon: Icons.dns,
      actions: [
        IconButton(
          tooltip: 'Definiciones',
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showServerInfo(context),
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
          LayoutBuilder(
            builder: (context, cts) {
              // Cálculo responsivo del ancho para 2 columnas en móvil, 3 en pantallas muy anchas
              final maxW = cts.maxWidth;
              int columns = 2;
              if (maxW >= 920) columns = 3;
              final spacing = 12.0;
              final itemW = (maxW - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: 12,
                children: [
                  _numField('T₀ (°C)', t0C, width: itemW),
                  _numField('Tₐ (°C)', taC, width: itemW),
                  _numField('P (W)', pC, width: itemW),
                  _numField('C (J/°C)', cC, width: itemW),
                  _numField('hA (W/°C)', haC, width: itemW),
                  _numField('Duración (min)', dC, width: itemW),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              Chip(label: Text('T∞ ≈ ${steady.toStringAsFixed(2)} °C')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart({
    required double chartHeight,
    required double minY,
    required double maxY,
    required double steady,
  }) {
    final data = _createChartData(
      minY: minY,
      maxY: maxY,
      steady: steady,
    );

    return SizedBox(
      height: chartHeight + 20,
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
          // Botón para ver la gráfica en grande
          Positioned(
            right: 8,
            top: 8,
            child: Tooltip(
              message: 'Ver en grande',
              child: IconButton(
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.7)),
                onPressed: () => _openFullChart(steady: steady, minY: minY, maxY: maxY),
                icon: const Icon(Icons.fullscreen, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _createChartData({
    required double minY,
    required double maxY,
    required double steady,
  }) {
    return LineChartData(
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
            setState(() => tMarker = x.clamp(0, duration));
          }
        },
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
                        Colors.blue.withValues(alpha: 0.25),
                        Colors.blue.withValues(alpha: 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      extraLinesData: _buildExtraLines(steady),
    );
  }

  void _openFullChart({
    required double steady,
    required double minY,
    required double maxY,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;
        final h = size.height * 0.9;
        final data = _createChartData(minY: minY, maxY: maxY, steady: steady);
        return SafeArea(
          top: false,
          child: SizedBox(
            height: h,
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
                        child: LineChart(data),
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
        Text('Definiciones', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('• T(t): temperatura del servidor [°C]'),
        const Text('• T₀: temperatura inicial [°C]'),
        const Text('• Tₐ: ambiente [°C]'),
        const Text('• P: potencia disipada [W]'),
        const Text('• C: capacidad térmica [J/°C]'),
        const Text('• hA: coef. global de convección [W/°C]'),
        const Text('• k = hA/C [1/min], q = P/C [°C/min]'),
        const Text('• T∞ = Tₐ + P/hA [°C] (equilibrio)'),
        const SizedBox(height: 8),
        Text('Notas', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('• Tₐ y P constantes durante el intervalo.'),
        const Text('• Propiedades térmicas (C, hA) constantes.'),
        const Text('• No se incluye radiación de forma explícita.'),
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

  void _showServerInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Definiciones – Modelo del Servidor'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Variables'),
              SizedBox(height: 6),
              Text('• T(t): temperatura [°C]'),
              Text('• T₀: temperatura inicial [°C]'),
              Text('• Tₐ: ambiente [°C]'),
              Text('• P: potencia [W]'),
              Text('• C: capacidad térmica [J/°C]'),
              Text('• hA: coef. global [W/°C]'),
              SizedBox(height: 12),
              Text('Parámetros derivados'),
              SizedBox(height: 6),
              Text('• k = hA / C [1/min],  q = P / C [°C/min]'),
              Text('• T∞ = Tₐ + P / hA'),
              SizedBox(height: 12),
              Text('Ecuaciones'),
              SizedBox(height: 6),
              Text('C dT/dt = −hA (T − Tₐ) + P'),
              Text('T(t) = Tₐ + (T₀ − Tₐ − q/k) e^{−k t} + q/k'),
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

  Widget _numField(String label, TextEditingController c, {double width = 180}) {
    return SizedBox(
      width: width,
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
