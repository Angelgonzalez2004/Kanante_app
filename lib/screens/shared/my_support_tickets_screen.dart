import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kanante_app/models/support_ticket_model.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:intl/intl.dart';

class MySupportTicketsScreen extends StatefulWidget {
  const MySupportTicketsScreen({super.key});

  @override
  State<MySupportTicketsScreen> createState() => _MySupportTicketsScreenState();
}

class _MySupportTicketsScreenState extends State<MySupportTicketsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Debes iniciar sesión para ver tus tickets.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tickets de Soporte'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800.0),
          child: StreamBuilder<List<SupportTicket>>(
            stream: _firebaseService.getSupportTickets(), // This gets all, need to filter
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No tienes tickets de soporte enviados.'));
              }

              final userTickets = snapshot.data!
                  .where((ticket) => ticket.userId == currentUser.uid)
                  .toList();

              if (userTickets.isEmpty) {
                return const Center(child: Text('No tienes tickets de soporte enviados.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: userTickets.length,
                itemBuilder: (context, index) {
                  final ticket = userTickets[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(
                        ticket.status == 'open'
                            ? Icons.hourglass_empty
                            : ticket.status == 'closed'
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                        color: ticket.status == 'open' ? Colors.orange : Colors.green,
                      ),
                      title: Text(ticket.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estado: ${ticket.status == 'open' ? 'Abierto' : 'Cerrado'}'),
                          Text('Enviado el: ${DateFormat('dd/MM/yyyy').format(ticket.createdAt)}'),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Navigate to a detail screen for this ticket
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SupportTicketUserDetailScreen(ticket: ticket),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class SupportTicketUserDetailScreen extends StatelessWidget {
  final SupportTicket ticket;
  const SupportTicketUserDetailScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ticket.subject),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800.0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('Asunto', ticket.subject),
                _buildDetailItem('Estado', ticket.status == 'open' ? 'Abierto' : 'Cerrado'),
                _buildDetailItem('Enviado por', ticket.userName ?? 'Anónimo'),
                _buildDetailItem('Rol del Usuario', ticket.userRole ?? 'N/A'),
                _buildDetailItem('Fecha de Envío', DateFormat('dd/MM/yyyy, HH:mm').format(ticket.createdAt)),
                const Divider(height: 30),
                _buildSectionTitle('Mensaje Original'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(ticket.message),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Respuesta del Soporte'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueGrey.shade200),
                  ),
                  child: Text(
                    ticket.adminResponse ?? 'Aún no hay respuesta del equipo de soporte.',
                    style: TextStyle(fontStyle: ticket.adminResponse == null ? FontStyle.italic : null),
                  ),
                ),
                if (ticket.respondedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Respondido el: ${DateFormat('dd/MM/yyyy, HH:mm').format(ticket.respondedAt!)}',
                      style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
