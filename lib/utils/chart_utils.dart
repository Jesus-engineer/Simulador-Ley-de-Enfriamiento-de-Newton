import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Utilities for creating "nice" axis steps and formatting numbers
class ChartUtils {
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
}
