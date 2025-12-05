import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../services/firebase_service.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  late final FirebaseService _firebaseService;
  late Future<List<Appointment>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseService();
    _refreshAppointments();
  }

  void _refreshAppointments() {
    setState(() {
      _appointmentsFuture = _fetchAppointments();
    });
  }

  Future<List<Appointment>> _fetchAppointments() async {
    final professionalId = FirebaseAuth.instance.currentUser?.uid;
    if (professionalId == null) {
      throw Exception("Profesional no autenticado.");
    }
    return _firebaseService.getAppointmentsForProfessional(professionalId);
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _firebaseService.updateAppointmentStatus(appointmentId, status);
      if (!mounted) return; // Add this line
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cita ${status == 'confirmed' ? 'confirmada' : 'rechazada'}.')),
      );
      _refreshAppointments();
    } catch (e) {
      if (!mounted) return; // Add this line
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la cita: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestión de Citas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.teal, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Appointment>>(
                future: _appointmentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No hay citas programadas.'));
                  }

                  final appointments = snapshot.data!;
                  return ListView.builder(
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];
                      return _appointmentCard(appointment);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appointmentCard(Appointment appointment) {
    final formattedDate = DateFormat('d MMMM, y', 'es_MX').format(appointment.dateTime);
    final formattedTime = DateFormat('h:mm a', 'es_MX').format(appointment.dateTime);

    Widget trailingWidget;
    switch (appointment.status) {
      case 'pending':
        trailingWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: 'Aceptar',
              onPressed: () => _updateAppointmentStatus(appointment.id, 'confirmed'),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              tooltip: 'Rechazar',
              onPressed: () => _updateAppointmentStatus(appointment.id, 'rejected'),
            ),
          ],
        );
        break;
      case 'confirmed':
        trailingWidget = const Chip(label: Text('Confirmada'), backgroundColor: Colors.green, labelStyle: TextStyle(color: Colors.white));
        break;
      case 'rejected':
        trailingWidget = const Chip(label: Text('Rechazada'), backgroundColor: Colors.red, labelStyle: TextStyle(color: Colors.white));
        break;
      default:
        trailingWidget = const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade50,
          child: const Icon(Icons.calendar_today, color: Colors.teal),
        ),
        title: Text(
          appointment.patientName ?? 'Paciente Desconocido',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$formattedDate - $formattedTime'),
        trailing: trailingWidget,
      ),
    );
  }
}