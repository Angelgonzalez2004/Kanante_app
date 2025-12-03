import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final void Function(int) onNavigate;

  const HomePage({
    super.key,
    this.userData,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final name = userData?['name']?.split(' ').first ?? 'Profesional';
    final email = userData?['email'] ?? 'Sin correo';
    final phone = userData?['phone'] ?? 'No registrado';
    final rawDate = userData?['createdAt'];
    final createdAt = _formatCreatedAt(rawDate);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "👋 Bienvenido, $name",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          Text(
            "Gestiona tus pacientes, citas y mensajes de forma eficiente.",
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.04),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "🧑‍⚕️ Tu Información",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const Divider(height: 24),
                  _infoRow(context, Icons.email_outlined, "Correo", email),
                  _infoRow(
                      context, Icons.phone_android_rounded, "Teléfono", phone),
                  _infoRow(context, Icons.calendar_today_rounded, "Cuenta Creada",
                      createdAt),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Accesos Rápidos",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _quickAction(context, Icons.people_alt_rounded, "Pacientes",
                  () => onNavigate(1)),
              _quickAction(context, Icons.calendar_month_rounded, "Citas",
                  () => onNavigate(2)),
              _quickAction(context, Icons.message_rounded, "Mensajes",
                  () => onNavigate(3)),
              _quickAction(
                  context, Icons.person_rounded, "Perfil", () => onNavigate(4)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCreatedAt(String? rawDate) {
    if (rawDate == null) return 'Desconocido';
    final dt = DateTime.tryParse(rawDate);
    if (dt == null) return rawDate;
    return DateFormat('dd MMM, yyyy', 'es_MX').format(dt);
  }

  Widget _infoRow(
      BuildContext context, IconData icon, String title, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 16),
          Text(
            "$title: ",
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.secondaryContainer,
        foregroundColor: theme.colorScheme.onSecondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
