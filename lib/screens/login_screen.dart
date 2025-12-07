import 'dart:async'; // Added for StreamSubscription
import 'package:flutter/foundation.dart' show kIsWeb; // Added for kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/floating_registration_form.dart';
import '../../widgets/auth/primary_auth_button.dart';
import '../../widgets/auth/social_auth_button.dart';
import '../../widgets/fade_in_slide.dart';

import 'register_screen.dart';
import 'recover_password_screen.dart';
import 'welcome_screen.dart';
import 'user/user_dashboard.dart';
import 'professional/professional_dashboard.dart';
import 'admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseService _firebaseService = FirebaseService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;
  bool _rememberMe = false;

  StreamSubscription<GoogleSignInAccount?>? _googleSignInSubscription; // Added

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    if (kIsWeb) {
      _googleSignInSubscription = _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? googleUser) {
        if (googleUser != null) {
          _handleSuccessfulGoogleSignIn(googleUser);
        } else {
          // User signed out or sign-in failed. Reset loading state if set.
          if (mounted) setState(() => isLoading = false);
        }
      });
      // Try to sign in silently if user is already authenticated
      _googleSignIn.signInSilently();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _googleSignInSubscription?.cancel(); // Cancel subscription
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    if (email != null) {
      setState(() {
        _emailController.text = email;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('email', _emailController.text.trim());
    } else {
      await prefs.remove('email');
    }
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await _saveCredentials();
      final snapshot = await _db.child('users/${userCredential.user!.uid}/accountType').get();

      if (!snapshot.exists || snapshot.value == null) {
        _showSnackBar('No se encontró información del usuario.', isError: true);
        await _auth.signOut();
        return;
      }

      String accountType = snapshot.value.toString();
      _navigateToDashboard(accountType);

    } on FirebaseAuthException catch (e) {
      String message = 'Ocurrió un error. Intenta de nuevo.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
        message = 'Correo o contraseña incorrectos.';
      }
      _showSnackBar(message, isError: true);
    } catch (e) {
      _showSnackBar('Error inesperado: $e', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // New helper method to handle successful Google Sign-In and Firebase authentication
  Future<void> _handleSuccessfulGoogleSignIn(GoogleSignInAccount googleUser) async {
    setState(() => isLoading = true); // Ensure loading is true while handling
    try {
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        UserModel? userModel = await _firebaseService.getUserProfile(user.uid);

        if (!mounted) return;
        if (userModel != null) {
          _navigateToDashboard(userModel.accountType);
        } else {
          _showFloatingRegisterSheet(user);
        }
      }
    } catch (e) {
      _showSnackBar('Error al iniciar sesión con Google: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Refactored _signInWithGoogle method
  Future<void> _signInWithGoogle() async {
    setState(() => isLoading = true); // Start loading immediately
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn(); // Initiate interactive sign-in
      if (googleUser == null) {
        // User cancelled the sign-in process
        if (mounted) setState(() => isLoading = false);
        return;
      }
      // For non-web, we call _handleSuccessfulGoogleSignIn directly.
      // For web, the _googleSignIn.onCurrentUserChanged listener will pick up the googleUser
      // and call _handleSuccessfulGoogleSignIn.
      if (!kIsWeb) { 
        _handleSuccessfulGoogleSignIn(googleUser);
      }
    } on Exception catch (e) { // Catch Exception here to avoid Firebase specific catch for Google Sign In on web
      _showSnackBar('Error al iniciar sesión con Google: ${e.toString()}', isError: true);
      if (mounted) setState(() => isLoading = false); // Reset loading on error
    } 
    // No finally block to reset isLoading for web here, as _handleSuccessfulGoogleSignIn or cancellation handles it.
  }
  
  void _showFloatingRegisterSheet(User googleUser) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: FloatingRegistrationForm(googleUser: googleUser),
      ),
    );

    if (result != null) {
      _navigateToDashboard(result);
    }
  }


  void _navigateToDashboard(String accountType) {
    if (!mounted) return;
    
    Widget? dashboard;
    switch (accountType) {
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
        _showSnackBar('Tipo de cuenta no reconocido.', isError: true);
        return; 
    }
    
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => dashboard!));
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible( // Added Flexible
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) => setState(() => _rememberMe = value!),
                                    activeColor: AppColors.primary,
                                  ),
                                  const Flexible(child: Text('Recordar correo', style: TextStyle(color: AppColors.textLight))), // Added Flexible
                                ],
                              ),
                            ),
                            Flexible( // Added Flexible
                              child: TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecoverPasswordScreen())),
                                child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: AppColors.primary)),
                              ),
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
                      
                      SizedBox(height: size.height * 0.03),
                      const FadeInSlide(
                        duration: Duration(milliseconds: 500),
                        delay: Duration(milliseconds: 700),
                        child: Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('O', style: TextStyle(color: AppColors.textLight)),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                      ),

                      SizedBox(height: size.height * 0.03),
                      FadeInSlide(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 800),
                        child: SocialAuthButton(
                          text: 'Continuar con Google',
                          isLoading: isLoading,
                          onPressed: _signInWithGoogle,
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
                      const SizedBox(height: 16), // Add some space
                      FadeInSlide(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 1000),
                        child: TextButton(
                          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen())), // Use pushReplacement
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