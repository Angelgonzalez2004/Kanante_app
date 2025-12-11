import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:kanante_app/models/publication_model.dart';
import 'package:kanante_app/theme/app_colors.dart';
import 'package:kanante_app/screens/user/professional_search_page.dart'; // To navigate to search

class UserHomePage extends StatefulWidget {
  final String userName;

  const UserHomePage({super.key, required this.userName});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _upcomingAppointments = 0;
  List<Publication> _recentPublications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDashboardData();
  }

  Future<void> _loadUserDashboardData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final upcomingAppointments = await _firebaseService.getUpcomingAppointmentsForUser(user.uid);
      final allPublications = await _firebaseService.getAllPublications();

      if (mounted) {
        setState(() {
          _upcomingAppointments = upcomingAppointments.length;
          _recentPublications = allPublications.take(3).toList(); // Show top 3 recent publications
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading user dashboard data: $e');
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
                        'Tu resumen personal.',
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
                      onTap: () {
                        // Navigate to appointments page
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Text('Ir a Citas'))); // Placeholder
                      },
                    ),
                    _buildCard(
                      context,
                      title: 'Buscar Profesionales',
                      value: 'Encuentra tu experto',
                      icon: Icons.search_rounded,
                      color: AppColors.accent,
                      onTap: () {
                        // Navigate to professional search page
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfessionalSearchPage()));
                      },
                    ),
                    // Add more user-specific metrics or quick actions here
                  ],
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Publicaciones Recientes',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _recentPublications.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                        child: Text('No hay publicaciones recientes.'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentPublications.length,
                        itemBuilder: (context, index) {
                          final pub = _recentPublications[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            elevation: 2,
                            child: ListTile(
                              leading: const Icon(Icons.article_outlined),
                              title: Text(pub.title),
                              subtitle: Text('${pub.content.toString().substring(0, pub.content.toString().length > 50 ? 50 : pub.content.toString().length)}...'),
                              onTap: () {
                                // Navigate to publication detail page
                              },
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 30),
              ],
            ),
          );
  }

  Widget _buildCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color, VoidCallback? onTap}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell( // Use InkWell for tap feedback
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
            children: [
              Icon(icon, size: 30, color: color),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
