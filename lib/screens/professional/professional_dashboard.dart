import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kanante_app/models/alert_model.dart';
import 'package:kanante_app/services/firebase_service.dart';
import '../shared/home_page.dart';
import '../shared/publication_feed_page.dart';
import 'patients_page.dart';
import 'appointments_page.dart';
import 'messages_page.dart';
import 'publications_page.dart';
import 'settings_page.dart';
import 'new_publication_page.dart'; // Added for FAB
import '../shared/support_screen.dart';
import 'profile_page.dart'; // Este archivo debe contener la clase ProfessionalProfilePage
import '../shared/my_alerts_screen.dart'; // New import
import '../shared/appointments_reminder_screen.dart'; // New import for AppointmentsReminderScreen
import 'professional_availability_screen.dart'; // New import

class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});

  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseService _firebaseService = FirebaseService();

  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _sections = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfessionalData();
  }

  Future<void> _loadProfessionalData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final snapshot = await _db.child('users/${user.uid}').get();
      if (snapshot.exists && mounted) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _userData = data;
          _initializeSections();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar datos: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initializeSections() {
    _sections = [
      {
        'title': 'Inicio',
        'icon': Icons.dashboard_rounded,
        'page': HomePage(
          userName: _userData?['name'] ?? 'Profesional',
        )
      },
      {
        'title': 'Feed',
        'icon': Icons.explore_rounded,
        'page': const PublicationFeedPage()
      },
      {
        'title': 'Pacientes',
        'icon': Icons.people_alt_rounded,
        'page': const PatientsPage()
      },
      {
        'title': 'Citas',
        'icon': Icons.calendar_month_rounded,
        'page': const AppointmentsPage()
      },
      {
        'title': 'Mensajes',
        'icon': Icons.message_rounded,
        'page': const MessagesPage()
      },
      {
        'title': 'Publicaciones',
        'icon': Icons.article_rounded,
        'page': const PublicationsPage()
      },
      {
        'title': 'Citas Agendadas', // New section for reminders
        'icon': Icons.event_note_rounded,
        'page': const AppointmentsReminderScreen(),
      },
      {
        'title': 'Disponibilidad', // New section for professional availability
        'icon': Icons.schedule_rounded,
        'page': const ProfessionalAvailabilityScreen(),
      },
      {
        'title': 'Ajustes',
        'icon': Icons.settings_rounded,
        'page': const SettingsPage()
      },
      {
        'title': 'Mi Perfil',
        'icon': Icons.person_rounded,
        // CORRECCIÓN PRINCIPAL: Usamos el nombre correcto de la clase.
        // Si tu perfil requiere el ID, usa: ProfessionalProfilePage(professionalUid: _auth.currentUser!.uid)
        'page': const ProfessionalProfilePage() 
      },
      {
        'title': 'Soporte',
        'icon': Icons.support_agent,
        'page': const SupportScreen()
      },
      {
        'title': 'Mis Alertas',
        'icon': Icons.notifications_active,
        'page': const MyAlertsScreen()
      },
      {
        'title': 'Cerrar Sesión',
        'icon': Icons.logout_rounded,
        'isLogout': true, // Bandera especial para logout
      },
    ];
  }

  void _onItemTapped(int index) {
    // Verificación de seguridad: Si es el botón de logout, ejecutamos logout y NO cambiamos de página
    if (_sections[index]['isLogout'] == true) {
      _logout();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
     if (MediaQuery.of(context).size.width < 600 && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Cierre de Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar la sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, Salir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cerrando sesión en 3 segundos...'),
          duration: Duration(seconds: 3),
        ),
      );

      // Wait for 3 seconds
      await Future.delayed(const Duration(seconds: 3));

      // Sign out
      await _auth.signOut();

      // Navigate to Login screen and remove all previous routes
      // Note: This conflicts with the AuthWrapper pattern, but is implemented as requested.
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator()),
      );
    }

    if (_sections.isEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No se pudieron cargar los datos del usuario.'),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: _loadProfessionalData,
                    child: const Text('Reintentar'))
              ],
            ),
          ),
        ),
      );
    }

    final isLargeScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(_sections[_selectedIndex]['title']),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      drawer: !isLargeScreen ? _buildDrawer() : null,
      body: Row(
        children: [
          if (isLargeScreen) _buildSideBar(),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _sections
                  .where((s) => s['isLogout'] != true) // Filtramos el logout para el Stack de páginas
                  .map<Widget>((s) => s['page'])
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: (_selectedIndex == 5) // 'Publicaciones'
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const NewPublicationPage()),
                );
              },
              backgroundColor: Colors.indigo,
              child: const Icon(Icons.add),
            )
          : null, // No FAB for other pages
    );
  }

  Widget _buildSideBar() {
    return StreamBuilder<List<AlertModel>>(
      stream: _firebaseService.getAlertsForRecipient(_auth.currentUser!.uid),
      builder: (context, snapshot) {
        final unreadCount = snapshot.hasData
            ? snapshot.data!.where((a) => a.status == 'unread').length
            : 0;
        return NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          labelType: NavigationRailLabelType.all,
          leading: Column(
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 20),
              const Divider(),
            ],
          ),
          destinations: _sections.where((s) => s['isLogout'] != true).map<NavigationRailDestination>((section) {
             final isAlerts = section['title'] == 'Mis Alertas';
            return NavigationRailDestination(
              icon: Badge(
                isLabelVisible: isAlerts && unreadCount > 0,
                label: Text('$unreadCount'),
                child: Icon(section['icon']),
              ),
              label: Text(section['title']),
            );
          }).toList(),
        );
      }
    );
  }

  Widget _buildDrawer() {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.primary,
            ),
            child: _buildHeader(),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final section = _sections[index];
                // Resaltamos la opción seleccionada (excepto si es logout)
                final selected = _selectedIndex == index && section['isLogout'] != true;

                if (section['isLogout'] == true) {
                  return Column(
                    children: [
                      const Divider(),
                      ListTile(
                        leading: Icon(section['icon'], color: Colors.red),
                        title: Text(
                          section['title'],
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        onTap: _logout, // Llamada directa
                      ),
                    ],
                  );
                } else if (section['title'] == 'Mis Alertas') {
                  return StreamBuilder<List<AlertModel>>(
                    stream: _firebaseService.getAlertsForRecipient(_auth.currentUser!.uid),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.hasData
                          ? snapshot.data!.where((a) => a.status == 'unread').length
                          : 0;
                      return ListTile(
                        leading: Badge(
                          isLabelVisible: unreadCount > 0,
                          label: Text('$unreadCount'),
                          child: Icon(section['icon'], color: selected ? colorScheme.primary : null),
                        ),
                        title: Text(
                          section['title'],
                          style: TextStyle(color: selected ? colorScheme.primary : null, fontWeight: selected ? FontWeight.bold : null),
                        ),
                        onTap: () {
                          _onItemTapped(index);
                           if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                           }
                        },
                      );
                    }
                  );
                }
                else {
                  return ListTile(
                    leading: Icon(section['icon'], color: selected ? colorScheme.primary : null),
                    title: Text(
                      section['title'],
                      style: TextStyle(color: selected ? colorScheme.primary : null, fontWeight: selected ? FontWeight.bold : null),
                    ),
                    onTap: () {
                      _onItemTapped(index);
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context); // Cierra el drawer
                      }
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final imageUrl = _userData?['profileImageUrl'] as String?;
    final name = _userData?['name'] ?? 'Profesional';
    final email = _userData?['email'] ?? '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
          backgroundColor: Color.fromRGBO(255, 255, 255, 0.3), // Changed deprecated withOpacity
          child: (imageUrl == null || imageUrl.isEmpty) ? const Icon(Icons.psychology_alt_rounded, size: 32, color: Colors.white) : null, // Moved child to last
        ),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }
}