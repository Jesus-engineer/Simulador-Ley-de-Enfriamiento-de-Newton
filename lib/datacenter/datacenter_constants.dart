import 'package:flutter/material.dart';
import 'dart:math' as math;

class DataCenterViewConstants {
  static const double minWidth = 900.0;
  static const double defaultPadding = 8.0;
  static const double labelSpacing = 4.0;
  static const double labelFontSize = 12.0;
}

class DataCenterColors {
  static const coldAisleColor = Colors.lightBlueAccent;
  static const hotAisleColor = Colors.orangeAccent;
  static const backgroundColor = Colors.black54;

  static Color getTemperatureColor(double temp, double ambient, double steady) {
    final s = steady;
    final clamped = temp.clamp(ambient - 5, s + 15);
    final ratio = (clamped - (ambient - 5)) / ((s + 15) - (ambient - 5));
    return Color.lerp(Colors.blue.shade400, Colors.red.shade400, ratio) ??
        Colors.orange;
  }
}

class DataCenterAnimations {
  static const Duration animationDuration = Duration(seconds: 2);
  static const double coldAirPhase = 0.2;
  static const double hotAirPhase = 0.8;

  static double getColdAirPosition(double t) => coldAirPhase + 0.6 * t;
  static double getHotAirPosition(double t) => hotAirPhase - 0.6 * t;

  static const List<double> rackTemperatureVariations = [-1.5, 0.0, 1.5];
}
