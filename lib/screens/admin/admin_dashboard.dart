import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../login_screen.dart';
import 'verifications_page.dart';
import 'support_center_screen.dart';
import '../shared/faq_screen.dart'; // Ensure FaqScreen is imported from shared
import 'package:kanante_app/data/faq_data.dart';
import 'admin_publication_list.dart'; // Correct import for publication list
import 'admin_profile_page.dart'; // New import
import 'admin_settings_page.dart'; // New import

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
  late final List<String> _pageTitles;

  @override
  void initState() {
    super.initState();
    _pages = [
      const VerificationsPage(),
      const AdminPublicationList(), // Use AdminPublicationListPage
      const SupportCenterScreen(),
      const FaqScreen(faqData: FaqData.forAdmin),
      const AdminProfilePage(), // Placeholder - Admin Profile Page
      const AdminSettingsPage(), // Placeholder - Admin Settings Page
      const Center(child: Text('Gestionar Cuentas (TODO)')), // Placeholder, was index 4
    ];
    _pageTitles = [
      'Verificar Profesionales',
      'Supervisar Publicaciones',
      'Centro de Soporte',
      'Preguntas Frecuentes',
      'Mi Perfil (Admin)', // New title
      'Configuración (Admin)', // New title
      'Gestionar Cuentas', // Shifted index
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
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.verified_user_outlined),
                      label: Text(_pageTitles[0]),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.article_outlined),
                      label: Text(_pageTitles[1]),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.support_agent),
                      label: Text(_pageTitles[2]),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.question_answer_outlined),
                      label: Text(_pageTitles[3]),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.people),
                      label: Text(_pageTitles[4]),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.person_outline),
                      label: Text(_pageTitles[5]),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(_pageTitles[6]),
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
                  const DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                    ),
                    child: Text(
                      'Menú de Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
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
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: Text(_pageTitles[4]),
                    selected: _selectedIndex == 4,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 4;
                      });
                      Navigator.pop(context); // Close the drawer
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(_pageTitles[5]),
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
                    title: Text(_pageTitles[6]),
                    selected: _selectedIndex == 6,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 6;
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
