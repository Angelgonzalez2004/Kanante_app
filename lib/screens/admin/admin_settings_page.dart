import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../main.dart'; // Para themeNotifier
import '../login_screen.dart';
import '../../theme/app_colors.dart'; // Added missing import

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  bool _darkMode = false;
  bool _notifications = true;
  bool _isLoading = true; // Use this for loading preferences initially

  void _showSnackBar(String message, {Color color = Colors.teal}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _darkMode = prefs.getBool('darkMode') ?? false;
        _notifications = prefs.getBool('notifications') ?? true;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, salir')),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      await _googleSignIn.signOut();
      
      _showSnackBar('¡Hasta luego! 👋', color: Colors.green);
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }
  
  Future<void> _deleteAccount() async {
     final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text('Esta acción es irreversible. ¿Estás seguro de que quieres eliminar tu cuenta permanentemente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _googleSignIn.signOut();
        await _auth.currentUser?.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuenta eliminada con éxito.')),
          );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      } on FirebaseAuthException catch (e) {
         if (mounted) {
          String message = "Ocurrió un error.";
          if (e.code == 'requires-recent-login') {
            message = 'Esta operación requiere que hayas iniciado sesión recientemente. Por favor, cierra sesión y vuelve a entrar.';
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }

  Future<void> _toggleTheme(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _darkMode = value);
    }
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    await prefs.setBool('darkMode', value);
    _showSnackBar(value ? 'Modo oscuro activado' : 'Modo claro activado',
        color: Colors.green);
  }

  Future<void> _toggleNotifications(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _notifications = value);
    }
    await prefs.setBool('notifications', value);
    _showSnackBar(
        value ? 'Notificaciones activadas' : 'Notificaciones desactivadas',
        color: Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes de Administrador'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _isLoading
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
                            'Ajustes de la Aplicación',
                            style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.055,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _darkMode,
                            activeTrackColor: AppColors.primary.withAlpha((255 * 0.5).round()),
                            activeThumbColor: AppColors.primary,
                            title: const Text('Modo oscuro'),
                            onChanged: _toggleTheme,
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _notifications,
                            activeTrackColor: AppColors.primary.withAlpha((255 * 0.5).round()),
                            activeThumbColor: AppColors.primary,
                            title: const Text('Notificaciones'),
                            onChanged: _toggleNotifications,
                          ),
                          Divider(height: MediaQuery.of(context).size.height * 0.04),
                          Center(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withAlpha((255 * 0.1).round()),
                                foregroundColor: Colors.redAccent,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Colors.redAccent)),
                              ),
                              onPressed: _logout,
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Cerrar Sesión', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                           Center(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _deleteAccount,
                              icon: const Icon(Icons.delete_forever),
                              label: const Text('Eliminar Cuenta', style: TextStyle(fontSize: 16)),
                            ),
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
