import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kanante_app/models/user_model.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:kanante_app/screens/professional/profile_page.dart'; // Reusing existing profile page for details
import 'package:kanante_app/screens/professional/professional_publications_list_screen.dart'; // New screen for publications list
import 'package:kanante_app/screens/shared/chat_screen.dart'; // Chat screen

class ProfessionalProfileViewerPage extends StatefulWidget {
  final String professionalUid;

  const ProfessionalProfileViewerPage({super.key, required this.professionalUid});

  @override
  State<ProfessionalProfileViewerPage> createState() => _ProfessionalProfileViewerPageState();
}

class _ProfessionalProfileViewerPageState extends State<ProfessionalProfileViewerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _currentAppUser; // Current logged-in user of the app
  UserModel? _viewingProfessional; // The professional whose profile is being viewed
  bool _isLoading = true;
  String? _chatId; // To store the chat ID for the message tab

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Increased length to 3
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      _currentAppUser = await _firebaseService.getUserProfile(firebaseUser.uid);
      if (_currentAppUser != null && _currentAppUser!.id != widget.professionalUid) {
        _chatId = await _firebaseService.getOrCreateChat(_currentAppUser!.id, widget.professionalUid);
      }
    }
    _viewingProfessional = await _firebaseService.getUserProfile(widget.professionalUid);
    setState(() => _isLoading = false);
  }

  // No longer needed as chat is now a tab
  // bool get _canMessageProfessional {
  //   return _currentAppUser != null &&
  //          _viewingProfessional != null &&
  //          _currentAppUser!.accountType == 'Usuario' && // Only normal users can message professionals from here
  //          _currentAppUser!.id != _viewingProfessional!.id; // Cannot message self
  // }

  // No longer needed as chat is now a tab
  // void _startChatWithProfessional() async {
  //   if (_currentAppUser == null || _viewingProfessional == null) return;

  //   final chatId = await _firebaseService.getOrCreateChat(_currentAppUser!.id, _viewingProfessional!.id);
  //   if (!mounted) return;

  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => ChatScreen(
  //         chatId: chatId,
  //         otherUserName: _viewingProfessional!.name,
  //         otherUserId: _viewingProfessional!.id,
  //         otherUserImageUrl: _viewingProfessional!.profileImageUrl,
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_viewingProfessional == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil no encontrado')),
        body: const Center(child: Text('No se pudo cargar la información del profesional.')),
      );
    }

    // Determine if the current user is a normal user trying to message a professional (not self)
    final bool isUserAndNotSelf = _currentAppUser != null &&
                                  _currentAppUser!.accountType == 'Usuario' &&
                                  _currentAppUser!.id != _viewingProfessional!.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(_viewingProfessional!.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Publicaciones', icon: Icon(Icons.article)),
            Tab(text: 'Perfil', icon: Icon(Icons.person)),
            Tab(text: 'Mensajes', icon: Icon(Icons.message)), // New Messages Tab
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Publicaciones
          ProfessionalPublicationsListScreen(professionalUid: widget.professionalUid),
          // Tab 2: Perfil del profesional (usando la misma página de perfil pero en modo lectura)
          ProfessionalProfilePage(professionalUid: widget.professionalUid),
          // Tab 3: Mensajes
          Builder( // Use Builder to get a new context for ScaffoldMessenger
            builder: (BuildContext innerContext) {
              if (isUserAndNotSelf && _chatId != null) {
                return ChatScreen(
                  chatId: _chatId!,
                  otherUserName: _viewingProfessional!.name,
                  otherUserId: _viewingProfessional!.id,
                  otherUserImageUrl: _viewingProfessional!.profileImageUrl,
                  isProfessionalChat: true, // Pass true as it's a professional's profile
                );
              } else if (!isUserAndNotSelf) {
                return const Center(child: Text('No puedes enviar mensajes a este perfil.'));
              } else {
                return const Center(child: Text('Cargando chat...'));
              }
            },
          ),
        ],
      ),
      // FloatingActionButton for messaging removed, as it's now part of the tabs
      // floatingActionButton: _canMessageProfessional
      //     ? FloatingActionButton.extended(
      //         onPressed: _startChatWithProfessional,
      //         icon: const Icon(Icons.message),
      //         label: const Text('Enviar Mensaje'),
      //       )
      //     : null,
    );
  }
}
