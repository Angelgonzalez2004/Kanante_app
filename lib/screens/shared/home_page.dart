import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String userName;
  final List<Widget> shortcutButtons;

  const HomePage({super.key, required this.userName, required this.shortcutButtons});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900.0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bienvenido de nuevo,', style: textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
                Text(userName, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 24),
                // Enhanced Introductory Container
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: (0.08 * 255).toDouble()),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: (0.2 * 255).toDouble())),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.spa_outlined, color: Theme.of(context).colorScheme.primary, size: 30),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Kananté (del maya "cuidar" o "proteger") es tu espacio seguro para conectar con profesionales de la salud mental.',
                          style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Accesos Rápidos', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200, // Each item can have a max width of 200
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1, // To keep items squarish
                  ),
                  itemCount: shortcutButtons.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) => shortcutButtons[index],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
