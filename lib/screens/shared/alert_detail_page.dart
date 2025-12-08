import 'package:flutter/material.dart';
import 'package:kanante_app/models/alert_model.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:intl/intl.dart';

class AlertDetailPage extends StatefulWidget {
  final AlertModel alert;
  const AlertDetailPage({super.key, required this.alert});

  @override
  State<AlertDetailPage> createState() => _AlertDetailPageState();
}

class _AlertDetailPageState extends State<AlertDetailPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final _replyController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _markAsRead() async {
    if (widget.alert.status == 'unread') {
      try {
        await _firebaseService.markAlertAsRead(widget.alert.id);
        widget.alert.status = 'read'; // Update local status
      } catch (e) {
        // Log error but don't block user
        debugPrint("Error marking alert as read: $e");
      }
    }
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) {
      _showSnackBar('Por favor, escribe una respuesta.', isError: true);
      return;
    }
    setState(() => _isLoading = true);

    try {
      await _firebaseService.replyToAlert(
        widget.alert.id,
        _replyController.text.trim(),
        'replied',
      );
      _showSnackBar('Respuesta enviada.');
      if(mounted) {
        // Update local state to reflect the reply
        setState(() {
            widget.alert.recipientReply = _replyController.text.trim();
            widget.alert.replyTimestamp = DateTime.now();
            widget.alert.status = 'replied';
        });
      }
    } catch (e) {
      _showSnackBar('Error al enviar respuesta: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alert.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.alert.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enviado: ${DateFormat('dd/MM/yyyy, hh:mm a').format(widget.alert.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 32),
            Text(
              widget.alert.message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Divider(height: 32),
            _buildReplySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildReplySection() {
    // If a reply has already been sent, show it in a read-only format.
    if (widget.alert.recipientReply != null) {
      return Card(
        color: Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu Respuesta:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(widget.alert.recipientReply!),
              const SizedBox(height: 8),
              Text(
                'Respondido: ${DateFormat('dd/MM/yyyy, hh:mm a').format(widget.alert.replyTimestamp!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    // Otherwise, show the reply input form.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escribe tu respuesta',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _replyController,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Tu respuesta al administrador...',
          ),
        ),
        const SizedBox(height: 16),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ElevatedButton.icon(
                  onPressed: _sendReply,
                  icon: const Icon(Icons.send),
                  label: const Text('Enviar Respuesta'),
                ),
              ),
      ],
    );
  }
}
