import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../main.dart'; // Para themeNotifier
import '../login_screen.dart';

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({super.key});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  bool _darkMode = false;
  bool _notifications = true;
  
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
      });
    }
  }

  Future<void> _changePassword() async {
    final TextEditingController newPassword = TextEditingController();

    String? snackBarMessage;
    Color snackBarColor = Colors.red;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: TextField(
          controller: newPassword,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Nueva contraseña',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _auth.currentUser?.updatePassword(newPassword.text);
                snackBarMessage = 'Contraseña actualizada correctamente';
                snackBarColor = Colors.green;
                
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              } catch (e) {
                snackBarMessage = 'Error: ${e.toString()}';
                snackBarColor = Colors.red;
                
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (snackBarMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snackBarMessage!), backgroundColor: snackBarColor),
      );
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
    return Material( // Added Material widget
      type: MaterialType.transparency, // Use transparency to avoid visual changes
      child: Center( // Removed Scaffold and AppBar
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800), // Smaller max width
                          child: ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.lock_rounded, color: Colors.teal),
                                title: const Text('Cambiar contraseña'),
                                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                                onTap: _changePassword,
                              ),                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _darkMode,
                      activeTrackColor: Colors.teal.withAlpha((255 * 0.5).round()),
                      activeThumbColor: Colors.teal,
                      title: const Text('Modo oscuro'),
                      onChanged: _toggleTheme,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _notifications,
                      activeTrackColor: Colors.teal.withAlpha((255 * 0.5).round()),
                      activeThumbColor: Colors.teal,
                      title: const Text('Notificaciones'),
                      onChanged: _toggleNotifications,
                    ),
                    Divider(height: MediaQuery.of(context).size.height * 0.04),
                    Text(
                      'Privacidad',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.teal),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ver política de privacidad'),
                      leading: const Icon(Icons.policy),
                      onTap: () {
                        _showSnackBar('Navegar a la política de privacidad.');
                        // TODO: Implement navigation to privacy policy page
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Gestionar preferencias de datos'),
                      leading: const Icon(Icons.data_usage),
                      onTap: () {
                        _showSnackBar('Navegar a la gestión de preferencias de datos.');
                        // TODO: Implement navigation to data preferences management
                      },
                    ),
                    Divider(height: MediaQuery.of(context).size.height * 0.04),
                    Text(
                      'Seguridad',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.teal),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Cambiar contraseña'),
                      leading: const Icon(Icons.lock_reset),
                      onTap: _changePassword, // Reuse existing _changePassword method
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Configuración de autenticación de dos factores'),
                      leading: const Icon(Icons.security),
                      onTap: () {
                        _showSnackBar('Navegar a la configuración de 2FA.');
                        // TODO: Implement navigation to 2FA settings
                      },
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
    );
  }
}