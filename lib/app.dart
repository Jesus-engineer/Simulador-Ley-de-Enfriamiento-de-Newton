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

  static const _pages = [NewtonSimplePage(), ServerExamplePage()];
  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.functions), label: 'Ley'),
    NavigationDestination(icon: Icon(Icons.dns), label: 'Servidor'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        floatingLabelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        labelStyle: TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );

    return MaterialApp(
      title: 'Simulador – Ley de Enfriamiento de Newton',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Simulador de Enfriamiento'),
          actions: [
            IconButton(
              tooltip: 'Compartir',
              icon: const Icon(Icons.share),
              onPressed: () => ShareDialog.show(context),
            ),
          ],
        ),
        body: IndexedStack(
          index: _index,
          children: _pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          destinations: _destinations,
          onDestinationSelected: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
