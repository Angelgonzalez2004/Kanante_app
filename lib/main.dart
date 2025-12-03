import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; // New import
import 'firebase_options.dart';

import 'screens/splash_screen.dart'; // Import the new splash screen
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/recover_password_screen.dart';

// Declarar esto en main.dart
ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es'); // Initialize for Spanish locale, assuming 'es' is the primary locale
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier, // desde main.dart
      builder: (context, currentTheme, _) {
        return MaterialApp(
          title: 'Kananté',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            textTheme: const TextTheme(
              titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              bodyLarge: TextStyle(fontSize: 16),
              bodyMedium: TextStyle(fontSize: 14),
              bodySmall: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              centerTitle: true,
              elevation: 4,
            ),

          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
            textTheme: const TextTheme(
              titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white70),
              bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
              bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
              bodySmall: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.teal[700],
              foregroundColor: Colors.white,
              centerTitle: true,
              elevation: 4,
            ),

          ),
          themeMode: currentTheme,
          home: const SplashScreen(), // Set SplashScreen as the initial home widget
          routes: {
            // '/': (context) => const WelcomeScreen(), // SplashScreen handles initial navigation
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/recover': (context) => const RecoverPasswordScreen(),
            '/welcome': (context) => const WelcomeScreen(), // Add welcome screen as a named route if needed later
          },
        );
      },
    );
  }
}

