import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:kanante_app/theme/app_colors.dart';

class ProfessionalHomePage extends StatefulWidget {
  final String userName;

  const ProfessionalHomePage({super.key, required this.userName});

  @override
  State<ProfessionalHomePage> createState() => _ProfessionalHomePageState();
}

class _ProfessionalHomePageState extends State<ProfessionalHomePage> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _upcomingAppointments = 0;
  int _unreadMessages = 0;
  double _averageRating = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfessionalDashboardData();
  }

  Future<void> _loadProfessionalDashboardData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final upcomingAppointments = await _firebaseService.getUpcomingAppointmentsForProfessional(user.uid);
      final unreadMessages = await _firebaseService.getUnreadMessageCountForUser(user.uid);
      final reviews = await _firebaseService.getReviewsForProfessional(user.uid);

      if (mounted) {
        setState(() {
          _upcomingAppointments = upcomingAppointments.length;
          _unreadMessages = unreadMessages;
          if (reviews.isNotEmpty) {
            _averageRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
          } else {
            _averageRating = 0.0;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading professional dashboard data: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, ${widget.userName}!',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tu resumen de actividad reciente.',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                  childAspectRatio: 2.5,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  children: [
                    _buildCard(
                      context,
                      title: 'Próximas Citas',
                      value: _upcomingAppointments.toString(),
                      icon: Icons.calendar_today_rounded,
                      color: AppColors.primary,
                    ),
                    _buildCard(
                      context,
                      title: 'Mensajes Sin Leer',
                      value: _unreadMessages.toString(),
                      icon: Icons.message_rounded,
                      color: Colors.teal.shade700,
                    ),
                    _buildCard(
                      context,
                      title: 'Calificación Promedio',
                      value: _averageRating.toStringAsFixed(1),
                      icon: Icons.star_rounded,
                      color: Colors.amber.shade700,
                    ),
                    // Add more professional-specific metrics here
                  ],
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Análisis de Perfil (Placeholder)',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.grey.withAlpha((255 * 0.1).round()),
                                                            spreadRadius: 1,
                                                            blurRadius: 5,
                                                            offset: const Offset(0, 3),
                                                          ),                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Completitud del Perfil: 80%', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      LinearProgressIndicator(value: 0.8, color: AppColors.accent),
                      SizedBox(height: 5),
                      Text('Completa tu información para mayor visibilidad.'),
                      SizedBox(height: 20),
                      Text('Visitas al Perfil: +15% esta semana', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      LinearProgressIndicator(value: 0.6, color: AppColors.success),
                      SizedBox(height: 5),
                      Text('Tu perfil está atrayendo a nuevos pacientes.'),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      margin: EdgeInsets.zero, // Removed margin from here, added to GridView padding
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
