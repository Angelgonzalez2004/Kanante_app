import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:kanante_app/models/user_model.dart';
import '../../theme/app_colors.dart'; // Assuming AppColors is defined

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _adminUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  Future<void> _loadAdminProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final userModel = await _firebaseService.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _adminUser = userModel;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar perfil: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Material( // Added Material widget
      type: MaterialType.transparency, // Use transparency to avoid visual changes
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 40 : 24, vertical: 32),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información del Administrador',
                            style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.055,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                          ListTile(
                            leading: const Icon(Icons.person_rounded),
                            title: Text(_adminUser?.name ?? 'Administrador'),
                            subtitle: const Text('Nombre'),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.email_rounded),
                            title: Text(_adminUser?.email ?? 'N/A'),
                            subtitle: const Text('Correo Electrónico'),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.admin_panel_settings_rounded),
                            title: const Text('Rol'),
                            subtitle: Text(_adminUser?.accountType ?? 'Admin'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
