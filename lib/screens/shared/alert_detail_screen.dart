import 'package:flutter/material.dart';
import 'package:kanante_app/models/alert_model.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:intl/intl.dart';

class AlertDetailScreen extends StatefulWidget {
  final AlertModel alert;
  const AlertDetailScreen({super.key, required this.alert});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  final _firebaseService = FirebaseService();
  final _replyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.alert.recipientReply != null) {
      _replyController.text = widget.alert.recipientReply!;
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false, Duration duration = const Duration(seconds: 2)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: duration,
      ),
    );
  }

  Future<void> _submitReply() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firebaseService.replyToAlert(
        widget.alert.id,
        _replyController.text.trim(),
        'replied', // Update status to replied
      );
      _showSnackBar('Respuesta enviada.', duration: const Duration(seconds: 3));
      if (mounted) {
        Navigator.pop(context); // Go back to alerts list
      }
    } catch (e) {
      _showSnackBar('Error al enviar respuesta: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alert.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800.0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('De', widget.alert.senderId), // Will be Admin ID, could fetch name
                _buildDetailItem('Fecha de Envío', DateFormat('dd/MM/yyyy, HH:mm').format(widget.alert.timestamp)),
                _buildDetailItem('Estado', widget.alert.status == 'unread' ? 'No leído' : widget.alert.status == 'read' ? 'Leído' : 'Respondido'),
                const Divider(height: 30),
                _buildSectionTitle('Mensaje del Administrador'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(widget.alert.message),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Tu Respuesta'),
                const SizedBox(height: 8),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _replyController,
                        decoration: const InputDecoration(
                          labelText: 'Escribe tu respuesta aquí...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        validator: (value) => value == null || value.isEmpty ? 'La respuesta no puede estar vacía.' : null,
                        readOnly: widget.alert.status == 'replied', // Cannot reply if already replied
                      ),
                      const SizedBox(height: 16),
                      if (widget.alert.status != 'replied') // Show reply button only if not yet replied
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton.icon(
                                onPressed: _submitReply,
                                icon: const Icon(Icons.reply),
                                label: const Text('Enviar Respuesta'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                    ],
                  ),
                ),
                if (widget.alert.replyTimestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Respondido el: ${DateFormat('dd/MM/yyyy, HH:mm').format(widget.alert.replyTimestamp!)}',
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