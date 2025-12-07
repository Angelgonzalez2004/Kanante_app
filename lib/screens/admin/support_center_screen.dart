import 'package:flutter/material.dart';
import 'package:kanante_app/models/chat_model.dart';
import 'package:kanante_app/models/support_ticket_model.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:kanante_app/screens/shared/chat_screen.dart';
import 'support_ticket_detail_screen.dart';
import 'package:intl/intl.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de Soporte'),
        backgroundColor: Colors.indigo,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: 'Chats'),
            Tab(icon: Icon(Icons.feedback), text: 'Quejas y Sugerencias'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SupportChatsTab(),
          SupportTicketsTab(),
        ],
      ),
    );
  }
}

class SupportChatsTab extends StatelessWidget {
  const SupportChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();
    return StreamBuilder<List<ChatConversation>>(
      stream: firebaseService.getSupportChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay chats de soporte.'));
        }
        final chats = snapshot.data!;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900.0), // Max width for list on large screens
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(chat.otherParticipantName ?? 'Usuario Desconocido'),
                  subtitle: Text(chat.lastMessage),
                  trailing: Text(DateFormat('dd/MM/yy').format(chat.timestamp)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: chat.id,
                          otherUserName: chat.otherParticipantName ?? 'Usuario de Soporte',
                          otherUserId: chat.participants.firstWhere((id) => id != 'support_admin', orElse: () => ''),
                          otherUserImageUrl: null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class SupportTicketsTab extends StatelessWidget {
  const SupportTicketsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();
    return StreamBuilder<List<SupportTicket>>(
      stream: firebaseService.getSupportTickets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay tickets de soporte.'));
        }
        final tickets = snapshot.data!;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900.0), // Max width for list on large screens
            child: ListView.builder(
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return ListTile(
                  leading: Icon(ticket.status == 'open' ? Icons.folder_open : Icons.folder, color: ticket.status == 'open' ? Colors.blue : Colors.grey),
                  title: Text(ticket.subject),
                  subtitle: Text('De: ${ticket.userName ?? 'Anónimo'}'),
                  trailing: Text(DateFormat('dd/MM/yy').format(ticket.createdAt)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SupportTicketDetailScreen(ticket: ticket),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
