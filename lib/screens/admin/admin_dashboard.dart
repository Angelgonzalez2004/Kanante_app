import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kanante_app/data/faq_data.dart';
// import 'package:google_sign_in/google_sign_in.dart'; // Unused, commented out

import 'verifications_page.dart';
import 'support_center_screen.dart';
import '../shared/faq_screen.dart';
import 'admin_profile_page.dart';
import 'admin_settings_page.dart';
import 'admin_messages_page.dart';
import 'admin_account_management_page.dart';
import 'admin_analytics_screen.dart';
import '../shared/publication_feed_page.dart';
import 'admin_home_page.dart';
//import 'package:kanante_app/services/firebase_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn(); // Removed GoogleSignIn as it was unused in logic

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  // final FirebaseService _firebaseService = FirebaseService(); // Marked unused in analysis, keeping commented if you need later
  
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  int _selectedIndex = 0;

  late final List<Widget> _pages;
  final List<String> _pageTitles = const [
    'Inicio',
    'Verificar Profesionales',
    'Supervisar Publicaciones',
    'Centro de Soporte',
    'Preguntas Frecuentes',
    'Mensajes',
    'Mi Perfil (Admin)',
    'Configuración (Admin)',
    'Gestionar Cuentas',
    'Análisis y Reportes',
  ];

  @override
  void initState() {
    super.initState();
    _pages = const [
      AdminHomePage(),
      VerificationsPage(),
      PublicationFeedPage(),
      SupportCenterScreen(),
      FaqScreen(faqData: FaqData.forAdmin),
      AdminMessagesPage(),
      AdminProfilePage(),
      AdminSettingsPage(),
      AdminAccountManagementPage(),
      AdminAnalyticsScreen(),
    ];
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final snapshot = await _db.child('users/${user.uid}').get();
      if (snapshot.exists && mounted) {
        setState(() {
          _userData = Map<String, dynamic>.from(snapshot.value as Map);
        });
      }
    } catch (e) {
      debugPrint('Error loading admin user data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
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
      // await _googleSignIn.signOut();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
      }
    }
  }

  Widget _buildHeader() {
    final name = _userData?['name'] ?? 'Admin';
    final email = _userData?['email'] ?? '';
    final role = _userData?['accountType'] ?? 'Administrador';
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 32,
          backgroundColor: Colors.white,
          child: Icon(Icons.admin_panel_settings, size: 32, color: Colors.indigo),
        ),
        const SizedBox(height: 8),
        Text(name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(email,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Chip(
          label: Text(role,
              style: TextStyle(
                  color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
          backgroundColor: colorScheme.primary.withOpacity(0.7),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          side: BorderSide.none,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_pageTitles[_selectedIndex]),
              backgroundColor: Colors.indigo,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _signOut,
                  tooltip: 'Cerrar Sesión',
                ),
              ],
            ),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  leading: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 20),
                      const Divider(),
                    ],
                  ),
                  destinations: <NavigationRailDestination>[
                    NavigationRailDestination(
                      icon: const Icon(Icons.home_filled),
                      label: Text(_pageTitles[0]),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.verified_user_outlined),
                      label: Text(_pageTitles[1]),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.article_outlined),
                      label: Text(_pageTitles[2]),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.support_agent),
                      label: Text(_pageTitles[3]),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.question_answer_outlined),
                      label: Text(_pageTitles[4]),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.message_outlined),
                      label: Text(_pageTitles[5]),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.person_outline),
                      label: Text(_pageTitles[6]),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(_pageTitles[7]),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.people),
                      label: Text(_pageTitles[8]),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.analytics),
                      label: Text(_pageTitles[9]),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text(_pageTitles[_selectedIndex]),
              backgroundColor: Colors.indigo,
            ),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: _buildHeader(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home_filled),
                    title: Text(_pageTitles[0]),
                    selected: _selectedIndex == 0,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: Text(_pageTitles[1]),
                    selected: _selectedIndex == 1,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: Text(_pageTitles[2]),
                    selected: _selectedIndex == 2,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.support_agent),
                    title: Text(_pageTitles[3]),
                    selected: _selectedIndex == 3,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.question_answer_outlined),
                    title: Text(_pageTitles[4]),
                    selected: _selectedIndex == 4,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 4;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.message_outlined),
                    title: Text(_pageTitles[5]),
                    selected: _selectedIndex == 5,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 5;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(_pageTitles[6]),
                    selected: _selectedIndex == 6,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 6;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: Text(_pageTitles[7]),
                    selected: _selectedIndex == 7,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 7;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: Text(_pageTitles[8]),
                    selected: _selectedIndex == 8,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 8;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.analytics),
                    title: Text(_pageTitles[9]),
                    selected: _selectedIndex == 9,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 9;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Cerrar Sesión'),
                    onTap: _signOut,
                  ),
                ],
              ),
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          );
        }
      },
    );
  }
}