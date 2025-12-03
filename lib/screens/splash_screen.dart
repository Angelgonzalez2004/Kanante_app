import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math'; // Import for min function
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_screen.dart'; // login_screen is in the same directory
import 'user/user_dashboard.dart';
import 'professional/professional_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 3)); // Keep the splash screen for 3 seconds

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return; // Add this line
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    try {
      final snapshot = await FirebaseDatabase.instance.ref('users/${user.uid}/accountType').get();

      if (snapshot.exists && snapshot.value != null) {
        String accountType = snapshot.value.toString();
        if (accountType == 'Usuario') {
          if (!mounted) return; // Add this line
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UserDashboard()),
          );
        } else if (accountType == 'Profesional') {
          if (!mounted) return; // Add this line
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfessionalDashboard()),
          );
        } else {
          // If accountType is unknown, go to login
          if (!mounted) return; // Add this line
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        // If no accountType is found, go to login
        if (!mounted) return; // Add this line
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      // On error, go to login
      if (!mounted) return; // Add this line
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double maxImageSize = 300.0; // Define un tamaño máximo para la imagen
    final imageSize = min(min(size.width, size.height) * 0.4, maxImageSize);

    return Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: Image.asset(
          'assets/images/logoapp.jpg',
          width: imageSize,
          height: imageSize,
        ),
      ),
    );
  }
}
