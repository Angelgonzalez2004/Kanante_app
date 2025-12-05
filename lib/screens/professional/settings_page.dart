import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io'; // For File
import '../../main.dart'; // Para themeNotifier
import '../login_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _darkMode = false;
  bool _notifications = true;
  bool _isLoading = true;
  String _verificationStatus = "no verificado"; // Default status
  String? _verificationImageUrl;
  String? _verificationRejectionReason; // New

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadVerificationStatus();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _notifications = prefs.getBool('notifications') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _loadVerificationStatus() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _db.child('users/${user.uid}/verificationStatus').get();
    final imageUrlSnapshot = await _db.child('users/${user.uid}/verificationImageUrl').get();
    final rejectionReasonSnapshot = await _db.child('users/${user.uid}/verificationRejectionReason').get(); // New

    if (mounted) {
      setState(() {
        _verificationStatus = snapshot.exists ? snapshot.value.toString() : "no verificado";
        _verificationImageUrl = imageUrlSnapshot.exists ? imageUrlSnapshot.value.toString() : null;
        _verificationRejectionReason = rejectionReasonSnapshot.exists ? rejectionReasonSnapshot.value.toString() : null; // New
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se seleccionó ninguna imagen.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true; // Show loading while uploading
    });

    User? user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado.')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      String fileName = 'verification_documents/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      UploadTask uploadTask = _storage.ref().child(fileName).putFile(File(image.path));
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _db.child('users/${user.uid}').update({
        'verificationStatus': 'pendiente',
        'verificationImageUrl': downloadUrl,
      });

      if (mounted) {
        setState(() {
          _verificationStatus = 'pendiente';
          _verificationImageUrl = downloadUrl;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento subido. Verificación pendiente.')),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir documento: ${e.message}')),
        );
      }
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final TextEditingController newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nueva contraseña',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, newPasswordController.text);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _auth.currentUser?.updatePassword(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contraseña actualizada correctamente')),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, salir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      await _googleSignIn.signOut();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
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
    setState(() => _darkMode = value);
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    await prefs.setBool('darkMode', value);
  }

  Future<void> _toggleNotifications(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _notifications = value);
    await prefs.setBool('notifications', value);
  }

  Widget _buildVerificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Verificación Profesional'),
        _buildSettingsCard([
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado de verificación: $_verificationStatus',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                if (_verificationStatus == 'no verificado' || _verificationStatus == 'rechazado')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_verificationStatus == 'rechazado' && _verificationRejectionReason != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Text(
                            'Tu solicitud de verificación fue rechazada. Razón: $_verificationRejectionReason',
                            style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _pickAndUploadImage,
                        icon: const Icon(Icons.upload_file),
                        label: Text(_verificationStatus == 'rechazado' ? 'Re-solicitar Verificación' : 'Solicitar Verificación'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  )
                else if (_verificationStatus == 'pendiente')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tu solicitud está pendiente de revisión. Te notificaremos cuando se complete.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      if (_verificationImageUrl != null) ...[
                        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                        Text('Documento subido:', style: Theme.of(context).textTheme.labelLarge),
                        Image.network(
                          _verificationImageUrl!,
                          height: MediaQuery.of(context).size.height * 0.1,
                          fit: BoxFit.cover,
                        ),
                      ],
                    ],
                  )
                else if (_verificationStatus == 'verificado')
                  const Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded( // Wrap Text with Expanded
                        child: Text(
                          '¡Tu cuenta profesional ha sido verificada!',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis, // Add ellipsis for long text
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ]),
        SizedBox(height: MediaQuery.of(context).size.height * 0.03),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajustes"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVerificationSection(), // New verification section
                        _buildSectionTitle(context, 'Apariencia'),
                        _buildSettingsCard([
                          _buildThemeSwitch(),
                        ]),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                        _buildSectionTitle(context, 'Notificaciones'),
                        _buildSettingsCard([
                          _buildNotificationsSwitch(),
                        ]),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                        _buildSectionTitle(context, 'Cuenta'),
                        _buildSettingsCard([
                          _buildAccountOption(context, 'Cambiar contraseña', Icons.lock_outline, _changePassword),
                          const Divider(),
                          _buildAccountOption(context, 'Cerrar Sesión', Icons.logout, _logout, isDestructive: true),
                           const Divider(),
                          _buildAccountOption(context, 'Eliminar cuenta', Icons.delete_outline, _deleteAccount, isDestructive: true),
                        ]),
                      ],
                    ),
                  ),
                ),
              );
            }),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _buildThemeSwitch() {
    return SwitchListTile(
      title: const Text('Modo oscuro'),
      value: _darkMode,
      onChanged: _toggleTheme,
      secondary: const Icon(Icons.brightness_6_outlined),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildNotificationsSwitch() {
    return SwitchListTile(
      title: const Text('Activar notificaciones'),
      value: _notifications,
      onChanged: _toggleNotifications,
      secondary: const Icon(Icons.notifications_outlined),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildAccountOption(BuildContext context, String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? Colors.red.shade700 : Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
