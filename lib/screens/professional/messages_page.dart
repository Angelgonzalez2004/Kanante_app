import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../services/firebase_service.dart';
import '../shared/chat_screen.dart';
import 'select_chat_participants_page.dart'; // New import

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  late final FirebaseService _firebaseService;
  late Future<List<ChatConversation>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseService();
    _conversationsFuture = _fetchConversations();
  }

  Future<List<ChatConversation>> _fetchConversations() async {
    final professionalId = FirebaseAuth.instance.currentUser?.uid;
    if (professionalId == null) {
      throw Exception("Profesional no autenticado.");
    }
    return _firebaseService.getConversationsForProfessional(professionalId);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Padding(
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
            Expanded(
              child: FutureBuilder<List<ChatConversation>>(
                future: _conversationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No tienes mensajes.'));
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
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'newChatFab', // Unique tag
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SelectChatParticipantsPage()),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add_comment, color: Colors.white),
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
}