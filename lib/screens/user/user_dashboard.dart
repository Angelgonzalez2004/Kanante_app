import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kanante_app/models/alert_model.dart';
import 'package:kanante_app/services/firebase_service.dart';
import '../shared/home_page.dart';
import '../shared/publication_feed_page.dart';
import 'user_profile_page.dart';
import 'user_settings_page.dart';
import 'my_appointments_screen.dart';
import '../shared/support_screen.dart';
import 'messages_page.dart';
import '../shared/my_alerts_screen.dart';
import '../shared/appointments_reminder_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseService _firebaseService = FirebaseService();

  String _userName = 'Usuario';
  String _userEmail = '';
  String _phone = '';
  String? _profileImageUrl;
  int _selectedIndex = 1; // Default to 'Feed de Contenido'

  late final List<Map<String, dynamic>> _sections;
  late final List<String> _pageTitles;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _pageTitles = [
      'Inicio',
      'Feed de Contenido',
      'Mis Citas',
      'Citas Agendadas',
      'Mensajes',
      'Mi Perfil',
      'Configuración',
      'Soporte',
      'Mis Alertas',
      'Cerrar Sesión'
    ];
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await _dbRef.child('users/${user.uid}').get();
      if (mounted) {
        setState(() {
          if (snapshot.exists) {
            final data = Map<String, dynamic>.from(snapshot.value as Map);
            _userName = data['name'] ?? 'Usuario';
            _phone = data['phone'] ?? '';
            _profileImageUrl = data['profileImageUrl'];
          }
          _userEmail = user.email ?? '';
          _initializeSections();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error loading user data: $e");
    }
  }

  void _initializeSections() {
    _sections = [
      {
        'title': _pageTitles[0],
        'icon': Icons.home,
        'page': HomePage(
          userName: _userName,
        )
      },
      {
        'title': _pageTitles[1],
        'icon': Icons.explore,
        'page': const PublicationFeedPage()
      },
      {
        'title': _pageTitles[2],
        'icon': Icons.calendar_today,
        'page': const MyAppointmentsScreen()
      },
      {
        'title': _pageTitles[3],
        'icon': Icons.event_note_rounded,
        'page': const AppointmentsReminderScreen(),
      },
      {
        'title': _pageTitles[4],
        'icon': Icons.chat,
        'page': const MessagesPage()
      },
      {
        'title': _pageTitles[5],
        'icon': Icons.person,
        'page': const UserProfilePage()
      },
      {
        'title': _pageTitles[6],
        'icon': Icons.settings,
        'page': const UserSettingsPage()
      },
      {
        'title': _pageTitles[7],
        'icon': Icons.support_agent,
        'page': const SupportScreen()
      },
      {
        'title': _pageTitles[8],
        'icon': Icons.notifications_active,
        'page': const MyAlertsScreen()
      },
      {
        'title': _pageTitles[9],
        'icon': Icons.logout_rounded,
        'isLogout': true,
      },
    ];
  }

  // _shortcutCard has been removed as it was unused.

  Widget _buildHeader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
              ? NetworkImage(_profileImageUrl!)
              : null,
          backgroundColor: Colors.white.withValues(alpha: 0.3),
          child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
              ? const Icon(Icons.person, size: 32, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 12),
        Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(_phone.isNotEmpty ? _phone : _userEmail, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cerrando sesión en 3 segundos...'),
          duration: Duration(seconds: 3),
        ),
      );

      await Future.delayed(const Duration(seconds: 3));

      await _auth.signOut();
      await _googleSignIn.signOut();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
      }
    }
  }

  void _onItemTapped(int index) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth >= 600;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(_pageTitles[_selectedIndex]),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            actions: isLargeScreen
                ? [
                    IconButton(
                      icon: const Icon(Icons.logout_rounded),
                      tooltip: 'Cerrar sesión',
                      onPressed: _logout,
                    ),
                  ]
                : null,
          ),
          drawer: isLargeScreen ? null : _buildDrawer(),
          body: Row(
            children: [
              if (isLargeScreen) _buildSideBar(),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _sections
                      .where((s) => s['isLogout'] != true)
                      .map<Widget>((s) => s['page'])
                      .toList(),
                ),
              ),
            ],
          ),
          floatingActionButton: null,
        );
      },
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
          destinations: _sections
              .where((s) => s['isLogout'] != true)
              .map<NavigationRailDestination>((section) {
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
                final selected =
                    _selectedIndex == index && section['isLogout'] != true;

                if (section['isLogout'] == true) {
                  return Column(
                    children: [
                      const Divider(),
                      ListTile(
                        leading: Icon(section['icon'], color: Colors.red),
                        title: Text(
                          section['title'],
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        onTap: _logout,
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
                          style: TextStyle(
                              color: selected ? colorScheme.primary : null,
                              fontWeight: selected ? FontWeight.bold : null),
                        ),
                        selected: selected,
                        onTap: () {
                          _onItemTapped(index);
                        },
                      );
                    }
                  );
                }
                else {
                  return ListTile(
                    leading: Icon(section['icon'],
                        color: selected ? colorScheme.primary : null),
                    title: Text(
                      section['title'],
                      style: TextStyle(
                          color: selected ? colorScheme.primary : null,
                          fontWeight: selected ? FontWeight.bold : null),
                    ),
                    selected: selected,
                    onTap: () {
                      _onItemTapped(index);
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
}