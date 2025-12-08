import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kanante_app/screens/shared/chat_screen.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:kanante_app/models/user_model.dart';
import 'package:kanante_app/data/faq_data.dart';
import 'privacy_policy_screen.dart';
import 'feedback_form_screen.dart';
import 'faq_screen.dart';
import 'my_support_tickets_screen.dart'; // New import
import 'about_us_screen.dart'; // New import

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _currentUserRole = 'Usuario'; // Default role

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      UserModel? userProfile = await _firebaseService.getUserProfile(user.uid);
      if (userProfile != null && mounted) {
        setState(() {
          _currentUserRole = userProfile.accountType;
        });
      }
    }
  }

  void _navigateToChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para contactar a soporte.')),
      );
      return;
    }

    UserModel? userProfile = await _firebaseService.getUserProfile(user.uid);

    if (userProfile != null) {
      final chatId = await _firebaseService.getOrCreateSupportChat(user.uid, userProfile.name, userProfile.accountType);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUserName: 'Soporte Kananté',
              otherUserId: 'support_admin',
              otherUserImageUrl: null,
            ),
          ),
        );
      }
    } else {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cargar tu perfil de usuario.')),
        );
      }
    }
  }

  Map<String, List<Map<String, String>>> _getFaqDataForRole() {
    switch (_currentUserRole) {
      case 'Profesional':
        return FaqData.forProfessional;
      case 'Admin':
        // Admins will have their own FAQ access point from their dashboard
        return FaqData.forAdmin; 
      default: // Usuario
        return FaqData.forUser;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material( // Added Material widget
      type: MaterialType.transparency, // Use transparency to avoid visual changes
      child: Center( // Added Center
        child: ConstrainedBox( // Added ConstrainedBox
          constraints: const BoxConstraints(maxWidth: 800.0), // Set max width
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSupportCard(
                context,
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Contactar a Soporte',
                subtitle: 'Inicia un chat en vivo con nuestro equipo de soporte.',
                onTap: _navigateToChat,
              ),
              const SizedBox(height: 16),
              _buildSupportCard(
                context,
                icon: Icons.feedback_outlined,
                title: 'Enviar Queja o Sugerencia',
                subtitle: 'Tu opinión nos ayuda a mejorar la aplicación.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FeedbackFormScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSupportCard(
                context,
                icon: Icons.receipt_long, // New icon
                title: 'Mis Tickets de Soporte', // New title
                subtitle: 'Revisa el estado de tus quejas y sugerencias.', // New subtitle
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MySupportTicketsScreen()), // Navigate to new screen
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSupportCard(
                context,
                icon: Icons.question_answer_outlined,
                title: 'Preguntas Frecuentes',
                subtitle: 'Encuentra respuestas a tus dudas más comunes.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FaqScreen(faqData: _getFaqDataForRole())),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSupportCard(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Política de Privacidad',
                subtitle: 'Lee cómo manejamos tus datos.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                  );
                },
              ),
              const SizedBox(height: 16), // New SizedBox for spacing
              _buildSupportCard( // New About Us Card
                context,
                icon: Icons.info_outline,
                title: 'Sobre Nosotros',
                subtitle: 'Conoce la historia y misión de Kananté.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutUsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.teal),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
