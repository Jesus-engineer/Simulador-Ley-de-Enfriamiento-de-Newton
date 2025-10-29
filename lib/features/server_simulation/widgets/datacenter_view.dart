import 'package:flutter/material.dart';
import '../../../shared/constants.dart';
import '../../../shared/ui_constants.dart';

class DataCenterView extends StatelessWidget {
  final double ambient;
  final double temperature;
  final double steady;
  final double powerWatts;

  const DataCenterView({
    super.key,
    required this.ambient,
    required this.temperature,
    required this.steady,
    required this.powerWatts,
  });

  /// Calculate temperature relative to operating range (0-1)
  double _getTemperatureRatio() {
    const min = TemperatureConstants.serverMinTemp;
    const max = TemperatureConstants.serverMaxTemp;
    return ((temperature - min) / (max - min)).clamp(0, 1);
  }

  /// Get color based on temperature range
  Color _getTemperatureColor() {
    final ratio = _getTemperatureRatio();
    return ColorTween(begin: Colors.blue, end: Colors.red).lerp(ratio)!;
  }

  /// Get description of current state
  String _getStatusDescription() {
    const min = TemperatureConstants.serverMinTemp;
    const max = TemperatureConstants.serverMaxTemp;
    const critical = TemperatureConstants.serverCriticalTemp;

    if (temperature < min) {
      return 'Temperatura por debajo del rango óptimo';
    } else if (temperature >= min && temperature <= max) {
      return 'Temperatura en rango óptimo';
    } else if (temperature > max && temperature <= critical) {
      return 'Temperatura por encima del rango óptimo';
    } else {
      return 'TEMPERATURA CRÍTICA - Riesgo de daño';
    }
  }

  IconData _getStatusIcon() {
    const min = TemperatureConstants.serverMinTemp;
    const max = TemperatureConstants.serverMaxTemp;
    const critical = TemperatureConstants.serverCriticalTemp;

    if (temperature < min) {
      return Icons.ac_unit;
    } else if (temperature >= min && temperature <= max) {
      return Icons.check_circle;
    } else if (temperature > max && temperature <= critical) {
      return Icons.warning;
    } else {
      return Icons.dangerous;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTemperatureColor();

    return Card(
      elevation: UIConstants.defaultElevation,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(
              temperature: temperature,
              color: color,
              icon: _getStatusIcon(),
              description: _getStatusDescription(),
            ),
            const SizedBox(height: UIConstants.defaultSpacing),
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    const separator = SizedBox(height: UIConstants.defaultSpacing);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Información del servidor'),
        separator,
        _ServerInfo(
          powerWatts: powerWatts,
          ambientTemp: ambient,
          steadyTemp: steady,
        ),
        separator,
        const _SectionTitle('Rangos de temperatura'),
        separator,
        _TemperatureRanges(currentTemp: temperature),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final double temperature;
  final Color color;
  final IconData icon;
  final String description;

  const _HeaderSection({
    required this.temperature,
    required this.color,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              '${temperature.toStringAsFixed(1)}°C',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: UIConstants.defaultSpacing),
            Icon(icon, color: color, size: 32),
          ],
        ),
        Text(
          description,
          style: TextStyle(fontSize: UIConstants.defaultFontSize, color: color),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: UIConstants.largeFontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _ServerInfo extends StatelessWidget {
  final double powerWatts;
  final double ambientTemp;
  final double steadyTemp;

  const _ServerInfo({
    required this.powerWatts,
    required this.ambientTemp,
    required this.steadyTemp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoRow(
          icon: Icons.power,
          label: 'Potencia consumida',
          value: '$powerWatts W',
        ),
        const SizedBox(height: 4),
        _InfoRow(
          icon: Icons.thermostat,
          label: 'Temperatura ambiente',
          value: '${ambientTemp.toStringAsFixed(1)}°C',
        ),
        const SizedBox(height: 4),
        _InfoRow(
          icon: Icons.trending_flat,
          label: 'Temperatura en estado estable',
          value: '${steadyTemp.toStringAsFixed(1)}°C',
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _TemperatureRanges extends StatelessWidget {
  final double currentTemp;

  const _TemperatureRanges({required this.currentTemp});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TemperatureRange(
          label: 'Rango óptimo',
          minTemp: TemperatureConstants.serverMinTemp,
          maxTemp: TemperatureConstants.serverMaxTemp,
          currentTemp: currentTemp,
          color: Colors.green,
        ),
        const SizedBox(height: UIConstants.defaultSpacing),
        _TemperatureRange(
          label: 'Rango crítico',
          minTemp: TemperatureConstants.serverMaxTemp,
          maxTemp: TemperatureConstants.serverCriticalTemp,
          currentTemp: currentTemp,
          color: Colors.orange,
        ),
      ],
    );
  }
}

class _TemperatureRange extends StatelessWidget {
  final String label;
  final double minTemp;
  final double maxTemp;
  final double currentTemp;
  final Color color;

  const _TemperatureRange({
    required this.label,
    required this.minTemp,
    required this.maxTemp,
    required this.currentTemp,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isInRange = currentTemp >= minTemp && currentTemp <= maxTemp;
    const height = 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            color: color.withOpacity(0.2),
          ),
          child: Row(
            children: [
              Container(
                width: height,
                height: height,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(isInRange ? 1 : 0.2),
                ),
                child: Icon(
                  isInRange ? Icons.check : Icons.remove,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${minTemp.toStringAsFixed(1)}°C - ${maxTemp.toStringAsFixed(1)}°C',
                style: TextStyle(fontWeight: FontWeight.w500, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
