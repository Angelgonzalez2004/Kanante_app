// lib/screens/admin/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'verifications_page.dart';
import 'support_center_screen.dart';
import '../shared/faq_screen.dart'; 
import 'package:kanante_app/data/faq_data.dart';

import 'admin_profile_page.dart';
import 'admin_settings_page.dart';
import 'admin_messages_page.dart';
import 'admin_account_management_page.dart';
import 'admin_analytics_screen.dart';
import '../shared/publication_feed_page.dart';
import 'admin_home_page.dart'; // Import for AdminHomePage

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  int _selectedIndex = 0;

  late final List<Widget> _pages;
  final List<String> _pageTitles = const [
    'Inicio', // New 'Inicio' page
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
        AdminHomePage(), // New 'Inicio' page
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
      await _googleSignIn.signOut();

      // Navigate to Login screen and remove all previous routes
      // Note: This conflicts with the AuthWrapper pattern, but is implemented as requested.
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                    destinations: <NavigationRailDestination>[
                                      // New 'Inicio' destination
                                      NavigationRailDestination(
                                        icon: Icon(Icons.home_filled),
                                        label: Text(_pageTitles[0]),
                                      ),
                                      NavigationRailDestination(
                                        icon: Icon(Icons.verified_user_outlined),
                                        label: Text(_pageTitles[1]),
                                      ),
                                      NavigationRailDestination(
                                        icon: Icon(Icons.article_outlined),
                                        label: Text(_pageTitles[2]),
                                      ),
                                      NavigationRailDestination(
                                        icon: Icon(Icons.support_agent),
                                        label: Text(_pageTitles[3]),
                                      ),
                                      NavigationRailDestination(
                                        icon: Icon(Icons.question_answer_outlined),
                                        label: Text(_pageTitles[4]),
                                      ),
                                      NavigationRailDestination(
                                        icon: Icon(Icons.message_outlined),
                                        label: Text(_pageTitles[5]),
                                      ),
                                      NavigationRailDestination(
                                        icon: Icon(Icons.person_outline),
                                        label: Text(_pageTitles[6]),
                                      ),
                                      NavigationRailDestination(
                                        icon: Icon(Icons.settings_outlined),
                                        label: Text(_pageTitles[7]),
                                      ),
                                      NavigationRailDestination(
                                        icon: Icon(Icons.people),
                                        label: Text(_pageTitles[8]),
                                      ),
                                      NavigationRailDestination(
                                        icon: Icon(Icons.analytics),
                                        label: Text(_pageTitles[9]),
                                      ),
                                    ],                ),
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
                    decoration: const BoxDecoration( // --- CORRECCIÓN: const
                      color: Colors.indigo,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Image.asset(
                          'assets/images/logoapp.jpg', 
                          height: 60, 
                        ),
                        const SizedBox(height: 8),
                        const Text( // --- CORRECCIÓN: const
                          'Menú de Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
                                      selected: _selectedIndex == 9, // Updated index
                                      onTap: () {
                                        setState(() {
                                          _selectedIndex = 9; // Updated index
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                    const Divider(),
                                    ListTile(
                                      leading: const Icon(Icons.logout),
                                      title: const Text('Cerrar Sesión'),
                                      onTap: _signOut,
                                    ),                ],
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