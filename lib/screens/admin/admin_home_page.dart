import 'package:flutter/material.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:kanante_app/theme/app_colors.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final FirebaseService _firebaseService = FirebaseService();
  int _pendingVerifications = 0;
  int _pendingPublications = 0;
  int _totalUsers = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminDashboardData();
  }

  Future<void> _loadAdminDashboardData() async {
    try {
      final allUsers = await _firebaseService.getAllUsers();
      final allPublications = await _firebaseService.getAllPublications();

      if (mounted) {
        setState(() {
          _totalUsers = allUsers.length;
          _pendingVerifications = allUsers.where((user) => user.accountType == 'professional' && user.verificationStatus == 'pending').length;
          _pendingPublications = allPublications.where((pub) => pub.status == 'pending').length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading admin dashboard data: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView( // Using SingleChildScrollView to prevent overflow
            padding: EdgeInsets.zero, // No padding at the top
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCard(
                  context,
                  title: 'Profesionales por Verificar',
                  value: _pendingVerifications.toString(),
                  icon: Icons.verified_user_outlined,
                  color: Colors.orange.shade700,
                ),
                _buildCard(
                  context,
                  title: 'Publicaciones Pendientes',
                  value: _pendingPublications.toString(),
                  icon: Icons.article_outlined,
                  color: AppColors.accent,
                ),
                _buildCard(
                  context,
                  title: 'Total de Usuarios Registrados',
                  value: _totalUsers.toString(),
                  icon: Icons.people_alt_outlined,
                  color: AppColors.primary,
                ),
                // Add more admin-specific metrics here
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Estadísticas Rápidas',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                // Placeholder for charts or more detailed info
                Container(
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gráfico de Crecimiento de Usuarios (Placeholder)', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      LinearProgressIndicator(value: 0.7),
                      SizedBox(height: 5),
                      Text('70% de crecimiento en el último mes.'),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
