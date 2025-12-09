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
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: 'Chats'),
            Tab(icon: Icon(Icons.feedback), text: 'Quejas y Sugerencias'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              SupportChatsTab(),
              SupportTicketsTab(),
            ],
          ),
        ),
      ],
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

class SupportTicketsTab extends StatefulWidget {
  const SupportTicketsTab({super.key});

  @override
  State<SupportTicketsTab> createState() => _SupportTicketsTabState();
}

class _SupportTicketsTabState extends State<SupportTicketsTab> {
  final FirebaseService firebaseService = FirebaseService();
  String _selectedStatusFilter = 'all'; // 'all', 'open', 'in_progress', 'closed'
  String _selectedPriorityFilter = 'all'; // 'all', 'low', 'medium', 'high'

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterOptions(),
        Expanded(
          child: StreamBuilder<List<SupportTicket>>(
            stream: firebaseService.getSupportTickets(
              statusFilter: _selectedStatusFilter,
              priorityFilter: _selectedPriorityFilter,
            ),
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('De: ${ticket.userName ?? 'Anónimo'} (${ticket.userRole ?? 'N/A'})'),
                            Text('Prioridad: ${ticket.priority}'),
                            Text('Asignado a: ${ticket.assignedTo ?? 'N/A'}'),
                          ],
                        ),
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
          ),
        ),
      ],
    );
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedStatusFilter,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Todos')),
                DropdownMenuItem(value: 'open', child: Text('Abiertos')),
                DropdownMenuItem(value: 'in_progress', child: Text('En Progreso')),
                DropdownMenuItem(value: 'closed', child: Text('Cerrados')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatusFilter = value ?? 'all';
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedPriorityFilter,
              decoration: const InputDecoration(
                labelText: 'Prioridad',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Todas')),
                DropdownMenuItem(value: 'low', child: Text('Baja')),
                DropdownMenuItem(value: 'medium', child: Text('Media')),
                DropdownMenuItem(value: 'high', child: Text('Alta')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPriorityFilter = value ?? 'all';
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
