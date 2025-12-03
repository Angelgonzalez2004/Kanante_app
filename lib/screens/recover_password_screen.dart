import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_colors.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/primary_auth_button.dart';
import '../../widgets/fade_in_slide.dart';

class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
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

  Future<void> _recoverPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      _showSnackBar(
        'Se ha enviado un enlace a tu correo.',
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      String message = 'Ocurrió un error. Intenta de nuevo.';
      if (e.code == 'user-not-found') {
        message = 'No se encontró ninguna cuenta con este correo.';
      }
      _showSnackBar(message, isError: true);
    } catch (e) {
      _showSnackBar('Error inesperado: $e', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FadeInSlide(
                    duration: Duration(milliseconds: 400),
                    child: Icon(Icons.lock_open_outlined, size: 60, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  const FadeInSlide(
                    delay: Duration(milliseconds: 100),
                    child: Text(
                      'Recupera tu Cuenta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 200),
                    child: const Text(
                      'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: AppColors.textLight),
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 300),
                    child: Form(
                      key: _formKey,
                      child: AuthTextField(
                        controller: _emailController,
                        labelText: 'Correo electrónico',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => (value == null || !value.contains('@')) ? 'Correo inválido' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 400),
                    child: PrimaryAuthButton(
                      text: 'Enviar Enlace',
                      isLoading: isLoading,
                      onPressed: _recoverPassword,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: const Color.fromRGBO(0, 0, 0, 0.2),
              child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }
}
