import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/user_model.dart';

class VerificationDetailPage extends StatefulWidget {
  final String professionalId;
  const VerificationDetailPage({super.key, required this.professionalId});

  @override
  State<VerificationDetailPage> createState() => _VerificationDetailPageState();
}

class _VerificationDetailPageState extends State<VerificationDetailPage> {
  final _db = FirebaseDatabase.instance.ref();
  UserModel? _professional;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfessionalDetails();
  }

  Future<void> _fetchProfessionalDetails() async {
    try {
      final snapshot = await _db.child('users').child(widget.professionalId).get();
      if (snapshot.exists) {
        setState(() {
          _professional = UserModel.fromMap(snapshot.key!, Map<String, dynamic>.from(snapshot.value as Map));
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        // Handle user not found
      }
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Handle error, maybe show a snackbar
    }
  }

  Future<void> _updateVerificationStatus(String status, {String? notes}) async {
    if (_professional == null) return;
    setState(() => _isLoading = true);
    try {
      await _db.child('users').child(_professional!.id).update({
        'verificationStatus': status,
        'verificationNotes': notes, // This will be null for approval, clearing any previous notes
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El profesional ha sido ${status == 'verified' ? 'aprobado' : 'rechazado'}.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el estado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _approveVerification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar Verificación'),
        content: const Text('¿Estás seguro de que quieres aprobar a este profesional?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateVerificationStatus('verified');
            },
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
  }

  void _rejectVerification() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Verificación'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Motivo del rechazo',
            hintText: 'Escribe una breve explicación...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.of(context).pop();
              _updateVerificationStatus('rejected', notes: reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_professional?.name ?? 'Detalle de Verificación'),
        backgroundColor: Colors.indigo,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _professional == null
              ? const Center(child: Text('No se pudo cargar el profesional.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailCard(),
                      const SizedBox(height: 20),
                      _buildDocumentsCard(),
                      const SizedBox(height: 30),
                      _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(_professional!.name),
              subtitle: const Text('Nombre Completo'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(_professional!.email),
              subtitle: const Text('Correo Electrónico'),
            ),
            if(_professional!.phone != null && _professional!.phone!.isNotEmpty) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(_professional!.phone!),
                subtitle: const Text('Teléfono'),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsCard() {
    final documents = _professional!.verificationDocuments ?? [];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documentos de Verificación', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (documents.isEmpty)
              const Text('No hay documentos subidos.'),
            ...documents.map((docUrl) {
              return ListTile(
                leading: const Icon(Icons.description, color: Colors.blueGrey),
                title: Text(Uri.decodeFull(docUrl.split('/').last.split('?').first).substring(0, 20) + '...', overflow: TextOverflow.ellipsis),
                trailing: ElevatedButton(
                  child: const Text('Ver'),
                  onPressed: () => _launchURL(docUrl),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _rejectVerification,
          icon: const Icon(Icons.close),
          label: const Text('Rechazar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
        ),
        ElevatedButton.icon(
          onPressed: _approveVerification,
          icon: const Icon(Icons.check),
          label: const Text('Aprobar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
        ),
      ],
    );
  }
}
