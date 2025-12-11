import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kanante_app/screens/admin/admin_dashboard.dart';
import 'package:kanante_app/screens/professional/professional_dashboard.dart';
import 'package:kanante_app/screens/user/user_dashboard.dart';
import 'package:kanante_app/screens/welcome_screen.dart';
import 'package:kanante_app/services/firebase_service.dart';

import '../../models/user_model.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // User is not logged in
        if (!snapshot.hasData) {
          return const WelcomeScreen();
        }

        // User is logged in, check role
        return RoleBasedRedirect(userId: snapshot.data!.uid);
      },
    );
  }
}

class RoleBasedRedirect extends StatefulWidget {
  final String userId;

  const RoleBasedRedirect({super.key, required this.userId});

  @override
  State<RoleBasedRedirect> createState() => _RoleBasedRedirectState();
}

class _RoleBasedRedirectState extends State<RoleBasedRedirect> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _firebaseService.getUserProfile(widget.userId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!userSnapshot.hasData || userSnapshot.data == null) {
          debugPrint('AuthWrapper: User profile data not found or null for userId: ${widget.userId}');
          // This could happen if the user is authenticated but their DB entry is gone.
          // Or if there's a network error.
          // Sending to welcome screen is a safe fallback.
          return const WelcomeScreen();
        }

        final user = userSnapshot.data!;
        debugPrint('AuthWrapper: User profile found. User ID: ${user.id}, Account Type: ${user.accountType}');
        switch (user.accountType) {
          case 'admin':
            debugPrint('AuthWrapper: Navigating to AdminDashboard for user ID: ${user.id}');
            return const AdminDashboard();
          case 'professional':
            debugPrint('AuthWrapper: Navigating to ProfessionalDashboard for user ID: ${user.id}');
            return const ProfessionalDashboard();
          case 'user':
            debugPrint('AuthWrapper: Navigating to UserDashboard for user ID: ${user.id}');
            return const UserDashboard();
          default:
            debugPrint('AuthWrapper: Unknown account type "${user.accountType}" for user ID: ${user.id}. Navigating to WelcomeScreen.');
            return const WelcomeScreen(); // Fallback for unknown roles
        }
      },
    );
  }
}