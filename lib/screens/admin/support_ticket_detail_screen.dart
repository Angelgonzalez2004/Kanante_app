import 'package:flutter/material.dart';
import 'package:kanante_app/models/support_ticket_model.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:intl/intl.dart';

class SupportTicketDetailScreen extends StatefulWidget {
  final SupportTicket ticket;
  const SupportTicketDetailScreen({super.key, required this.ticket});

  @override
  State<SupportTicketDetailScreen> createState() => _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState extends State<SupportTicketDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _responseController = TextEditingController();
  final _firebaseService = FirebaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.ticket.adminResponse != null) {
      _responseController.text = widget.ticket.adminResponse!;
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _submitResponse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firebaseService.replyToSupportTicket(
        widget.ticket.ticketId,
        _responseController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Respuesta enviada.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar respuesta: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canRespond = widget.ticket.userId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticket.subject),
        backgroundColor: Colors.indigo,
      ),
      body: Center( // Added Center
        child: ConstrainedBox( // Added ConstrainedBox
          constraints: const BoxConstraints(maxWidth: 800.0), // Set max width
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('De', widget.ticket.userName ?? 'Anónimo'),
                _buildDetailItem('Rol', widget.ticket.userRole ?? 'N/A'),
                _buildDetailItem('Fecha', DateFormat('dd/MM/yyyy, HH:mm').format(widget.ticket.createdAt)),
                _buildDetailItem('Estado', widget.ticket.status, isStatus: true),
                const Divider(height: 30),
                _buildSectionTitle('Mensaje del Usuario'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(widget.ticket.message),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Respuesta del Administrador'),
                const SizedBox(height: 8),
                if (canRespond)
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _responseController,
                          decoration: const InputDecoration(
                            labelText: 'Escribe tu respuesta aquí...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 5,
                          validator: (value) => value == null || value.isEmpty ? 'La respuesta no puede estar vacía.' : null,
                          readOnly: widget.ticket.status == 'closed',
                        ),
                        const SizedBox(height: 16),
                        if (widget.ticket.status != 'closed')
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _submitResponse,
                            icon: const Icon(Icons.send),
                            label: const Text('Enviar Respuesta y Cerrar Ticket'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  const Text('No se puede responder a un ticket anónimo.'),
                if (widget.ticket.respondedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Respondido el: ${DateFormat('dd/MM/yyyy, HH:mm').format(widget.ticket.respondedAt!)}',
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
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              style: isStatus
                  ? TextStyle(
                      color: value == 'open' ? Colors.blue : Colors.grey,
                      fontWeight: FontWeight.bold,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
