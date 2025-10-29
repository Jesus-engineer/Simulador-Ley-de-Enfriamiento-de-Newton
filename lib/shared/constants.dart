/// Constants for temperature simulation
class TemperatureConstants {
  static const double defaultSimulationSpeed = 1.0; // minutes/second
  static const double simulationTickInterval = 0.05; // minutes
  static const int simulationUpdateRate = 50; // milliseconds
  static const int chartDataPoints = 400;

  static const double minTemperature = 0;
  static const double maxTemperature = 100;
  static const double defaultAmbientTemp = 25;

  // Server temperature ranges
  static const double serverMinTemp = 10.0;
  static const double serverMaxTemp = 35.0;
  static const double serverCriticalTemp = 45.0;

  static const Map<String, Map<String, double>> presets = {
    'drink': {'t0': 60, 'ta': 25, 'k': 0.25, 'duration': 30},
    'cpu': {'t0': 70, 'ta': 25, 'k': 0.35, 'duration': 20},
    'server': {
      't0': 60,
      'ta': 25,
      'P': 200,
      'C': 5000,
      'hA': 54,
      'duration': 60,
    },
  };
}

/// Constants for chart configuration
class ChartConstants {
  static const double defaultHeight = 200;
  static const double chartPadding = 2;
  static const double chartMarginPercent = 0.04;
}

/// Constants for animation
class AnimationConstants {
  static const Duration defaultDuration = Duration(milliseconds: 50);
  static const List<double> speeds = [0.25, 0.5, 1.0, 2.0, 4.0, 8.0];
}
