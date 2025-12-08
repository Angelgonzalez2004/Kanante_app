import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../login_screen.dart';
import 'verifications_page.dart';
import 'support_center_screen.dart';
import '../shared/faq_screen.dart'; // Ensure FaqScreen is imported from shared
import 'package:kanante_app/data/faq_data.dart';

import 'admin_profile_page.dart'; // New import
import 'admin_settings_page.dart'; // New import
import 'admin_messages_page.dart'; // New import
import 'admin_account_management_page.dart'; // New import
import '../shared/publication_feed_page.dart'; // New import for interactive feed

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  int _selectedIndex = 0; // To track the selected navigation item

  // List of pages to display in the body
  late final List<Widget> _pages;
  final List<String> _pageTitles = const [
    'Verificar Profesionales',
    'Supervisar Publicaciones',
    'Centro de Soporte',
    'Preguntas Frecuentes',
    'Mensajes',
    'Mi Perfil (Admin)',
    'Configuración (Admin)',
    'Gestionar Cuentas',
  ];

  @override
  void initState() {
    super.initState();
    _pages = const [
      VerificationsPage(),
      PublicationFeedPage(), // Changed to PublicationFeedPage
      SupportCenterScreen(),
      FaqScreen(faqData: FaqData.forAdmin),
      AdminMessagesPage(), // New Admin Messages Page
      AdminProfilePage(), // Placeholder - Admin Profile Page
      AdminSettingsPage(), // Placeholder - Admin Settings Page
      AdminAccountManagementPage(), // Replace placeholder with actual page
    ];
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Handle potential errors, e.g., show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) { // Wide screen layout (desktop/tablet)
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
                  destinations: const <NavigationRailDestination>[
                    NavigationRailDestination(
                      icon: Icon(Icons.verified_user_outlined),
                      label: Text('Verificar Profesionales'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.article_outlined),
                      label: Text('Supervisar Publicaciones'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.support_agent),
                      label: Text('Centro de Soporte'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.question_answer_outlined),
                      label: Text('Preguntas Frecuentes'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.message_outlined),
                      label: Text('Mensajes'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      label: Text('Mi Perfil (Admin)'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      label: Text('Configuración (Admin)'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people),
                      label: Text('Gestionar Cuentas'),
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
        } else { // Narrow screen layout (mobile)
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
                      color: Colors.indigo,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Image.asset(
                          'assets/images/logoapp.jpg', // Path to your app logo
                          height: 60, // Adjust height as needed
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Menú de Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18, // Slightly reduced font size for better fit
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: Text(_pageTitles[0]),
                    selected: _selectedIndex == 0,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                      Navigator.pop(context); // Close the drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: Text(_pageTitles[1]),
                    selected: _selectedIndex == 1,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                      Navigator.pop(context); // Close the drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.support_agent),
                    title: Text(_pageTitles[2]),
                    selected: _selectedIndex == 2,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                      Navigator.pop(context); // Close the drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.question_answer_outlined),
                    title: Text(_pageTitles[3]),
                    selected: _selectedIndex == 3,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                      Navigator.pop(context); // Close the drawer
                    },
                  ),
                  const Divider(), // New Divider
                  ListTile(
                    leading: const Icon(Icons.message_outlined), // New Icon
                    title: Text(_pageTitles[4]), // Corresponds to 'Mensajes'
                    selected: _selectedIndex == 4,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 4;
                      });
                      Navigator.pop(context); // Close the drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(_pageTitles[5]), // Corresponds to 'Mi Perfil (Admin)'
                    selected: _selectedIndex == 5,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 5;
                      });
                      Navigator.pop(context); // Close the drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: Text(_pageTitles[6]), // Corresponds to 'Configuración (Admin)'
                    selected: _selectedIndex == 6,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 6;
                      });
                      Navigator.pop(context); // Close the drawer
                    },
                  ),
                  const Divider(), // Shifted
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: Text(_pageTitles[7]), // Corresponds to 'Gestionar Cuentas'
                    selected: _selectedIndex == 7,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 7;
                      });
                      Navigator.pop(context); // Close the drawer
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
