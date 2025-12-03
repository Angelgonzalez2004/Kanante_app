import 'package:flutter/material.dart';
import 'dart:math'; // Import for min function
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String email = '';
  bool isLoading = false;

  void _showSnackBar(String message, {Color color = Colors.teal}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _recoverPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());

      _showSnackBar(
        'Se ha enviado un enlace para restablecer tu contraseña a $email',
        color: Colors.green,
      );

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'Correo inválido. Por favor verifica y vuelve a intentar.';
          break;
        case 'user-not-found':
          message = 'No se encontró ninguna cuenta con este correo.';
          break;
        default:
          message = e.message ?? 'Error al enviar el enlace';
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
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
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
                        // ICONO GRANDE
                        Icon(
                          Icons.lock_reset_rounded,
                          size: min(constraints.maxWidth * 0.25, maxIconSize),
                          color: Colors.teal[700],
                        ),
                        const SizedBox(height: 20),

                  // TITULO PRINCIPAL
                  Text(
                    'Recupera tu contraseña',
                    style: TextStyle(
                      fontSize: min(constraints.maxWidth * 0.065, maxTitleFontSize),
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),

                  // DESCRIPCIÓN
                  Text(
                    'Introduce tu correo electrónico y te enviaremos un enlace seguro para restablecer tu contraseña.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: min(constraints.maxWidth * 0.045, maxSubtitleFontSize),
                      color: Colors.teal[600],
                    ),
                  ),
                  SizedBox(height: size.height * 0.04),

                  // CAMPO DE CORREO
                  TextFormField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.teal),
                      labelText: 'Correo electrónico',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) => email = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu correo';
                      }
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Ingresa un correo válido';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: size.height * 0.04),

                  // BOTÓN ENVIAR ENLACE
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    label: const Text(
                      'Enviar enlace',
                      style: TextStyle(fontSize: maxButtonTextFontSize, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[600],
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, min(size.height * 0.07, 50.0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 4,
                    ),
                    onPressed: isLoading ? null : _recoverPassword,
                  ),
                  const SizedBox(height: 20),

                  // BOTÓN REGRESAR AL LOGIN
                  TextButton.icon(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                    icon: const Icon(Icons.arrow_back, color: Colors.teal),
                    label: const Text(
                      'Volver al inicio de sesión',
                      style: TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

          // OVERLAY DE LOADING
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
