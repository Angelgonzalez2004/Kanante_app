import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
      // Optionally show a snackbar to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre Kananté'),
        backgroundColor: AppColors.primary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/logoapp.jpg', // Assuming you have a logo in assets
                    height: 120,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Nuestra Historia',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kananté nace de la visión y el esfuerzo de un equipo de universitarios de la Universidad Tecnológica de Campeche. Nos unió la preocupación por el creciente impacto de los problemas de salud mental en nuestra sociedad, como la depresión, la ansiedad, los pensamientos suicidas y el alcoholismo. Observamos la barrera que a menudo existe entre quienes necesitan ayuda y los profesionales capacitados para ofrecerla.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Con la misión de tender un puente entre ambos, desarrollamos Kananté: una aplicación diseñada para facilitar el acceso a servicios de apoyo psicológico y terapéutico de manera sencilla, segura y confidencial. Creemos firmemente que nadie debería enfrentar sus batallas internas en soledad, y que la tecnología puede ser un poderoso aliado para promover el bienestar mental.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Text(
                  'Contáctanos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.facebook, color: Colors.blue),
                  title: const Text('Síguenos en Facebook'),
                  subtitle: const Text('Kananté App Oficial'),
                  onTap: () => _launchUrl('https://www.facebook.com/profile.php?id=61584536472870'),
                ),
                ListTile(
                  leading: const Icon(Icons.email, color: AppColors.primary),
                  title: const Text('Envíanos un correo'),
                  subtitle: const Text('kanantecampeche@gmail.com'),
                  onTap: () => _launchUrl('mailto:kanantecampeche@gmail.com'),
                ),
                ListTile(
                  leading: const Icon(Icons.message, color: Colors.green), // Changed from Icons.whatsapp to Icons.message
                  title: const Text('Envíanos un WhatsApp'),
                  subtitle: const Text('+52 9381321268'),
                  onTap: () => _launchUrl('https://wa.me/529381321268'),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    '© 2025 Kananté. Todos los derechos reservados.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
