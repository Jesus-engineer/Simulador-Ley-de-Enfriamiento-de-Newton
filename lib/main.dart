import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'app.dart';

void main() => runApp(const MainApp());
double _niceStep(double span) {
  if (span <= 0 || span.isNaN || span.isInfinite) return 1;
  final desired = span / 6;
  final log10 = math.log(desired) / math.ln10;
  final pow10 = math.pow(10, log10.floor()).toDouble();
  final residual = desired / pow10;
  final nice = residual <= 1
      ? 1
      : residual <= 2
      ? 2
      : residual <= 5
      ? 5
      : 10;
  return nice * pow10;
}

FlTitlesData _titles(
  double spanX,
  double minY,
  double maxY, {
  double xMin = 0,
  required double xMax,
}) {
  final ySpan = (maxY - minY).abs();
  final xStep = _niceStep(spanX);
  final yStep = _niceStep(ySpan);
  String _fmt(double v, double step) => v.toStringAsFixed(step >= 1 ? 0 : 1);

  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 60,
        interval: yStep,
        getTitlesWidget: (v, meta) {
          final isNearMin = (v - minY).abs() < yStep * 0.4;
          final isNearMax = (maxY - v).abs() < yStep * 0.4;
          if (isNearMin || isNearMax) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(_fmt(v, yStep), style: const TextStyle(fontSize: 12)),
            ),
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 36,
        interval: xStep,
        getTitlesWidget: (v, meta) {
          if (v < xMin - 1e-6 || v > xMax + 1e-6)
            return const SizedBox.shrink();
          return Text(_fmt(v, xStep), style: const TextStyle(fontSize: 12));
        },
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simulador – Ley de Enfriamiento de Newton',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Simulador de Enfriamiento')),
        body: IndexedStack(
          index: _index,
          children: const [NewtonSimplePage(), ServerExamplePage()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.functions), label: 'Ley'),
            NavigationDestination(icon: Icon(Icons.dns), label: 'Servidor'),
          ],
          onDestinationSelected: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

// Tarjeta reutilizable para mostrar fórmulas con LaTeX
class FormulaCard extends StatelessWidget {
  const FormulaCard({super.key, required this.title, required this.lines});
  final String title;
  final List<Widget> lines;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate, size: 18),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            ...lines.map(
              (w) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: w,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Campo numérico compacto para insertar dentro de las fórmulas
class InlineNumField extends StatelessWidget {
  const InlineNumField({
    super.key,
    required this.label,
    required this.controller,
    required this.onSubmitted,
    this.width = 110,
  });
  final String label;
  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final double width;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => onSubmitted(),
      ),
    );
  }
}

// 1) Apartado Ley de Enfriamiento de Newton (sin servidor gráfico)
class NewtonSimplePage extends StatefulWidget {
  const NewtonSimplePage({super.key});
  @override
  State<NewtonSimplePage> createState() => _NewtonSimplePageState();
}

class _NewtonSimplePageState extends State<NewtonSimplePage> {
  double t0 = 80, ta = 25, k = 0.2, duration = 60;
  double tMarker = 0;
  bool _running = false;
  double _speed = 1.0; // minutos simulados por segundo
  Timer? _timer;
  bool _loop = false;
  final t0C = TextEditingController(text: '80');
  final taC = TextEditingController(text: '25');
  final kC = TextEditingController(text: '0.2');
  final dC = TextEditingController(text: '60');

  double temp(double t) => ta + (t0 - ta) * math.exp(-k * t);
  List<FlSpot> series(int n) => List.generate(n + 1, (i) {
    final x = duration * i / n;
    return FlSpot(x, temp(x));
  });

  void apply() {
    double p(TextEditingController c, double f) =>
        double.tryParse(c.text.replaceAll(',', '.')) ?? f;
    setState(() {
      t0 = p(t0C, t0);
      ta = p(taC, ta);
      k = p(kC, k).abs();
      duration = p(dC, duration).clamp(1, 1e6);
      if (tMarker > duration) tMarker = duration;
    });
  }

  void _tick() {
    // Cada 50 ms avanzamos velocidad*(0.05 min)
    setState(() {
      tMarker = (tMarker + _speed * 0.05);
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
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
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
    final minY = [temp(0), temp(duration), ta].reduce(math.min) - 2;
    final maxY = [temp(0), temp(duration), ta].reduce(math.max) + 2;
    final tau = 1.0 / (k == 0 ? 1e-9 : k); // constante de tiempo
    final tHalf = math.ln2 / (k == 0 ? 1e-9 : k); // media vida
    final t95 = math.log(20) / (k == 0 ? 1e-9 : k); // ~95% hacia Ta
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                numField('T₀ (°C)', t0C),
                numField('Tₐ (°C)', taC),
                numField('k (1/min)', kC),
                numField('Duración (min)', dC),
                FilledButton.icon(
                  onPressed: apply,
                  icon: const Icon(Icons.check),
                  label: const Text('Aplicar'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Métricas rápidas
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('τ ≈ ${tau.toStringAsFixed(2)} min')),
                Chip(label: Text('t½ ≈ ${tHalf.toStringAsFixed(2)} min')),
                Chip(label: Text('t95% ≈ ${t95.toStringAsFixed(2)} min')),
                ActionChip(
                  avatar: const Icon(Icons.local_cafe, size: 16),
                  label: const Text('Bebida'),
                  onPressed: () {
                    setState(() {
                      t0 = 60;
                      ta = 25;
                      k = 0.25;
                      duration = 30;
                      t0C.text = '60';
                      taC.text = '25';
                      kC.text = '0.25';
                      dC.text = '30';
                      tMarker = 0;
                    });
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.memory, size: 16),
                  label: const Text('CPU'),
                  onPressed: () {
                    setState(() {
                      t0 = 70;
                      ta = 25;
                      k = 0.35;
                      duration = 20;
                      t0C.text = '70';
                      taC.text = '25';
                      kC.text = '0.35';
                      dC.text = '20';
                      tMarker = 0;
                    });
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.ac_unit, size: 16),
                  label: const Text('Exterior frío'),
                  onPressed: () {
                    setState(() {
                      ta = 10;
                      taC.text = '10';
                      tMarker = 0;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: Card(
                elevation: 1.5,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                  child: LineChart(
                    LineChartData(
                      minX: -(math.max(0.5, duration * 0.04)),
                      maxX: duration + math.max(0.5, duration * 0.04),
                      minY: minY,
                      maxY: maxY,
                      gridData: const FlGridData(show: true),
                      titlesData: _titles(
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
                                    fontSize: 12,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: series(400),
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
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: ta,
                            color: Colors.teal,
                            dashArray: const [6, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              labelResolver: (_) =>
                                  'Tₐ ${ta.toStringAsFixed(1)}°C',
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
                              labelResolver: (_) =>
                                  't = ${tMarker.toStringAsFixed(1)} min',
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
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Controles en vivo
            Wrap(
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
                    Switch(
                      value: _loop,
                      onChanged: (v) => setState(() => _loop = v),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Velocidad'),
                    const SizedBox(width: 8),
                    DropdownButton<double>(
                      value: _speed,
                      items: const <double>[0.25, 0.5, 1.0, 2.0, 4.0, 8.0]
                          .map(
                            (double v) => DropdownMenuItem<double>(
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
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: tMarker.clamp(0, duration),
                    min: 0,
                    max: duration,
                    onChanged: (v) {
                      setState(() => tMarker = v);
                    },
                  ),
                ),
              ],
            ),
            // Fórmulas (aprovecha el espacio en blanco)
            FormulaCard(
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
                // Versión con tus valores actuales (sólo números, sin fracciones para evitar escapes)
                Math.tex(
                  "T(t) = ${ta.toStringAsFixed(2)} + (${t0.toStringAsFixed(2)} - ${ta.toStringAsFixed(2)}) e^{-${k.toStringAsFixed(3)} t}",
                  textStyle: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget numField(String label, TextEditingController c) => SizedBox(
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

// 2) Apartado ejemplo de servidores
class ServerExamplePage extends StatefulWidget {
  const ServerExamplePage({super.key});
  @override
  State<ServerExamplePage> createState() => _ServerExamplePageState();
}

class _ServerExamplePageState extends State<ServerExamplePage> {
  double t0 = 60, ta = 25, P = 200, C = 5000, hA = 54, duration = 60;
  double get k => (hA / C) * 60; // 1/min
  double get q => (P / C) * 60; // °C/min
  double tMarker = 0;
  bool _running = false;
  double _speed = 1.0; // minutos simulados por segundo
  Timer? _timer;

  final t0C = TextEditingController(text: '60');
  final taC = TextEditingController(text: '25');
  final pC = TextEditingController(text: '200');
  final cC = TextEditingController(text: '5000');
  final haC = TextEditingController(text: '54');
  final dC = TextEditingController(text: '60');

  double temp(double t) =>
      ta +
      (t0 - ta - q / (k == 0 ? 1 : k)) * math.exp(-k * t) +
      (k == 0 ? 0 : q / k);
  List<FlSpot> series(int n) => List.generate(n + 1, (i) {
    final x = duration * i / n;
    return FlSpot(x, temp(x));
  });

  void apply() {
    double p(TextEditingController c, double f) =>
        double.tryParse(c.text.replaceAll(',', '.')) ?? f;
    setState(() {
      t0 = p(t0C, t0);
      ta = p(taC, ta);
      P = p(pC, P);
      C = p(cC, C).abs();
      hA = p(haC, hA).abs();
      duration = p(dC, duration).clamp(1, 1e6);
      if (tMarker > duration) tMarker = duration;
    });
  }

  void _tick() {
    setState(() {
      tMarker = (tMarker + _speed * 0.05).clamp(0, duration);
      if (tMarker >= duration) _stop();
    });
  }

  void _start() {
    if (_running) return;
    _running = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
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
    final steady = ta + (hA > 0 ? P / hA : 0);
    final currentT = temp(tMarker);
    final minY =
        [temp(0), temp(duration), ta, steady].reduce((a, b) => math.min(a, b)) -
        2;
    final maxY =
        [temp(0), temp(duration), ta, steady].reduce((a, b) => math.max(a, b)) +
        2;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final chartHeight = isWide ? 190.0 : 160.0;
          final left = Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      numField('T₀ (°C)', t0C),
                      numField('Tₐ (°C)', taC),
                      numField('P (W)', pC),
                      numField('C (J/°C)', cC),
                      numField('hA (W/°C)', haC),
                      numField('Duración (min)', dC),
                      FilledButton.icon(
                        onPressed: apply,
                        icon: const Icon(Icons.check),
                        label: const Text('Aplicar'),
                      ),
                      Chip(label: Text('T∞ ≈ ${steady.toStringAsFixed(2)} °C')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: chartHeight + 20,
                    child: Card(
                      elevation: 1.5,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                        child: LineChart(
                          LineChartData(
                            minX: -(math.max(0.5, duration * 0.04)),
                            maxX: duration + math.max(0.5, duration * 0.04),
                            minY: minY,
                            maxY: maxY,
                            gridData: const FlGridData(show: true),
                            titlesData: _titles(
                              duration,
                              minY,
                              maxY,
                              xMin: 0,
                              xMax: duration,
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: const Border.symmetric(
                                horizontal: BorderSide(
                                  color: Color(0x22000000),
                                ),
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
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: series(400),
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
                            extraLinesData: ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: ta,
                                  color: Colors.teal,
                                  dashArray: const [6, 4],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    labelResolver: (_) =>
                                        'Tₐ ${ta.toStringAsFixed(1)}°C',
                                  ),
                                ),
                                HorizontalLine(
                                  y: steady,
                                  color: Colors.orangeAccent,
                                  dashArray: const [6, 4],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    labelResolver: (_) =>
                                        'T∞ ${steady.toStringAsFixed(1)}°C',
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
                                    labelResolver: (_) =>
                                        't = ${tMarker.toStringAsFixed(1)} min',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
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
                          const SizedBox(width: 8),
                          DropdownButton<double>(
                            value: _speed,
                            items: const <double>[0.25, 0.5, 1.0, 2.0, 4.0, 8.0]
                                .map(
                                  (double v) => DropdownMenuItem<double>(
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
                  ),
                  const SizedBox(height: 8),
                  Row(
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
                  ),
                  FormulaCard(
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
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
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
                  ),
                ],
              ),
            ),
          );
          final rightContent = DataCenterView(
            ambient: ta,
            temperature: currentT,
            steady: steady,
            powerWatts: P,
          );
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                left,
                const SizedBox(width: 16),
                Expanded(flex: 1, child: rightContent),
              ],
            );
          } else {
            // Rehacer la columna izquierda sin Expanded y permitir scroll
            final leftSmall = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    numField('T₀ (°C)', t0C),
                    numField('Tₐ (°C)', taC),
                    numField('P (W)', pC),
                    numField('C (J/°C)', cC),
                    numField('hA (W/°C)', haC),
                    numField('Duración (min)', dC),
                    FilledButton.icon(
                      onPressed: apply,
                      icon: const Icon(Icons.check),
                      label: const Text('Aplicar'),
                    ),
                    Chip(label: Text('T∞ ≈ ${steady.toStringAsFixed(2)} °C')),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: chartHeight + 20,
                  child: Card(
                    elevation: 1.5,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                      child: LineChart(
                        LineChartData(
                          minX: -(math.max(0.5, duration * 0.04)),
                          maxX: duration + math.max(0.5, duration * 0.04),
                          minY: minY,
                          maxY: maxY,
                          gridData: const FlGridData(show: true),
                          titlesData: _titles(
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
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: series(400),
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
                          extraLinesData: ExtraLinesData(
                            horizontalLines: [
                              HorizontalLine(
                                y: ta,
                                color: Colors.teal,
                                dashArray: const [6, 4],
                                label: HorizontalLineLabel(
                                  show: true,
                                  labelResolver: (_) =>
                                      'Tₐ ${ta.toStringAsFixed(1)}°C',
                                ),
                              ),
                              HorizontalLine(
                                y: steady,
                                color: Colors.orangeAccent,
                                dashArray: const [6, 4],
                                label: HorizontalLineLabel(
                                  show: true,
                                  labelResolver: (_) =>
                                      'T∞ ${steady.toStringAsFixed(1)}°C',
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
                                  labelResolver: (_) =>
                                      't = ${tMarker.toStringAsFixed(1)} min',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
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
                        const SizedBox(width: 8),
                        DropdownButton<double>(
                          value: _speed,
                          items: const <double>[0.25, 0.5, 1.0, 2.0, 4.0, 8.0]
                              .map(
                                (double v) => DropdownMenuItem<double>(
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
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Slider(
                      value: tMarker.clamp(0, duration),
                      min: 0,
                      max: duration,
                      onChanged: (v) => setState(() => tMarker = v),
                    ),
                  ],
                ),
                FormulaCard(
                  title: 'Fórmulas y ecuaciones',
                  lines: [
                    Math.tex(
                      r"C\,\frac{dT}{dt} = -hA\,(T-T_a) + P",
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    Math.tex(
                      r"k=\frac{hA}{C},\; q=\frac{P}{C}\;\Rightarrow\; \frac{dT}{dt} = -k(T-T_a)+q",
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
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
                ),
              ],
            );
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leftSmall,
                  const SizedBox(height: 12),
                  SizedBox(height: 320, child: rightContent),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget numField(String label, TextEditingController c) => SizedBox(
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
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Header with indicators
          Row(
            children: [
              Icon(Icons.dns, color: tempColor(widget.temperature)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.7,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: tempColor(widget.temperature),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _BlinkLed(color: Colors.greenAccent, controller: _c, phase: 0.0),
              const SizedBox(width: 4),
              _BlinkLed(color: Colors.amberAccent, controller: _c, phase: 0.33),
              const SizedBox(width: 4),
              _BlinkLed(color: Colors.redAccent, controller: _c, phase: 0.66),
            ],
          ),
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
                      color: tempColor(widget.temperature - i),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Footer labels (escala automática para caber en anchuras pequeñas)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tₐ ${widget.ambient.toStringAsFixed(1)}°C',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  'T ${widget.temperature.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    color: tempColor(widget.temperature),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.steady != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'T∞ ${widget.steady!.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
        return Stack(
          children: [
            Align(
              alignment: Alignment(-1.0, inY * 2 - 1),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.lightBlueAccent.withValues(alpha: 0.9),
              ),
            ),
            Align(
              alignment: Alignment(1.05, outY * 2 - 1),
              child: Transform.rotate(
                angle: math.pi,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.orangeAccent.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        );
      },
    );

    return Stack(
      children: [
        Positioned.fill(child: rack),
        Positioned.fill(child: airflow),
      ],
    );
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
      child: Row(
        children: [
          // Fans
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                (i) => _Fan(
                  controller: controller,
                  color: color,
                  speed: 1.0 + i * 0.2,
                ),
              ),
            ),
          ),
          // LEDs column (compact to avoid tiny-height overflows)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MiniLed(
                color: Colors.lightGreenAccent,
                controller: controller,
                phase: 0.1,
              ),
              _MiniLed(
                color: Colors.cyanAccent,
                controller: controller,
                phase: 0.5,
              ),
              _MiniLed(
                color: Colors.deepPurpleAccent,
                controller: controller,
                phase: 0.8,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fan extends StatelessWidget {
  const _Fan({
    required this.controller,
    required this.color,
    required this.speed,
  });
  final AnimationController controller;
  final Color color;
  final double speed;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withValues(alpha: 0.15), Colors.black],
                stops: const [0.3, 1.0],
              ),
              border: Border.all(color: Colors.grey.shade800, width: 1),
            ),
          ),
          Center(
            child: RotationTransition(
              turns: Tween<double>(begin: 0, end: speed).animate(controller),
              child: Icon(
                Icons.settings,
                size: 20,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkLed extends StatelessWidget {
  const _BlinkLed({
    required this.color,
    required this.controller,
    required this.phase,
  });
  final Color color;
  final AnimationController controller;
  final double phase;
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity:
          TweenSequence([
            TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.0), weight: 50),
            TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.2), weight: 50),
          ]).animate(
            CurvedAnimation(
              parent: controller,
              curve: Interval(phase, (phase + 0.9).clamp(0.0, 1.0)),
            ),
          ),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6),
          ],
        ),
      ),
    );
  }
}

class _MiniLed extends StatelessWidget {
  const _MiniLed({
    required this.color,
    required this.controller,
    required this.phase,
  });
  final Color color;
  final AnimationController controller;
  final double phase;
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Interval(phase, (phase + 0.5).clamp(0.0, 1.0)),
        ),
      ),
      child: Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 3),
          ],
        ),
      ),
    );
  }
}

// Vista de Datacenter con varios racks y pasillos Cold/Hot
class DataCenterView extends StatefulWidget {
  const DataCenterView({
    super.key,
    required this.ambient,
    required this.temperature,
    this.steady,
    this.powerWatts,
  });
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
        return Stack(
          children: [
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
              child: Row(
                children: const [
                  Icon(Icons.ac_unit, size: 14, color: Colors.lightBlueAccent),
                  SizedBox(width: 4),
                  Text(
                    'Cold Aisle',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.lightBlueAccent,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Row(
                children: const [
                  Icon(
                    Icons.local_fire_department,
                    size: 14,
                    color: Colors.orangeAccent,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Hot Aisle',
                    style: TextStyle(fontSize: 12, color: Colors.orangeAccent),
                  ),
                ],
              ),
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
                    return Stack(
                      children: [
                        Align(
                          alignment: Alignment(-1.0, (0.3 + 0.4 * ph) * 2 - 1),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                            color: Colors.lightBlueAccent.withValues(
                              alpha: 0.9,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment(1.0, (0.7 - 0.4 * ph) * 2 - 1),
                          child: Transform.rotate(
                            angle: math.pi,
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                              color: Colors.orangeAccent.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
