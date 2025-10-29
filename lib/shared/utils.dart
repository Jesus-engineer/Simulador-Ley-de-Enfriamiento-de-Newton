import 'dart:math' as math;

class MathUtils {
  /// Calculates a "nice" step size for chart axis divisions
  static double niceStep(double span) {
    if (span <= 0 || span.isNaN || span.isInfinite) return 1;
    final desired = span / 6;
    final log10 = math.log(desired) / math.ln10;
    final pow10 = math.pow(10, log10.floor()).toDouble();
    final residual = desired / pow10;
    return (residual <= 1
            ? 1
            : residual <= 2
            ? 2
            : residual <= 5
            ? 5
            : 10) *
        pow10;
  }

  /// Formats a number with appropriate decimal places based on step size
  static String formatNumber(double value, double step) =>
      value.toStringAsFixed(step >= 1 ? 0 : 1);

  /// Parses a numeric input with fallback value
  static double parseNumericInput(String text, double defaultValue) =>
      double.tryParse(text.replaceAll(',', '.')) ?? defaultValue;
}

class UIConstants {
  static const double defaultElevation = 1.5;
  static const double defaultBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double defaultSpacing = 8.0;
  static const double defaultFontSize = 12.0;
}
