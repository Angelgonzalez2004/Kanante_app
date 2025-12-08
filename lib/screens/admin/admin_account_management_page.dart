import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kanante_app/models/user_model.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:kanante_app/screens/professional/profile_page.dart'; // Reusing for viewing other profiles
import 'package:kanante_app/screens/admin/send_alert_screen.dart'; // New screen for sending alerts

class AdminAccountManagementPage extends StatefulWidget {
  const AdminAccountManagementPage({super.key});

  @override
  State<AdminAccountManagementPage> createState() => _AdminAccountManagementPageState();
}

class _AdminAccountManagementPageState extends State<AdminAccountManagementPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<UserModel> _allUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  Future<void> _loadAllUsers() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all users including admins, then filter them out if needed for management view.
      // Or if getAllUsers already filters based on current logic, use that.
      // For now, let's assume getAllUsers fetches everyone for admin management.
      final users = await _firebaseService.getAllUsers();
      if (mounted) {
        setState(() {
          // Filter out the current admin user if present and not managing themselves
          _allUsers = users.where((user) => user.id != _auth.currentUser!.uid).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<UserModel> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _allUsers;
    }
    return _allUsers.where((user) {
      return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             user.accountType.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _confirmDeleteUser(UserModel user) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: Text('¿Estás seguro de que quieres eliminar la cuenta de ${user.name} (${user.accountType})? Esta acción eliminará sus datos de la base de datos, pero no su registro de autenticación.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firebaseService.deleteUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Los datos de ${user.name} han sido eliminados.')),
          );
          _loadAllUsers(); // Reload to reflect changes
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _sendAlertToUser(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SendAlertScreen(recipientUser: user),
      ),
    ).then((_) => _loadAllUsers()); // Refresh data after sending alert
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Cuentas'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterUsers,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre, email o tipo de cuenta',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(child: Text(_searchQuery.isEmpty ? 'No hay usuarios registrados.' : 'No se encontraron usuarios.'))
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundImage: user.profileImageUrl != null
                                    ? NetworkImage(user.profileImageUrl!)
                                    : null,
                                child: user.profileImageUrl == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text('${user.name} (${user.accountType})'),
                              subtitle: Text(user.email),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Teléfono: ${user.phone ?? 'N/A'}'),
                                      Text('Género: ${user.gender ?? 'N/A'}'),
                                      // Add more details here as needed
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Flexible(
                                            child: TextButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ProfessionalProfilePage(professionalUid: user.id),
                                                  ),
                                                );
                                              },
                                              child: const Text('Ver Perfil Completo'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: ElevatedButton(
                                              onPressed: () => _sendAlertToUser(user),
                                              child: const Text('Enviar Alerta'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: ElevatedButton(
                                              onPressed: () => _confirmDeleteUser(user),
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              child: const Text('Eliminar'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}