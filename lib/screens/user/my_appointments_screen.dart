import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../services/firebase_service.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Appointment>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      // Handle user not being logged in
      setState(() {
        _appointmentsFuture = Future.value([]);
      });
      return;
    }
    setState(() {
      _appointmentsFuture = _firebaseService.getAppointmentsForUser(userId);
    });
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Cita'),
        content: const Text('¿Estás seguro de que quieres cancelar esta cita?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firebaseService.updateAppointmentStatus(appointmentId, 'cancelled');
        if (!mounted) return; // Add this line
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita cancelada.')),
        );
        _loadAppointments(); // Refresh the list
      } catch (e) {
        if (!mounted) return; // Add this line
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cancelar la cita: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _loadAppointments(),
        child: FutureBuilder<List<Appointment>>(
          future: _appointmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error al cargar las citas.'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No tienes citas solicitadas.', style: TextStyle(fontSize: 16, color: Colors.grey)),
              );
            }

            final appointments = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                return _buildAppointmentCard(appointments[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final formattedDate = DateFormat('d MMMM, y', 'es_MX').format(appointment.dateTime);
    final formattedTime = DateFormat('h:mm a', 'es_MX').format(appointment.dateTime);

    Icon statusIcon;
    Color statusColor;
    String statusText;

    switch (appointment.status) {
      case 'pending':
        statusIcon = const Icon(Icons.hourglass_top_rounded, color: Colors.orange);
        statusColor = Colors.orange;
        statusText = 'Pendiente';
        break;
      case 'confirmed':
        statusIcon = const Icon(Icons.check_circle_rounded, color: Colors.green);
        statusColor = Colors.green;
        statusText = 'Confirmada';
        break;
      case 'rejected':
        statusIcon = const Icon(Icons.cancel_rounded, color: Colors.red);
        statusColor = Colors.red;
        statusText = 'Rechazada';
        break;
      default:
        statusIcon = const Icon(Icons.help_outline_rounded, color: Colors.grey);
        statusColor = Colors.grey;
        statusText = 'Desconocido';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.1),
            child: statusIcon,
          ),
          title: Text(
            appointment.professionalName ?? 'Profesional no encontrado',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('$formattedDate - $formattedTime'),
          trailing: (appointment.status == 'pending' || appointment.status == 'confirmed')
              ? TextButton(
                  child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                  onPressed: () => _cancelAppointment(appointment.id),
                )
              : Chip(
                  label: Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: statusColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                ),
        ),
      ),
    );
  }
}