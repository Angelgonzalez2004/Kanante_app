import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;

  int _totalUsers = 0;
  int _totalProfessionals = 0;
  int _totalAppointmentsPending = 0;
  int _totalAppointmentsCompleted = 0;
  int _totalAppointmentsCancelled = 0;
  int _totalPublications = 0;
  int _totalReviews = 0;
  double _averageProfessionalRating = 0.0; // This would be an average across all professionals

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      _totalUsers = await _firebaseService.getTotalUsersCount();
      _totalProfessionals = await _firebaseService.getTotalProfessionalsCount();
      _totalPublications = await _firebaseService.getTotalPublicationsCount();
      _totalReviews = await _firebaseService.getTotalReviewsCount();
      
      final appointmentCounts = await _firebaseService.getAppointmentCountsByStatus();
      _totalAppointmentsPending = appointmentCounts['pending'] ?? 0;
      _totalAppointmentsCompleted = appointmentCounts['completed'] ?? 0;
      _totalAppointmentsCancelled = appointmentCounts['cancelled'] ?? 0;

      // Calculate overall average rating (this would require iterating through all professionals and their average ratings)
      // For simplicity, this is an average of all existing reviews.
      // A dedicated Firebase Cloud Function would be more efficient for real-time overall average.
      // For now, let's just get total reviews and use 0.0 for average professional rating
      _averageProfessionalRating = 0.0; // Reset for now.

    } catch (e) {
      debugPrint("Error loading analytics data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos analíticos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetricCard(
                        title: 'Usuarios Totales',
                        value: _totalUsers.toString(),
                        icon: Icons.people,
                        color: Colors.blue.shade600,
                      ),
                      _buildMetricCard(
                        title: 'Profesionales Totales',
                        value: _totalProfessionals.toString(),
                        icon: Icons.medical_services,
                        color: Colors.green.shade600,
                      ),
                      _buildMetricCard(
                        title: 'Publicaciones Totales',
                        value: _totalPublications.toString(),
                        icon: Icons.article,
                        color: Colors.orange.shade600,
                      ),
                      _buildMetricCard(
                        title: 'Reseñas Totales',
                        value: _totalReviews.toString(),
                        icon: Icons.star,
                        color: Colors.purple.shade600,
                      ),
                      _buildMetricCard(
                        title: 'Calificación Promedio Profesional',
                        value: _averageProfessionalRating.toStringAsFixed(1),
                        icon: Icons.star_half,
                        color: Colors.amber.shade600,
                      ),
                      const Divider(height: 32),
                      Text(
                        'Estado de Citas',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      _buildMetricCard(
                        title: 'Citas Pendientes',
                        value: _totalAppointmentsPending.toString(),
                        icon: Icons.hourglass_empty,
                        color: Colors.grey.shade600,
                      ),
                      _buildMetricCard(
                        title: 'Citas Completadas',
                        value: _totalAppointmentsCompleted.toString(),
                        icon: Icons.check_circle,
                        color: Colors.teal.shade600,
                      ),
                      _buildMetricCard(
                        title: 'Citas Canceladas',
                        value: _totalAppointmentsCancelled.toString(),
                        icon: Icons.cancel,
                        color: Colors.red.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard({required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
