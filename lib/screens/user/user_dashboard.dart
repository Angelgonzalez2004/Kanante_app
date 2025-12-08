import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kanante_app/models/alert_model.dart';
import 'package:kanante_app/services/firebase_service.dart';
import '../login_screen.dart';
import '../shared/home_page.dart';
import '../shared/publication_feed_page.dart'; // New import for interactive feed
import 'user_profile_page.dart'; // Added new UserProfilePage
import 'user_settings_page.dart'; // Added new UserSettingsPage
import 'professional_content_screen.dart';
import 'my_appointments_screen.dart';
import '../shared/support_screen.dart';
import 'messages_page.dart'; // Changed import
import '../shared/my_alerts_screen.dart'; // New import


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
  String _phone = ''; // Added phone number
  String? _profileImageUrl; // Add for profile image
  int _selectedIndex = 1; // Changed from 0 to 1 to default to 'Feed de Contenido'

  late final List<Map<String, dynamic>> _sections; // Made late final
  late final List<String> _pageTitles; // Added _pageTitles list
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _pageTitles = [
      // Initialize _pageTitles here
      'Inicio',
      'Feed de Contenido',
      'Mis Citas',
      'Mensajes',
      'Mi Perfil', // Renamed from Ajustes
      'Configuración', // New entry
      'Soporte',
      'Mis Alertas', // New entry
      'Cerrar Sesión' // Added logout title for consistency
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
            _phone = data['phone'] ?? ''; // Load phone number
            _profileImageUrl = data['profileImageUrl']; // Get profile image
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
        'title': _pageTitles[0], // Use pageTitles
        'icon': Icons.home,
        'page': HomePage(
          userName: _userName,
          shortcutButtons: _buildUserShortcuts(),
        )
      },
      {
        'title': _pageTitles[1], // Use pageTitles
        'icon': Icons.explore,
        'page': const PublicationFeedPage() // Changed to PublicationFeedPage
      },
      {
        'title': _pageTitles[2], // Use pageTitles
        'icon': Icons.calendar_today,
        'page': const MyAppointmentsScreen()
      },
      {
        'title': _pageTitles[3], // Use pageTitles
        'icon': Icons.chat,
        'page': const MessagesPage()
      },
      {
        'title': _pageTitles[4], // Use pageTitles - Mi Perfil
        'icon': Icons.person,
        'page': const UserProfilePage()
      },
      {
        'title': _pageTitles[5], // Use pageTitles - Configuración
        'icon': Icons.settings,
        'page': const UserSettingsPage()
      },
      {
        // REMOVED THE 'n' HERE
        'title': _pageTitles[6], // Use pageTitles - Soporte
        'icon': Icons.support_agent,
        'page': const SupportScreen()
      },
      {
        'title': _pageTitles[7], // Use pageTitles - Mis Alertas
        'icon': Icons.notifications_active,
        'page': const MyAlertsScreen()
      },
      {
        'title': _pageTitles[8], // Use pageTitles - Cerrar Sesión
        'icon': Icons.logout_rounded,
        'isLogout': true, // Added isLogout flag
      },
    ];
  }

  List<Widget> _buildUserShortcuts() {
    // Tapping these cards will now correctly navigate using the index from the _sections list.
    return [
      _shortcutCard(
          'Feed de Contenido', Icons.explore, () => _onItemTapped(1)),
      _shortcutCard('Mensajes', Icons.chat, () => _onItemTapped(3)),
      _shortcutCard('Mis Citas', Icons.calendar_today, () => _onItemTapped(2)),
      _shortcutCard('Mi Perfil', Icons.person,
          () => _onItemTapped(4)), // Link to new profile page
      _shortcutCard('Mis Alertas', Icons.notifications_active, () => _onItemTapped(7)), // New shortcut
    ];
  }

  Widget _shortcutCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.teal),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
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
      await _auth.signOut();
      await _googleSignIn.signOut();
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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
    // For narrow screens, close the drawer after selection
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
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            actions: isLargeScreen
                ? [
                    IconButton(
                      icon: const Icon(Icons.logout_rounded),
                      tooltip: 'Cerrar sesión',
                      onPressed: _logout,
                    ),
                  ]
                : null, // No actions for narrow screens, logout is in drawer
          ),
          drawer: isLargeScreen
              ? null
              : _buildDrawer(context), // Only show drawer on narrow screens
          body: Row(
            children: [
              if (isLargeScreen)
                _buildSideBar(context), // Show sidebar on large screens
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _sections
                      .where((s) =>
                          s['isLogout'] != true) // Filter out logout for page stack
                      .map<Widget>((s) => s['page'])
                      .toList(),
                ),
              ),
            ],
          ),
          floatingActionButton: null, // No FAB for any page now that MessagesPage handles its own chat initiation
        );
      },
    );
  }

  Widget _buildSideBar(BuildContext context) {
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
              CircleAvatar(
                radius: 40,
                backgroundImage:
                    (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                _userName,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              // CORRECCIÓN: Usar _phone aquí
              if (_phone.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    _phone,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
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

  Widget _buildDrawer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_userName),
            // CORRECCIÓN: Usar _phone aquí combinado con el email
            accountEmail: Text(_phone.isNotEmpty ? '$_userEmail\n$_phone' : _userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundImage:
                  (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                      ? NetworkImage(_profileImageUrl!)
                      : null,
              child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary,
            ),
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