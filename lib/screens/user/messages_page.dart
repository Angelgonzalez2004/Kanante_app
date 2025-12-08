import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart'; // Import UserModel
import '../../services/firebase_service.dart';
import '../shared/chat_screen.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> with SingleTickerProviderStateMixin {
  late final FirebaseService _firebaseService;
  late Future<List<ChatConversation>> _conversationsFuture;
  late Future<List<UserModel>> _professionalsFuture; // New future for professionals
  late TabController _tabController; // Tab controller

  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseService();
    _conversationsFuture = _fetchConversations();
    _professionalsFuture = _fetchProfessionals(); // Fetch professionals
    _tabController = TabController(length: 2, vsync: this); // Initialize TabController
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<ChatConversation>> _fetchConversations() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception("Usuario no autenticado.");
    }
    return _firebaseService.getConversationsForUser(userId);
  }

  Future<List<UserModel>> _fetchProfessionals() async {
    // Users can only chat with health professionals.
    // Assuming 'Profesional' is the account type for health professionals.
    final professionals = await _firebaseService.getAllProfessionals();
    return professionals; // Filtered to only 'Profesional' by the service
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mensajes',
                  style: TextStyle(
                    fontSize: size.width * 0.06,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: size.height * 0.02),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.teal,
                  labelColor: Colors.teal,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'Chats'),
                    Tab(text: 'Contactos'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Chats Tab Content
                      FutureBuilder<List<ChatConversation>>(
                        future: _conversationsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No tienes conversaciones.'));
                          }

                          final conversations = snapshot.data!;
                          return ListView.builder(
                            itemCount: conversations.length,
                            itemBuilder: (context, index) {
                              final conversation = conversations[index];
                              return _messageCard(conversation);
                            },
                          );
                        },
                      ),
                      // Contactos Tab Content
                      FutureBuilder<List<UserModel>>(
                        future: _professionalsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No hay profesionales disponibles.'));
                          }

                          final professionals = snapshot.data!;
                          final currentUserId = FirebaseAuth.instance.currentUser!.uid;

                          return ListView.builder(
                            itemCount: professionals.length,
                            itemBuilder: (context, index) {
                              final professional = professionals[index];
                              // Exclude self from the contacts list
                              if (professional.id == currentUserId) return const SizedBox.shrink();

                              return _contactCard(professional);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _messageCard(ChatConversation conversation) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          backgroundImage: conversation.otherParticipantImageUrl != null
              ? CachedNetworkImageProvider(conversation.otherParticipantImageUrl!)
              : null,
          child: conversation.otherParticipantImageUrl == null
              ? const Icon(Icons.person, color: Colors.teal)
              : null,
        ),
        title: Text(
          conversation.otherParticipantName ?? 'Usuario Desconocido',
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis, // Handle long names
        ),
        subtitle: Text(
          conversation.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chat_bubble_outline, color: Colors.teal),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: conversation.id,
                otherUserName: conversation.otherParticipantName ?? 'Usuario Desconocido',
                otherUserId: conversation.participants.firstWhere((id) => id != FirebaseAuth.instance.currentUser!.uid),
                otherUserImageUrl: conversation.otherParticipantImageUrl,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _contactCard(UserModel professional) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          backgroundImage: professional.profileImageUrl != null
              ? CachedNetworkImageProvider(professional.profileImageUrl!)
              : null,
          child: professional.profileImageUrl == null
              ? const Icon(Icons.person, color: Colors.teal)
              : null,
        ),
        title: Text(
          professional.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          professional.specialties.join(', '), // Display specialties
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chat, color: Colors.teal),
        onTap: () async {
          final currentUserId = FirebaseAuth.instance.currentUser!.uid;
          final chatId = await _firebaseService.getOrCreateChat(currentUserId, professional.id);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: chatId,
                otherUserName: professional.name,
                otherUserId: professional.id,
                otherUserImageUrl: professional.profileImageUrl,
              ),
            ),
          );
        },
      ),
    );
  }
}
