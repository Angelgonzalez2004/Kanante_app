import 'package:flutter/material.dart';
import 'dart:math'; // Import for min function
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_screen.dart';
import 'recover_password_screen.dart';
import 'user/user_dashboard.dart';
import 'professional/professional_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final password = prefs.getString('password');
    if (email != null && password != null) {
      setState(() {
        _emailController.text = email;
        _passwordController.text = password;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('email', _emailController.text.trim());
      await prefs.setString('password', _passwordController.text);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
    }
  }

  void _showSnackBar(String message, {Color color = Colors.teal}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await _saveCredentials();

      String uid = userCredential.user!.uid;

      // 🔎 Obtener tipo de cuenta desde Realtime Database (validado)
      final snapshot = await _db.child('users/$uid/accountType').get();

      if (!snapshot.exists || snapshot.value == null) {
        _showSnackBar(
            'No se encontró información del usuario en la base de datos.',
            color: Colors.red);
        return;
      }

      String accountType = snapshot.value.toString();

      _showSnackBar('Inicio de sesión exitoso!', color: Colors.green);

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      if (accountType == 'Usuario') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserDashboard()),
        );
      } else if (accountType == 'Profesional') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfessionalDashboard()),
        );
      } else {
        _showSnackBar('Tipo de cuenta desconocido.', color: Colors.red);
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No se encontró ninguna cuenta con este correo.';
          break;
        case 'wrong-password':
          message = 'Contraseña incorrecta.';
          break;
        default:
          message = e.message ?? 'Error al iniciar sesión.';
      }
      _showSnackBar(message, color: Colors.red);
    } catch (e) {
      _showSnackBar('Error inesperado: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Define max values for responsiveness
    const double maxIconSize = 80.0;
    const double maxTitleFontSize = 40.0;
    const double maxSubtitleFontSize = 20.0;
    const double maxButtonTextFontSize = 18.0;

    return Scaffold(
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
                            children: [
                        Icon(Icons.spa_rounded,
                            color: Colors.teal[600], size: min(constraints.maxWidth * 0.25, maxIconSize)),
                        SizedBox(height: size.height * 0.01),
                    Text('Kananté',
                        style: TextStyle(
                            fontSize: min(constraints.maxWidth * 0.1, maxTitleFontSize),
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[700])),
                    Text('Bienestar Joven Campeche',
                        style: TextStyle(
                            fontSize: min(constraints.maxWidth * 0.045, maxSubtitleFontSize),
                            color: Colors.teal[400],
                            fontWeight: FontWeight.w500)),
                    SizedBox(height: size.height * 0.05),

                    // 📨 Campo de correo
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: Colors.teal),
                        labelText: 'Correo electrónico',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Por favor ingresa tu correo'
                          : null,
                    ),
                    SizedBox(height: size.height * 0.02),

                    // 🔒 Campo de contraseña (con mostrar/ocultar)
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: Colors.teal),
                        labelText: 'Contraseña',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.teal,
                          ),
                          onPressed: () =>
                              setState(() => showPassword = !showPassword),
                        ),
                      ),
                      obscureText: !showPassword,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Por favor ingresa tu contraseña'
                          : null,
                    ),

                    CheckboxListTile(
                      title: const Text('Recordar cuenta'),
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value!;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    SizedBox(height: size.height * 0.03),

                    // 🚪 Botón Entrar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.login, color: Colors.white),
                        label: const Text('Entrar',
                            style: TextStyle(
                                fontSize: maxButtonTextFontSize, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              vertical: min(size.height * 0.02, 20.0)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                          elevation: 4,
                        ),
                        onPressed: isLoading ? null : _login,
                      ),
                    ),

                    SizedBox(height: size.height * 0.02),

                    // 👤 Botón Crear cuenta
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.person_add_alt_1_rounded,
                            color: Colors.teal),
                        label: const Text('Crear cuenta',
                            style: TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.w600,
                                fontSize: maxButtonTextFontSize - 2)),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: min(size.height * 0.018, 18.0)),
                          side: const BorderSide(color: Colors.teal),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ),
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen()),
                                );
                              },
                      ),
                    ),

                    SizedBox(height: size.height * 0.015),

                    // 🔁 Recuperar contraseña
                    TextButton.icon(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const RecoverPasswordScreen()),
                              );
                            },
                      icon: const Icon(Icons.lock_reset_rounded,
                          color: Colors.teal),
                      label: const Text('¿Olvidaste tu contraseña?',
                          style: TextStyle(
                              color: Colors.teal, fontWeight: FontWeight.w500)),
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

          // ⏳ Capa de carga
          if (isLoading)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.teal),
              ),
            ),
        ],
      ),
    );
  }
}