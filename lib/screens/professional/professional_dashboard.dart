import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../shared/home_page.dart';
import '../shared/publication_feed_page.dart';
import 'patients_page.dart';
import 'appointments_page.dart';
import 'messages_page.dart';
import 'publications_page.dart';
import 'settings_page.dart';
import 'profile_page.dart'; // New import

class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});

  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

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
          shortcutButtons: _buildProfessionalShortcuts(),
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
        'title': 'Ajustes',
        'icon': Icons.settings_rounded,
        'page': const SettingsPage()
      },
      {
        'title': 'Mi Perfil',
        'icon': Icons.person_rounded,
        'page': const ProfessionalProfilePage()
      },
      {
        'title': 'Cerrar SesiÃ³n',
        'icon': Icons.logout_rounded,
        'isLogout': true, // Special flag for logout
      },
    ];
  }

  List<Widget> _buildProfessionalShortcuts() {
    return [
      _shortcutCard('Pacientes', Icons.people_alt_rounded, () => _onItemTapped(2)),
      _shortcutCard('Citas', Icons.calendar_month_rounded, () => _onItemTapped(3)),
      _shortcutCard('Mensajes', Icons.message_rounded, () => _onItemTapped(4)),
      _shortcutCard('Publicaciones', Icons.article_rounded, () => _onItemTapped(5)),
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
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if(Navigator.canPop(context)) Navigator.pop(context);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Cierre de SesiÃ³n'),
        content: const Text('Â¿EstÃ¡s seguro de que deseas cerrar la sesiÃ³n?'),
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
            child: const Text('SÃ­, Salir'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesiÃ³n',
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
                  .where((s) => s['isLogout'] != true) // Filter out logout section
                  .map<Widget>((s) => s['page'])
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideBar() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      labelType: NavigationRailLabelType.all,
      leading: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 40,
            backgroundImage: (_userData?['profileImageUrl'] != null && _userData!['profileImageUrl'].isNotEmpty)
                ? NetworkImage(_userData!['profileImageUrl'])
                : null,
            child: (_userData?['profileImageUrl'] == null || _userData!['profileImageUrl'].isEmpty)
                ? const Icon(Icons.psychology_alt_rounded, size: 40)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            _userData?['name'] ?? 'Profesional',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Divider(),
        ],
      ),
      destinations: _sections.map<NavigationRailDestination>((section) {
        return NavigationRailDestination(
          icon: Icon(section['icon']),
          label: Text(section['title']),
        );
      }).toList(),
    );
  }

  Widget _buildDrawer() {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_userData?['name'] ?? 'Profesional'),
            accountEmail: Text(_userData?['email'] ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundImage: (_userData?['profileImageUrl'] != null && _userData!['profileImageUrl'].isNotEmpty)
                  ? NetworkImage(_userData!['profileImageUrl'])
                  : null,
              child: (_userData?['profileImageUrl'] == null || _userData!['profileImageUrl'].isEmpty)
                  ? const Icon(Icons.psychology_alt_rounded, size: 40)
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
                final selected = _selectedIndex == index;

                if (section['isLogout'] == true) {
                  return Column(
                    children: [
                      const Divider(),
                      ListTile(
                        leading: Icon(section['icon'], color: selected ? colorScheme.primary : null),
                        title: Text(
                          section['title'],
                          style: TextStyle(color: selected ? colorScheme.primary : null, fontWeight: selected ? FontWeight.bold : null),
                        ),
                        onTap: _logout, // Call _logout directly
                      ),
                    ],
                  );
                } else {
                  return ListTile(
                    leading: Icon(section['icon'], color: selected ? colorScheme.primary : null),
                    title: Text(
                      section['title'],
                      style: TextStyle(color: selected ? colorScheme.primary : null, fontWeight: selected ? FontWeight.bold : null),
                    ),
                    onTap: () => _onItemTapped(index),
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
