import 'package:flutter/material.dart';
import '../features/newton_cooling/newton_simple_page.dart';
import '../features/server_simulation/server_example_page.dart';
import '../features/share/share_dialog.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _index = 0;
  // Tema: permite cambiar el color semilla para dar una identidad visual
  final List<MaterialColor> _seedOptions = const [
    Colors.indigo,
    Colors.teal,
    Colors.deepPurple,
  ];
  int _themeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simulador – Ley de Enfriamiento de Newton',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seedOptions[_themeIndex]),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          floatingLabelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          labelStyle: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Simulador de Enfriamiento'),
          actions: [
            // Selector rápido de color del tema
            PopupMenuButton<int>(
              tooltip: 'Tema',
              icon: const Icon(Icons.palette_outlined),
              onSelected: (i) => setState(() => _themeIndex = i),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 0,
                  child: _ThemeOption(color: _seedOptions[0], label: 'Indigo'),
                ),
                PopupMenuItem(
                  value: 1,
                  child: _ThemeOption(color: _seedOptions[1], label: 'Turquesa'),
                ),
                PopupMenuItem(
                  value: 2,
                  child: _ThemeOption(color: _seedOptions[2], label: 'Morado'),
                ),
              ],
            ),
            IconButton(
              tooltip: 'Compartir',
              icon: const Icon(Icons.share),
              onPressed: () => ShareDialog.show(context),
            ),
          ],
        ),
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

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
