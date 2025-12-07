import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:kanante_app/theme/app_colors.dart';
import 'package:kanante_app/widgets/auth/primary_auth_button.dart';

class FloatingRegistrationForm extends StatefulWidget {
  final User googleUser;

  const FloatingRegistrationForm({super.key, required this.googleUser});

  @override
  State<FloatingRegistrationForm> createState() =>
      _FloatingRegistrationFormState();
}

class _FloatingRegistrationFormState extends State<FloatingRegistrationForm> {
  static const String _kAdminSecretKey = '12345678'; // Keep this secure
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  String? _selectedRole;
  bool _isLoading = false;
  bool _isAdminKeyVerified = false;

  void _onAccountTypeChanged(String? newValue) {
    if (newValue == null) return;
    
    setState(() {
      _selectedRole = newValue;
      // Reset admin verification if user switches away from Admin
      if (newValue != 'Admin') {
        _isAdminKeyVerified = false;
      }
    });

    if (newValue == 'Admin') {
      _showAdminKeyDialog();
    }
  }

  void _showAdminKeyDialog() {
    final keyController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false, // User must interact with dialog
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clave de Administrador'),
          content: TextField(
            controller: keyController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Ingresa la clave secreta',
              icon: Icon(Icons.key),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // If user cancels, revert account type selection
                setState(() {
                  _selectedRole = null;
                  _isAdminKeyVerified = false;
                });
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (keyController.text.trim() == _kAdminSecretKey) {
                  setState(() => _isAdminKeyVerified = true);
                  Navigator.of(dialogContext).pop();
                  _showSnackBar('Clave de administrador correcta.', isError: false);
                } else {
                   _showSnackBar("Clave incorrecta.", isError: true);
                }
              },
              child: const Text('Verificar'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _completeRegistration() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == null) {
        _showSnackBar('Por favor, selecciona un rol.', isError: true);
        return;
      }

      if (_selectedRole == 'Admin' && !_isAdminKeyVerified) {
        _showSnackBar('Debes verificar la clave de administrador para registrarte como uno.', isError: true);
        _showAdminKeyDialog(); // Re-prompt for key
        return;
      }

      setState(() => _isLoading = true);

      try {
        await _firebaseService.createNewUser(
          uid: widget.googleUser.uid,
          email: widget.googleUser.email!,
          name: widget.googleUser.displayName ?? 'Usuario de Google',
          accountType: _selectedRole!,
          profileImageUrl: widget.googleUser.photoURL,
        );

        if (mounted) {
          Navigator.pop(context, _selectedRole); // Return the selected role
        }
      } catch (e) {
        _showSnackBar('Ocurrió un error al completar el registro.', isError: true);
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Completa tu registro',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '¡Bienvenido! Solo falta un paso.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              initialValue: widget.googleUser.displayName ?? '',
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.googleUser.email ?? '',
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Selecciona tu rol',
                prefixIcon: Icon(Icons.person_pin_outlined),
                border: OutlineInputBorder(),
              ),
              items: ['Usuario', 'Profesional', 'Admin'] // Added 'Admin'
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      ))
                  .toList(),
              onChanged: _onAccountTypeChanged, // Changed to new handler
              validator: (value) =>
                  value == null ? 'Debes seleccionar un rol' : null,
            ),
            const SizedBox(height: 24),
            PrimaryAuthButton(
              text: 'Finalizar Registro',
              isLoading: _isLoading,
              onPressed: _completeRegistration,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
