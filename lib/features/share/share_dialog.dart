import 'package:flutter/material.dart';

class ShareDialog extends StatelessWidget {
  const ShareDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => const Dialog(
        insetPadding: EdgeInsets.all(16),
        child: ShareDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.share, size: 20),
                const SizedBox(width: 8),
                Text('Compartir', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Comparte tus resultados o captura de la gráfica.\n\n'
              'Sugerencia: toma una captura de pantalla de la app y envíala por tu canal preferido.',
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check),
                label: const Text('Entendido'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
