import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // New import for FCM
import 'package:firebase_auth/firebase_auth.dart'; // New import for current user
import 'package:kanante_app/services/firebase_service.dart';
import 'package:kanante_app/screens/shared/auth_wrapper.dart';
import 'firebase_options.dart';

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

  // --- CÓDIGO MODIFICADO ---
  // Activamos el modo DEBUG para poder ver el token en la consola
  // y registrarlo en Firebase.
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // <--- IMPORTANTE: Modo Debug
    appleProvider: AppleProvider.debug,     // <--- IMPORTANTE: Modo Debug para iOS también
  );
  // -----------------------

  await initializeDateFormatting('es'); // Inicializar formato de fecha en español
  
  // --- FCM Token Handling ---
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseService firebaseService = FirebaseService();

  // Request permission for notifications
  NotificationSettings settings = await firebaseMessaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    debugPrint('User granted permission for notifications');
    // Get the initial FCM token
    String? token = await firebaseMessaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      // Save token to current user's profile if logged in
      auth.authStateChanges().listen((User? user) {
        if (user != null) {
          firebaseService.updateUserProfile(user.uid, {'fcmToken': token});
          debugPrint('FCM Token saved for user ${user.uid}');
        }
      });
    }

    // Listen for token refresh
    firebaseMessaging.onTokenRefresh.listen((String newToken) {
      debugPrint('FCM Token refreshed: $newToken');
      auth.authStateChanges().listen((User? user) {
        if (user != null) {
          firebaseService.updateUserProfile(user.uid, {'fcmToken': newToken});
          debugPrint('New FCM Token saved for user ${user.uid}');
        }
      });
    });
  } else {
    debugPrint('User declined or has not yet granted permission for notifications');
  }

  // --- FCM Message Handling (Flutter side) ---
  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
      // Here you might want to show a local notification or update UI
    }
  });

  // Handle interaction when the app is terminated and user taps on notification
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      debugPrint('Terminated app message: ${message.data}');
      // Handle deep linking or specific actions based on notification data
    }
  });

  // Handle interaction when the app is in background and user taps on notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('App opened from background message: ${message.data}');
    // Handle deep linking or specific actions based on notification data
  });
  // --- End FCM Message Handling ---
  
  runApp(const MyApp());
}

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling a background message: ${message.messageId}');
  // Perform any other background tasks here
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
          home: const AuthWrapper(), // AuthWrapper is the new initial screen
          routes: {
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