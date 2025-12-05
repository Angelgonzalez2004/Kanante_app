import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../services/firebase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/primary_auth_button.dart';
import '../../widgets/fade_in_slide.dart';

import 'admin/admin_dashboard.dart';
import 'login_screen.dart';
import 'user/user_dashboard.dart';
import 'professional/professional_dashboard.dart';

class RegisterScreen extends StatefulWidget {
  final User? googleUser;
  const RegisterScreen({super.key, this.googleUser});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const String _kAdminSecretKey = '12345678'; // Keep this secure
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseService _firebaseService = FirebaseService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rfcController = TextEditingController();
  final _birthDateController = TextEditingController();

  String _accountType = 'Usuario';
  DateTime? _selectedBirthDate;
  bool _acceptTerms = false;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  XFile? _pickedXFile;
  bool _isAdminKeyVerified = false;

  @override
  void initState() {
    super.initState();
    if (widget.googleUser != null) {
      _emailController.text = widget.googleUser!.email ?? '';
      _nameController.text = widget.googleUser!.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _rfcController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _pickedXFile = picked);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Por favor, corrige los errores en el formulario.', isError: true);
      return;
    }
    if (!_acceptTerms) {
      _showSnackBar('Debes aceptar los términos y condiciones para continuar.', isError: true);
      return;
    }
    if (_accountType == 'Admin' && !_isAdminKeyVerified) {
      _showSnackBar('Debes verificar la clave de administrador para registrarte como uno.', isError: true);
      _showAdminKeyDialog(); // Re-prompt for key
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user;
      if (widget.googleUser != null) {
        user = widget.googleUser;
      } else {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        user = userCredential.user;
      }

      if (user == null) throw Exception("No se pudo obtener la información de usuario.");

      String? profileImageUrl;
      if (_accountType == 'Profesional') {
         profileImageUrl = user.photoURL;
        if (_pickedXFile != null) {
          Uint8List fileBytes = await _pickedXFile!.readAsBytes();
          String fileExtension = _pickedXFile!.name.split('.').last;
          String fileName = 'profile_images/${user.uid}.$fileExtension';
          Reference storageRef = _storage.ref().child(fileName);
          UploadTask uploadTask = storageRef.putData(fileBytes);
          TaskSnapshot snapshot = await uploadTask;
          profileImageUrl = await snapshot.ref.getDownloadURL();
        }
      }

      await _firebaseService.createNewUser(
        uid: user.uid,
        email: user.email!,
        name: _nameController.text.trim(),
        accountType: _accountType,
        profileImageUrl: profileImageUrl,
        birthDate: _selectedBirthDate,
        phone: _phoneController.text.trim(),
        rfc: _rfcController.text.trim(),
      );

      _showSnackBar('¡Cuenta creada exitosamente! Bienvenido a Kananté.');
      if (!mounted) return;

      Widget dashboard;
      switch (_accountType) {
        case 'Usuario':
          dashboard = const UserDashboard();
          break;
        case 'Profesional':
          dashboard = const ProfessionalDashboard();
          break;
        case 'Admin':
          dashboard = const AdminDashboard();
          break;
        default:
          dashboard = const LoginScreen();
      }
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => dashboard), (route) => false);

    } on FirebaseAuthException catch (e) {
      String message = 'Ocurrió un error. Intenta de nuevo más tarde.';
      if (e.code == 'email-already-in-use') {
        message = 'El correo electrónico ya está en uso. Por favor, intenta iniciar sesión.';
      } else if (e.code == 'weak-password') {
        message = 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
      }
      _showSnackBar(message, isError: true);
    } catch (e) {
      _showSnackBar('Ocurrió un error inesperado: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _onAccountTypeChanged(String? newValue) {
    if (newValue == null) return;
    
    setState(() {
      _accountType = newValue;
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
      builder: (context) {
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
                Navigator.of(context).pop();
                // If user cancels, revert account type selection
                setState(() {
                  _accountType = 'Usuario';
                  _isAdminKeyVerified = false;
                });
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (keyController.text.trim() == _kAdminSecretKey) {
                  setState(() => _isAdminKeyVerified = true);
                  Navigator.of(context).pop();
                  _showSnackBar('Clave de administrador correcta.');
                } else {
                  // Show error inside the dialog or as a snackbar after popping
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Clave incorrecta."), backgroundColor: Colors.red));
                }
              },
              child: const Text('Verificar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGoogleUser = widget.googleUser != null;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Crear Cuenta', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_accountType == 'Profesional') ...[
                      FadeInSlide(
                        duration: const Duration(milliseconds: 400),
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _pickedXFile != null ? FileImage(File(_pickedXFile!.path)) : null,
                            child: _pickedXFile == null ? const Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey) : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const FadeInSlide(
                        delay: Duration(milliseconds: 100),
                        child: Text('Añadir foto de perfil', style: TextStyle(color: AppColors.textLight)),
                      ),
                      const SizedBox(height: 30),
                    ],

                    FadeInSlide(delay: const Duration(milliseconds: 200), child: _buildTextField(controller: _nameController, label: 'Nombre completo', icon: Icons.person_outline, validator: (val) => val!.isEmpty ? 'Ingresa tu nombre' : null)),
                    const SizedBox(height: 20),
                    FadeInSlide(delay: const Duration(milliseconds: 300), child: _buildTextField(controller: _emailController, label: 'Correo electrónico', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, enabled: !isGoogleUser, validator: (val) => (val == null || !val.contains('@')) ? 'Correo inválido' : null)),
                    if (!isGoogleUser) ...[
                      const SizedBox(height: 20),
                      FadeInSlide(delay: const Duration(milliseconds: 400), child: _buildPasswordField(_passwordController, 'Contraseña')),
                      const SizedBox(height: 20),
                      FadeInSlide(delay: const Duration(milliseconds: 500), child: _buildConfirmPasswordField()),
                    ],
                    const SizedBox(height: 20),
                    FadeInSlide(delay: const Duration(milliseconds: 600), child: _buildDropdown()),
                    const SizedBox(height: 20),
                    FadeInSlide(delay: const Duration(milliseconds: 700), child: _buildDatePicker()),
                    const SizedBox(height: 20),

                    FadeInSlide(
                      delay: const Duration(milliseconds: 800),
                      child: CheckboxListTile(
                        value: _acceptTerms,
                        onChanged: (value) => setState(() => _acceptTerms = value!),
                        activeColor: AppColors.primary,
                        title: const Text('Acepto los términos y condiciones', style: TextStyle(color: AppColors.textLight)),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInSlide(
                      delay: const Duration(milliseconds: 900),
                      child: PrimaryAuthButton(
                        text: 'Crear Cuenta',
                        isLoading: _isLoading,
                        onPressed: _register,
                      ),
                    ),
                    const SizedBox(height: 20),
                     FadeInSlide(
                      delay: const Duration(milliseconds: 1000),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('¿Ya tienes una cuenta? Inicia Sesión', style: TextStyle(color: AppColors.primary)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading) Container(color: Colors.black.withValues(alpha: 0.2), child: const Center(child: CircularProgressIndicator(color: AppColors.primary))),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text, bool enabled = true, String? Function(String?)? validator}) {
    return AuthTextField(
      controller: controller,
      labelText: label,
      icon: icon,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator ?? (val) => null,
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label) {
    return AuthTextField(
      controller: controller,
      labelText: label,
      icon: Icons.lock_outline,
      obscureText: !_showPassword,
      validator: (val) => (val == null || val.length < 6) ? 'Mínimo 6 caracteres' : null,
      suffixIcon: IconButton(
        icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textLight),
        onPressed: () => setState(() => _showPassword = !_showPassword),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return AuthTextField(
      controller: _confirmPasswordController,
      labelText: 'Confirmar contraseña',
      icon: Icons.lock_outline,
      obscureText: !_showConfirmPassword,
      validator: (val) {
        if (val != _passwordController.text) return 'Las contraseñas no coinciden';
        return null;
      },
      suffixIcon: IconButton(
        icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textLight),
        onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
      ),
    );
  }
  
  Widget _buildDatePicker() {
    return TextFormField(
      controller: _birthDateController,
      readOnly: true,
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedBirthDate ?? DateTime(2000),
          firstDate: DateTime(1920),
          lastDate: DateTime.now(),
          builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!),
        );
        if (picked != null) {
          setState(() {
            _selectedBirthDate = picked;
            _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
          });
        }
      },
      decoration: InputDecoration(
        labelText: 'Fecha de nacimiento (opcional)',
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        labelStyle: const TextStyle(color: AppColors.textLight),
        prefixIconColor: AppColors.primary,
        filled: true,
        // Usamos const aquí
        fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _accountType,
      onChanged: _onAccountTypeChanged,
      items: const [
        DropdownMenuItem(value: 'Usuario', child: Text('Usuario (busco ayuda)')),
        DropdownMenuItem(value: 'Profesional', child: Text('Profesional (ofrezco ayuda)')),
        DropdownMenuItem(value: 'Admin', child: Text('Administrador')),
      ],
      decoration: InputDecoration(
        labelText: 'Tipo de cuenta',
        prefixIcon: const Icon(Icons.account_circle_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        labelStyle: const TextStyle(color: AppColors.textLight),
        prefixIconColor: AppColors.primary,
        filled: true,
        // Usamos const aquí
        fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}