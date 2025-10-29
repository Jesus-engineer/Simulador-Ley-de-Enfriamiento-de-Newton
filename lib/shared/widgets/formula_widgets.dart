import 'package:flutter/material.dart';
import '../utils.dart';

/// A reusable card widget for displaying formulas with LaTeX
class FormulaCard extends StatelessWidget {
  const FormulaCard({super.key, required this.title, required this.lines});

  final String title;
  final List<Widget> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: UIConstants.defaultElevation,
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate, size: 18),
                const SizedBox(width: UIConstants.defaultSpacing),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: UIConstants.defaultSpacing),
            ...lines.map(
              (w) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: w,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact numeric input field for use within formulas
class InlineNumField extends StatelessWidget {
  const InlineNumField({
    super.key,
    required this.label,
    required this.controller,
    required this.onSubmitted,
    this.width = 110,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => onSubmitted(),
      ),
    );
  }
}
