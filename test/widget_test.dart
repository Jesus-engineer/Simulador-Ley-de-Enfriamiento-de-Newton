// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simulacion_ley_newton/main.dart';

void main() {
  testWidgets('Carga tabs y controles básicos', (WidgetTester tester) async {
    // Desactiva animaciones para que pumpAndSettle no se quede esperando
    await tester.pumpWidget(const TickerMode(enabled: false, child: MyApp()));

    // Debe mostrar el título general
    expect(find.text('Simulador de Enfriamiento'), findsOneWidget);

    // En la pestaña Ley debe haber campos T0 y k
    expect(find.textContaining('T₀'), findsWidgets);
    expect(find.textContaining('k'), findsWidgets);

    // Cambiar a pestaña Servidor
  await tester.tap(find.text('Servidor'));
  await tester.pump(const Duration(milliseconds: 100));

    // Debe mostrar P, C y hA
    expect(find.textContaining('P (W)'), findsOneWidget);
    expect(find.textContaining('C (J/°C)'), findsOneWidget);
    expect(find.textContaining('hA (W/°C)'), findsOneWidget);
  });
}
