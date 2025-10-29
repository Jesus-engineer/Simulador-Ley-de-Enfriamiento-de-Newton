import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils.dart';

/// Creates axis titles configuration for charts
class ChartTitlesConfig {
  static FlTitlesData create(
    double spanX,
    double minY,
    double maxY, {
    double xMin = 0,
    required double xMax,
  }) {
    final ySpan = (maxY - minY).abs();
    final xStep = MathUtils.niceStep(spanX);
    final yStep = MathUtils.niceStep(ySpan);

    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 60,
          interval: yStep,
          getTitlesWidget: (v, meta) {
            if ((v - minY).abs() < yStep * 0.4 ||
                (maxY - v).abs() < yStep * 0.4) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  MathUtils.formatNumber(v, yStep),
                  style: const TextStyle(fontSize: UIConstants.defaultFontSize),
                ),
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
            if (v < xMin - 1e-6 || v > xMax + 1e-6) {
              return const SizedBox.shrink();
            }
            return Text(
              MathUtils.formatNumber(v, xStep),
              style: const TextStyle(fontSize: UIConstants.defaultFontSize),
            );
          },
        ),
      ),
    );
  }
}
