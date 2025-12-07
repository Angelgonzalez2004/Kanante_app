import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/recover_password_screen.dart';

// Variable global para el manejo del tema
ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- CORRECCIÓN AQUÍ ---
  // Se usa playIntegrity porque ya registraste la huella SHA-256 en Firebase.
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest, 
  );
  // -----------------------

  await initializeDateFormatting('es'); // Inicializar formato de fecha en español
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier, 
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
          home: const SplashScreen(), // SplashScreen es la pantalla inicial
          routes: {
            // '/welcome' no es necesario si SplashScreen redirige, pero lo dejo por si acaso
            '/welcome': (context) => const WelcomeScreen(), 
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/recover': (context) => const RecoverPasswordScreen(),
          },
        );
      },
    );
  }
}