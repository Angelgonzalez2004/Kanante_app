import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kanante_app/models/alert_model.dart';
import 'package:kanante_app/models/user_model.dart';
import 'package:kanante_app/services/firebase_service.dart';

class SendAlertScreen extends StatefulWidget {
  final UserModel recipientUser;
  const SendAlertScreen({super.key, required this.recipientUser});

  @override
  State<SendAlertScreen> createState() => _SendAlertScreenState();
}

class _SendAlertScreenState extends State<SendAlertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
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

  Future<void> _sendAlert() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showSnackBar('Error: Administrador no autenticado.', isError: true);
        return;
      }

      final alert = AlertModel(
        id: '', // Firebase will generate this
        senderId: currentUser.uid,
        recipientId: widget.recipientUser.id,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        timestamp: DateTime.now(),
        status: 'unread',
      );

      await _firebaseService.sendAlert(alert);

      _showSnackBar('Alerta enviada a ${widget.recipientUser.name}.', duration: const Duration(seconds: 3));
      if (mounted) {
        Navigator.pop(context); // Go back to account management page
      }
    } catch (e) {
      _showSnackBar('Error al enviar alerta: $e', isError: true);
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
        title: Text('Enviar Alerta a ${widget.recipientUser.name}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enviando una alerta a: ${widget.recipientUser.name} (${widget.recipientUser.email})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título de la Alerta',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warning_amber),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'El título es requerido.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje de la Alerta',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                    ),
                    maxLines: 5,
                    validator: (value) => value == null || value.isEmpty ? 'El mensaje es requerido.' : null,
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: _sendAlert,
                          icon: const Icon(Icons.send),
                          label: const Text('Enviar Alerta'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}