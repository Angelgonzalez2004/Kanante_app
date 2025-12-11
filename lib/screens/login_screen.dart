

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// --- IMPORTANTE: Usamos la ruta del paquete para importar tu AuthWrapper ---
import 'package:kanante_app/screens/shared/auth_wrapper.dart';
import 'package:kanante_app/theme/app_colors.dart';

// Widgets de tu UI
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/fade_in_slide.dart';

import '../../widgets/auth/primary_auth_button.dart'; // Added
import 'register_screen.dart'; // Added
import 'recover_password_screen.dart'; // Added
import 'welcome_screen.dart'; // Added

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

  @override
  void initState() {
    super.initState();
    // if (kIsWeb) { // Suspendido temporalmente
    //   _googleSignInSubscription = _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? googleUser) {
    //     if (googleUser != null) {
    //       _handleSuccessfulGoogleSignIn(googleUser);
    //     // } else {
    //       if (mounted) setState(() => isLoading = false);
    //     }
    //   });
    //   _googleSignIn.signInSilently();
    // } // Suspendido temporalmente
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  // --- FUNCIÓN HELPER PARA NAVEGAR AL AUTH WRAPPER ---
  // Esta función elimina todas las pantallas anteriores y pone al AuthWrapper como jefe
  void _navigateToAuthWrapper() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
      (Route<dynamic> route) => false,
    );
  }

  // --- LOGIN CON EMAIL ---
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Verificamos que el usuario exista en la base de datos de Realtime Database
      final snapshot = await _db.child('users/${userCredential.user!.uid}').get();

      if (!snapshot.exists || snapshot.value == null) {
        _showSnackBar('No se encontró información del usuario en la base de datos.', isError: true);
        await _auth.signOut(); // Cerramos la sesión porque es un usuario fantasma
        if (mounted) setState(() => isLoading = false);
        return;
      }
      
      // ¡ÉXITO! Navegamos al Wrapper
      _navigateToAuthWrapper();

    } on FirebaseAuthException catch (e) {
      String message = 'Ocurrió un error. Intenta de nuevo.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
        message = 'Correo o contraseña incorrectos.';
      } else if (e.code == 'too-many-requests') {
        message = 'Demasiados intentos. Intenta más tarde.';
      }
      _showSnackBar(message, isError: true);
      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      _showSnackBar('Error inesperado: $e', isError: true);
      if (mounted) setState(() => isLoading = false);
    } 
  }
  


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.06, vertical: size.height * 0.05),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FadeInSlide(
                        duration: Duration(milliseconds: 400),
                        child: Icon(Icons.spa_outlined, size: 60, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      const FadeInSlide(
                        duration: Duration(milliseconds: 500),
                        delay: Duration(milliseconds: 100),
                        child: Text(
                          'Kananté',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const FadeInSlide(
                        duration: Duration(milliseconds: 500),
                        delay: Duration(milliseconds: 200),
                        child: Text(
                          'Bienvenido de vuelta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.05),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            FadeInSlide(
                              duration: const Duration(milliseconds: 500),
                              delay: const Duration(milliseconds: 300),
                              child: AuthTextField(
                                controller: _emailController,
                                labelText: 'Correo electrónico',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) => (value == null || !value.contains('@')) ? 'Correo inválido' : null,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FadeInSlide(
                              duration: const Duration(milliseconds: 500),
                              delay: const Duration(milliseconds: 400),
                              child: AuthTextField(
                                controller: _passwordController,
                                labelText: 'Contraseña',
                                icon: Icons.lock_outline,
                                obscureText: !showPassword,
                                validator: (value) => (value == null || value.length < 6) ? 'La contraseña debe tener al menos 6 caracteres' : null,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    showPassword ? Icons.visibility_off : Icons.visibility,
                                    color: AppColors.textLight,
                                  ),
                                  onPressed: () => setState(() => showPassword = !showPassword),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FadeInSlide(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 500),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end, // Changed to end, as only one item will remain
                          children: [
                            TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecoverPasswordScreen())),
                                child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: AppColors.primary)),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: size.height * 0.03),
                      FadeInSlide(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 600),
                        child: PrimaryAuthButton(
                          text: 'Entrar',
                          isLoading: isLoading,
                          onPressed: _login,
                        ),
                      ),
                      



                      SizedBox(height: size.height * 0.04),
                      SizedBox(height: size.height * 0.04),
                      
                      FadeInSlide(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 900),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('¿No tienes una cuenta? ', style: TextStyle(color: AppColors.textLight)),
                            TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                              child: const Text('Crea una aquí', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeInSlide(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 1000),
                        child: TextButton(
                          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen())),
                          child: const Text('‹ Volver a la Bienvenida', style: TextStyle(color: AppColors.textLight)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withAlpha((255 * 0.2).round()), 
              child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }
}