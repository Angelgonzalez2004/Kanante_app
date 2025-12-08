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
                Text(userName, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.teal.withAlpha(12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.withAlpha(51)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.teal.shade700, size: 30),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Kananté (del maya "cuidar" o "proteger") es tu espacio seguro para conectar con profesionales de la salud mental.',
                          style: textTheme.bodyMedium?.copyWith(color: Colors.teal.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Accesos Rápidos', style: textTheme.titleLarge),
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
