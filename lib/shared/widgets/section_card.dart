import 'package:flutter/material.dart';
import '../../shared/utils.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.icon,
    this.actions = const <Widget>[],
    required this.child,
  });

  final String title;
  final IconData? icon;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
            _Header(title: title, icon: icon, actions: actions),
            const SizedBox(height: UIConstants.defaultSpacing),
            child,
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.icon, required this.actions});
  final String title;
  final IconData? icon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final hasActions = actions.isNotEmpty;
    return LayoutBuilder(builder: (context, c) {
      final isTight = c.maxWidth < 520;
      final row = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasActions) ...[
            const SizedBox(width: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: actions,
            )
          ]
        ],
      );
      if (!hasActions) return row;
      if (!isTight) return row;
      // For narrow widths, stack actions below title.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions,
          ),
        ],
      );
    });
  }
}
