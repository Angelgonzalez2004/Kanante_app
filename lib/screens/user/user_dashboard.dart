import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../login_screen.dart';
import '../shared/home_page.dart';
import 'user_settings_page.dart';
import 'professional_content_screen.dart';
import 'my_appointments_screen.dart';
import 'messages_page.dart'; // Changed import

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  String _userName = 'Usuario';
  String _userEmail = '';
  int _selectedIndex = 0;

  List<Map<String, dynamic>> _sections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
        'title': 'Inicio',
        'icon': Icons.home,
        'page': HomePage(
          userName: _userName,
          shortcutButtons: _buildUserShortcuts(),
        )
      },
      {
        'title': 'Feed de Contenido',
        'icon': Icons.explore,
        'page': const ProfessionalContentScreen()
      },
      {
        'title': 'Mis Citas',
        'icon': Icons.calendar_today,
        'page': const MyAppointmentsScreen()
      },
      {
        'title': 'Mensajes', // Changed title
        'icon': Icons.chat, // Icon can remain the same
        'page': const MessagesPage() // Changed page
      },
      {
        'title': 'Ajustes',
        'icon': Icons.settings,
        'page': const UserSettingsPage()
      },
    ];
  }

  List<Widget> _buildUserShortcuts() {
    // Tapping these cards will now correctly navigate using the index from the _sections list.
    return [
      _shortcutCard('Feed de Contenido', Icons.explore, () => _onItemTapped(1)),
      _shortcutCard('Mensajes', Icons.chat, () => _onItemTapped(3)), // Changed title and potentially action
      _shortcutCard('Mis Citas', Icons.calendar_today, () => _onItemTapped(2)),
      _shortcutCard('Ajustes', Icons.settings, () => _onItemTapped(4)),
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

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (Navigator.canPop(context)) Navigator.pop(context); // Close drawer
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_sections[_selectedIndex]['title']!),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(_userName),
              accountEmail: Text(_userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.1, color: Colors.teal),
                ),
              ),
              decoration: const BoxDecoration(
                color: Colors.teal,
              ),
            ),
            for (int i = 0; i < _sections.length; i++)
              ListTile(
                leading: Icon(_sections[i]['icon']!),
                title: Text(_sections[i]['title']!),
                selected: _selectedIndex == i,
                onTap: () => _onItemTapped(i),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar SesiÃ³n'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _sections.map<Widget>((s) => s['page']).toList(),
      ),
    );
  }
}
