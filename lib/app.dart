import 'package:flutter/material.dart';
import '../features/newton_cooling/newton_simple_page.dart';
import '../features/server_simulation/server_example_page.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simulador – Ley de Enfriamiento de Newton',
      theme: ThemeData(
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
