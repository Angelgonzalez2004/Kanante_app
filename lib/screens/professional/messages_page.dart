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
  late Future<List<UserModel>> _normalUsersFuture; // New future for normal users
  late TabController _tabController; // Tab controller

  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseService();
    _conversationsFuture = _fetchConversations();
    _normalUsersFuture = _fetchNormalUsers(); // Fetch normal users
    _tabController = TabController(length: 2, vsync: this); // Initialize TabController
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<ChatConversation>> _fetchConversations() async {
    final professionalId = FirebaseAuth.instance.currentUser?.uid;
    if (professionalId == null) {
      throw Exception("Profesional no autenticado.");
    }
    return _firebaseService.getConversationsForProfessional(professionalId);
  }

  Future<List<UserModel>> _fetchNormalUsers() async {
    // Professionals can only chat with normal users.
    final users = await _firebaseService.getAllUsers();
    return users.where((user) => user.accountType == 'Usuario').toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Center(
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
                      future: _normalUsersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('No hay usuarios normales disponibles.'));
                        }

                        final normalUsers = snapshot.data!;
                        final currentUserId = FirebaseAuth.instance.currentUser!.uid;

                        return ListView.builder(
                          itemCount: normalUsers.length,
                          itemBuilder: (context, index) {
                            final user = normalUsers[index];
                            // Exclude self from the contacts list
                            if (user.id == currentUserId) return const SizedBox.shrink();

                            return _contactCard(user);
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

  Widget _contactCard(UserModel user) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          backgroundImage: user.profileImageUrl != null
              ? CachedNetworkImageProvider(user.profileImageUrl!)
              : null,
          child: user.profileImageUrl == null
              ? const Icon(Icons.person, color: Colors.teal)
              : null,
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          user.accountType, // Display account type
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chat, color: Colors.teal),
        onTap: () async {
          final currentUserId = FirebaseAuth.instance.currentUser!.uid;
          final chatId = await _firebaseService.getOrCreateChat(currentUserId, user.id);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: chatId,
                otherUserName: user.name,
                otherUserId: user.id,
                otherUserImageUrl: user.profileImageUrl,
              ),
            ),
          );
        },
      ),
    );
  }
}