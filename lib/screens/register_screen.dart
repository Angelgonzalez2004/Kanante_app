// lib\screens\register_screen.dart

// 📦 Imports principales
import 'dart:typed_data'; // ✅ Para Uint8List (leer bytes de imagen)
import 'dart:math'; // Import for min function
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart'; // CAMBIO: Import de Firebase Storage
import 'package:image_picker/image_picker.dart';
// import 'package:cloudinary_sdk/cloudinary_sdk.dart'; // CAMBIO: Eliminado Cloudinary
import 'package:intl/intl.dart';
// import 'package:kanante_app/config.dart'; // CAMBIO: Eliminado (asumiendo que era para keys de Cloudinary)
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage =
      FirebaseStorage.instance; // CAMBIO: Instancia de Storage

  String name = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String accountType = 'Usuario';
  String phone = '';
  DateTime? _selectedBirthDate;
  String rfc = '';
  bool acceptTerms = false;
  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  XFile? _pickedXFile;

  // CAMBIO: Eliminada la inicialización de Cloudinary
  /*
  final Cloudinary _cloudinary = Cloudinary.full(
     cloudName: AppConfig.cloudinaryCloudName,
     apiKey: AppConfig.cloudinaryApiKey,
     apiSecret: AppConfig.cloudinaryApiSecret,
  );
  */

  // ---------------- Snackbar Helper ----------------
  void _showSnackBar(String message, {Color color = Colors.teal}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // ---------------- Image Picker ----------------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedXFile = picked;
      });
    }
  }

  // ---------------- Registro ----------------
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!acceptTerms) {
      _showSnackBar('Debes aceptar los términos y condiciones',
          color: Colors.red);
      return;
    }

    if (!_validateEmail(email)) {
      _showSnackBar('Correo electrónico inválido', color: Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      // 🔑 Crear usuario en Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = userCredential.user!.uid;

      String? profileImageUrl;

      // ---------------- CAMBIO: Subida de imagen a Firebase Storage ----------------
      if (_pickedXFile != null) {
        try {
          // 1. Leer bytes de la imagen
          Uint8List fileBytes = await _pickedXFile!.readAsBytes();

          // 2. Crear la referencia de archivo (p.ej. profile_images/user_uid.jpg)
          String fileExtension = _pickedXFile!.name.split('.').last;
          String fileName = 'user_${uid}_profile.$fileExtension';
          Reference storageRef =
              _storage.ref().child('profile_images/$fileName');

          // 3. Subir los bytes
          UploadTask uploadTask = storageRef.putData(fileBytes);

          // 4. Esperar a que se complete y obtener la URL
          TaskSnapshot snapshot = await uploadTask;
          profileImageUrl = await snapshot.ref.getDownloadURL();

          print('✅ Imagen subida correctamente a Storage: $profileImageUrl');
        } on FirebaseException catch (e) {
          print('❌ Error Firebase Storage: ${e.message}');
          _showSnackBar(
            'Error al subir imagen: ${e.message ?? "Error desconocido"}',
            color: Colors.orange,
          );
        } catch (e) {
          print('⚠️ Error al procesar imagen: $e');
          _showSnackBar('Error al procesar la imagen: $e',
              color: Colors.orange);
        }
      }
      // ---------------- FIN DEL CAMBIO ----------------

      // 🔹 Formatear fecha
      String formattedBirthDate = _selectedBirthDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedBirthDate!)
          : '';

      // 🗄 Guardar en Firebase Realtime Database
      await _db.child('users/$uid').set({
        'name': name.isEmpty ? null : name,
        'email': email,
        'accountType': accountType,
        'phone': phone.isEmpty ? null : phone,
        'birthDate': formattedBirthDate.isEmpty ? null : formattedBirthDate,
        'rfc': rfc.isEmpty ? null : rfc,
        'profileImageUrl':
            profileImageUrl, // Se guarda la URL de Firebase Storage
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'active',
      });

      _showSnackBar('Cuenta creada exitosamente 🎉');

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'email-already-in-use' => 'El correo ya está registrado',
        'invalid-email' => 'Correo inválido',
        'weak-password' => 'La contraseña es muy débil (mínimo 6 caracteres)',
        _ => e.message ?? 'Error al crear la cuenta',
      };
      _showSnackBar(message, color: Colors.red);
    } catch (e) {
      _showSnackBar('Error inesperado: $e', color: Colors.red);
      print('DEBUG - Error general: $e');
      try {
        // Intento de Rollback: Si falla la BD o Storage, borrar el usuario de Auth
        await _auth.currentUser?.delete();
        print('Usuario Auth eliminado por error en BD o Storage.');
      } catch (authDeleteError) {
        print('Error eliminando usuario de Auth: $authDeleteError');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Define max values for responsiveness
    const double maxIconSize = 80.0;
    const double maxTitleFontSize = 40.0;
    const double maxSubtitleFontSize = 20.0;
    const double maxButtonTextFontSize = 18.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFE0F2F1),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450), // Max width for the form on large screens
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0), // Fixed horizontal margin for the card
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0), // Fixed padding inside the card
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Use constraints.maxWidth instead of size.width here
                        return Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // To prevent column from taking full height unnecessarily
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                        Icon(Icons.spa_rounded,
                            size: min(constraints.maxWidth * 0.25, maxIconSize), color: Colors.teal[700]),
                        const SizedBox(height: 10),
                  Text('Únete a Kananté',
                      style: TextStyle(
                          fontSize: min(constraints.maxWidth * 0.07, maxTitleFontSize),
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[800])),
                  Text('Bienestar Joven-Mental Campeche',
                      style: TextStyle(
                          fontSize: min(constraints.maxWidth * 0.045, maxSubtitleFontSize),
                          color: Colors.teal[400],
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 30),

                  // 📸 Imagen de perfil
                  GestureDetector(
                    onTap: _pickImage,
                    child: _pickedXFile != null
                        ? FutureBuilder<Uint8List>(
                            future: _pickedXFile!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.white,
                                  child: CircularProgressIndicator(
                                      color: Colors.teal),
                                );
                              } else if (snapshot.hasData) {
                                return CircleAvatar(
                                  radius: 60,
                                  backgroundImage: MemoryImage(snapshot.data!),
                                );
                              } else {
                                return CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey[200],
                                  child: Icon(Icons.camera_alt,
                                      color: Colors.grey[800],
                                      size: min(constraints.maxWidth * 0.1, maxIconSize * 0.5)),
                                );
                              }
                            },
                          )
                        : CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            child: Icon(Icons.camera_alt,
                                color: Colors.grey[800],
                                size: min(constraints.maxWidth * 0.1, maxIconSize * 0.5)),
                          ),
                  ),
                  const SizedBox(height: 20),

                  ..._buildTextFields(size),
                  SizedBox(height: size.height * 0.025),
                  _buildAccountTypeDropdown(),
                  SizedBox(height: size.height * 0.025),
                  _buildTermsCheckbox(),
                  SizedBox(height: size.height * 0.03),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.white),
                    label: const Text('Registrarme',
                        style: TextStyle(
                            fontSize: maxButtonTextFontSize, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[600],
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, size.height * 0.07),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                        elevation: 4),
                    onPressed: isLoading ? null : _register,
                  ),
                  const SizedBox(height: 15),

                  TextButton.icon(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()));
                          },
                    icon: const Icon(Icons.arrow_back, color: Colors.teal),
                    label: const Text('Volver al inicio de sesión',
                        style: TextStyle(color: Colors.teal)),
                  ),
                        ],
                      ), // Closing main Column
                    ); // Closing Form
                  }), // Closing LayoutBuilder
                ), // Closing Padding inside Card
              ), // Closing Card
            ), // Closing ConstrainedBox
          ), // Closing Center
        ), // Closing SingleChildScrollView
          if (isLoading)
            Container(
              color: Colors.black38,
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.teal)),
            ),
        ],
      ),
    );
  }

  // ---------------- Widgets Helpers ----------------
  List<Widget> _buildTextFields(Size size) {
    return [
      _buildInputField(Icons.person, 'Nombre completo (opcional)',
          onChanged: (val) => name = val),
      const SizedBox(height: 20),
      _buildInputField(Icons.email_outlined, 'Correo electrónico',
          keyboardType: TextInputType.emailAddress,
          onChanged: (val) => email = val,
          validator: (val) =>
              val!.isEmpty ? 'Por favor ingresa tu correo' : null),
      const SizedBox(height: 20),
      _buildPasswordField(),
      const SizedBox(height: 20),
      _buildConfirmPasswordField(),
      const SizedBox(height: 20),
      _buildInputField(Icons.phone, 'Teléfono (opcional)',
          keyboardType: TextInputType.phone, onChanged: (val) => phone = val),
      const SizedBox(height: 15),
      _buildBirthDatePicker(),
      const SizedBox(height: 15),
      _buildInputField(Icons.badge, 'RFC (opcional)',
          onChanged: (val) => rfc = val),
    ];
  }

  Widget _buildInputField(IconData icon, String label,
      {bool obscureText = false,
      TextInputType keyboardType = TextInputType.text,
      Function(String)? onChanged,
      String? Function(String?)? validator}) {
    return TextFormField(
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.teal),
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none),
      ),
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      obscureText: !showPassword,
      onChanged: (val) => password = val,
      validator: (val) => val!.length < 6 ? 'Mínimo 6 caracteres' : null,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.teal),
        labelText: 'Contraseña',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none),
        suffixIcon: IconButton(
          icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.teal),
          onPressed: () => setState(() => showPassword = !showPassword),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      obscureText: !showConfirmPassword,
      onChanged: (val) => confirmPassword = val,
      validator: (val) {
        if (val!.isEmpty) return 'Confirma tu contraseña';
        if (val != password) return 'Las contraseñas no coinciden';
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_reset_rounded, color: Colors.teal),
        labelText: 'Confirmar contraseña',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none),
        suffixIcon: IconButton(
          icon: Icon(
              showConfirmPassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.teal),
          onPressed: () =>
              setState(() => showConfirmPassword = !showConfirmPassword),
        ),
      ),
    );
  }

  Widget _buildBirthDatePicker() {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(
        text: _selectedBirthDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedBirthDate!)
            : '',
      ),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedBirthDate ?? DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          helpText: 'Selecciona tu fecha de nacimiento',
          cancelText: 'Cancelar',
          confirmText: 'Seleccionar',
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Colors.teal,
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(foregroundColor: Colors.teal),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _selectedBirthDate = picked);
        }
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.calendar_today, color: Colors.teal),
        labelText: 'Fecha de nacimiento (opcional)',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildAccountTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: DropdownButtonFormField<String>(
        value: accountType,
        isExpanded: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.account_circle, color: Colors.teal),
          labelText: 'Tipo de cuenta',
          labelStyle: TextStyle(color: Colors.teal),
        ),
        items: const [
          DropdownMenuItem(
              value: 'Usuario', child: Text('Usuario (uso personal)')),
          DropdownMenuItem(
              value: 'Profesional',
              child: Text(
                  'Profesional de la salud (psicólogo, terapeuta, psiquiatta, etc.)')),
        ],
        onChanged: (value) {
          setState(() {
            accountType = value!;
          });
        },
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return CheckboxListTile(
      value: acceptTerms,
      onChanged: (value) => setState(() => acceptTerms = value!),
      activeColor: Colors.teal,
      title: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Términos y Condiciones'),
              content: const SingleChildScrollView(
                child: Text(
                    'Al registrarte en Kananté, aceptas el uso responsable de la plataforma, '
                    'el tratamiento confidencial de los datos y el respeto hacia los profesionales y usuarios de bienestar.'),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'))
              ],
            ),
          );
        },
        child: const Text('Acepto los términos y condiciones',
            style: TextStyle(color: Colors.teal)),
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
