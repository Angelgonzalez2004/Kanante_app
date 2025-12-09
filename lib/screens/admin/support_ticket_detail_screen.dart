import 'package:flutter/material.dart';
import 'package:kanante_app/models/support_ticket_model.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:kanante_app/models/user_model.dart'; // New import for UserModel

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

  String _currentStatus = '';
  String _currentPriority = '';
  String? _currentAssignedTo;
  List<UserModel> _adminUsers = []; // To store list of admin users
  String? _assignedAdminName;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.ticket.status;
    _currentPriority = widget.ticket.priority;
    _currentAssignedTo = widget.ticket.assignedTo;
    if (widget.ticket.adminResponse != null) {
      _responseController.text = widget.ticket.adminResponse!;
    }
    _loadAdminUsers();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminUsers() async {
    final admins = await _firebaseService.getAllUsers(searchQuery: 'Admin'); // Assuming accountType 'Admin'
    // Filter to only get actual admins, as searchQuery might match name too
    _adminUsers = admins.where((user) => user.accountType == 'Admin').toList();

    if (_currentAssignedTo != null) {
      final assignedAdmin = _adminUsers.firstWhere((admin) => admin.id == _currentAssignedTo, orElse: () => UserModel(id: 'unknown', name: 'Desconocido', email: 'unknown', accountType: 'Admin'));
      if (assignedAdmin.id != 'unknown') {
        _assignedAdminName = assignedAdmin.name;
      }
    }
    setState(() {}); // Refresh UI
  }

  Future<void> _updateTicketDetails() async {
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> updates = {
        'status': _currentStatus,
        'priority': _currentPriority,
        'assignedTo': _currentAssignedTo,
      };
      if (_responseController.text.trim().isNotEmpty) {
        updates['adminResponse'] = _responseController.text.trim();
        updates['respondedAt'] = DateTime.now().millisecondsSinceEpoch;
      }

      await _firebaseService.updateSupportTicketDetails(widget.ticket.ticketId, updates);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Detalles del ticket actualizados.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar ticket: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitResponse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _currentStatus = 'closed'; // Mark as closed when submitting response
    await _updateTicketDetails();

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool canRespond = widget.ticket.userId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticket.subject),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateTicketDetails,
            tooltip: 'Guardar Cambios',
          ),
        ],
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
                _buildDetailItem('Fecha Creación', DateFormat('dd/MM/yyyy, HH:mm').format(widget.ticket.createdAt)),
                _buildDetailItem('ID Ticket', widget.ticket.ticketId),
                _buildDetailItem('ID Usuario', widget.ticket.userId ?? 'N/A'),
                const Divider(height: 30),
                _buildSectionTitle('Gestionar Ticket'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildStatusDropdown()),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPriorityDropdown()),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAssignedToDropdown(),
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
                          readOnly: _currentStatus == 'closed', // Use current status
                        ),
                        const SizedBox(height: 16),
                        if (_currentStatus != 'closed') // Use current status
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

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _currentStatus,
      decoration: const InputDecoration(
        labelText: 'Estado del Ticket',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'open', child: Text('Abierto')),
        DropdownMenuItem(value: 'in_progress', child: Text('En Progreso')),
        DropdownMenuItem(value: 'closed', child: Text('Cerrado')),
      ],
      onChanged: (value) {
        setState(() {
          _currentStatus = value ?? 'open';
        });
      },
    );
  }

  Widget _buildPriorityDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _currentPriority,
      decoration: const InputDecoration(
        labelText: 'Prioridad',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'low', child: Text('Baja')),
        DropdownMenuItem(value: 'medium', child: Text('Media')),
        DropdownMenuItem(value: 'high', child: Text('Alta')),
      ],
      onChanged: (value) {
        setState(() {
          _currentPriority = value ?? 'medium';
        });
      },
    );
  }

  Widget _buildAssignedToDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _currentAssignedTo,
      decoration: InputDecoration(
        labelText: 'Asignar a',
        border: const OutlineInputBorder(),
        hintText: _assignedAdminName ?? 'Seleccionar Admin',
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Nadie')),
        ..._adminUsers.map((admin) => DropdownMenuItem(
          value: admin.id,
          child: Text(admin.name),
        )),
      ],
      onChanged: (value) {
        setState(() {
          _currentAssignedTo = value;
          _assignedAdminName = _adminUsers.firstWhere((admin) => admin.id == value, orElse: () => UserModel(id: 'unknown', name: 'Nadie', email: 'unknown', accountType: 'Admin')).name;
        });
      },
    );
  }
}

