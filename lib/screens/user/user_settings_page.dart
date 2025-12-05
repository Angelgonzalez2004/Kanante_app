import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart'; // Para themeNotifier
import '../login_screen.dart';

class UserSettingsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const UserSettingsPage({super.key, this.userData});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  bool _darkMode = false;
  bool _notifications = true;

  String _name = '';
  String _phone = '';
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();

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
    if (widget.userData != null) {
      _name = widget.userData!['name'] ?? '';
      _phone = widget.userData!['phone'] ?? '';
      _isLoading = false;
    } else {
      _loadUserData();
    }
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('darkMode') ?? false;
    _notifications = prefs.getBool('notifications') ?? true;
    if (mounted) setState(() {});
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _dbRef.child('users/${user.uid}').get();
    if (snapshot.exists && mounted) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _name = data['name'] ?? '';
        _phone = data['phone'] ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    await _dbRef.child('users/${user.uid}').update({
      'name': _name,
      'phone': _phone,
    });

    _showSnackBar('Datos actualizados con éxito', color: Colors.green);
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
                
                // CORRECCIÓN: Verificar si el diálogo sigue montado antes de cerrarlo
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              } catch (e) {
                snackBarMessage = 'Error: ${e.toString()}';
                snackBarColor = Colors.red;
                
                // CORRECCIÓN: Verificar si el diálogo sigue montado antes de cerrarlo
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
      final name = _name.isNotEmpty ? _name : 'Usuario';
      await _auth.signOut();
      
      // La función _showSnackBar ya verifica 'mounted', así que es seguro llamarla aquí.
      _showSnackBar('¡Hasta luego, $name! 👋', color: Colors.green);
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _toggleTheme(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _darkMode = value);
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    await prefs.setBool('darkMode', value);
    _showSnackBar(value ? 'Modo oscuro activado' : 'Modo claro activado',
        color: Colors.green);
  }

  Future<void> _toggleNotifications(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _notifications = value);
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
        title: const Text('Ajustes de Usuario'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 40 : 24, vertical: 32),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: isWide
                            ? _buildWideLayout()
                            : _buildNarrowLayout(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileSection(),
        Divider(height: MediaQuery.of(context).size.height * 0.05),
        _buildAppSettingsSection(),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildProfileSection(),
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.03),
        const VerticalDivider(width: 24),
        Expanded(
          flex: 2,
          child: _buildAppSettingsSection(),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    final size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mi Perfil',
          style: TextStyle(
              fontSize: size.width * 0.055,
              fontWeight: FontWeight.bold,
              color: Colors.teal),
        ),
        SizedBox(height: size.height * 0.02),
        TextFormField(
          initialValue: _name,
          decoration: const InputDecoration(
            labelText: 'Nombre completo',
            prefixIcon: Icon(Icons.person_rounded),
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => _name = v,
          validator: (v) => v!.isEmpty ? 'Ingrese su nombre' : null,
        ),
        SizedBox(height: size.height * 0.02),
        TextFormField(
          initialValue: _phone,
          decoration: const InputDecoration(
            labelText: 'Teléfono',
            prefixIcon: Icon(Icons.phone_rounded),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (v) => _phone = v,
        ),
        SizedBox(height: size.height * 0.03),
        Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _saveUserData,
            icon: const Icon(Icons.save_rounded, color: Colors.white),
            label: const Text('Guardar Cambios',
                style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildAppSettingsSection() {
    final size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ajustes de la Aplicación',
          style: TextStyle(
              fontSize: size.width * 0.055,
              fontWeight: FontWeight.bold,
              color: Colors.teal),
        ),
        SizedBox(height: size.height * 0.015),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock_rounded, color: Colors.teal),
          title: const Text('Cambiar contraseña'),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          onTap: _changePassword,
        ),
        const Divider(),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _darkMode,
          // CORRECCIÓN: withValues en lugar de withOpacity
          activeTrackColor: Colors.teal.withValues(alpha: 0.5),
          activeThumbColor: Colors.teal,
          title: const Text('Modo oscuro'),
          onChanged: _toggleTheme,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _notifications,
          // CORRECCIÓN: withValues en lugar de withOpacity
          activeTrackColor: Colors.teal.withValues(alpha: 0.5),
          activeThumbColor: Colors.teal,
          title: const Text('Notificaciones'),
          onChanged: _toggleNotifications,
        ),
        Divider(height: size.height * 0.04),
        Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              // CORRECCIÓN: withValues en lugar de withAlpha (aunque withAlpha funciona, esto es más moderno)
              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
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
      ],
    );
  }
}