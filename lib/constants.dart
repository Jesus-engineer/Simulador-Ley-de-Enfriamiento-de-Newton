// Constants for Newton's Cooling Law Simulator
class SimulationConstants {
  // Time simulation constants
  static const double defaultSimulationSpeed =
      1.0; // minutes simulated per second
  static const double simulationTickInterval = 0.05; // in minutes
  static const int simulationUpdateRate = 50; // in milliseconds
  static const int chartDataPoints = 400;

  // Chart visual constants
  static const double chartPadding = 2.0;
  static const double chartMarginPercent = 0.04;

  // Temperature presets
  static const Map<String, Map<String, double>> temperaturePresets = {
    'drink': {'t0': 60, 'ta': 25, 'k': 0.25, 'duration': 30},
    'cpu': {'t0': 70, 'ta': 25, 'k': 0.35, 'duration': 20},
    'coldExterior': {'ta': 10},
  };
}

// UI constants
class UIConstants {
  static const double cardElevation = 1.5;
  static const double borderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double defaultSpacing = 8.0;
}
