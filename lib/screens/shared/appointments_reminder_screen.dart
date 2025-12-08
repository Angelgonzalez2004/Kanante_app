import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../services/firebase_service.dart';

class AppointmentsReminderScreen extends StatefulWidget {
  const AppointmentsReminderScreen({super.key});

  @override
  State<AppointmentsReminderScreen> createState() => _AppointmentsReminderScreenState();
}

class _AppointmentsReminderScreenState extends State<AppointmentsReminderScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserAccountType;
  late Future<List<Appointment>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndAppointments();
  }

  Future<void> _loadUserDataAndAppointments() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final userProfile = await _firebaseService.getUserProfile(currentUser.uid);
    if (userProfile != null && mounted) {
      setState(() {
        _currentUserAccountType = userProfile.accountType;
        if (_currentUserAccountType == 'Usuario') {
          _appointmentsFuture = _firebaseService.getAppointmentsForUser(currentUser.uid);
        } else if (_currentUserAccountType == 'Profesional') {
          _appointmentsFuture = _firebaseService.getAppointmentsForProfessional(currentUser.uid);
        } else {
          _appointmentsFuture = Future.value([]); // Admins or other roles don't have appointments here
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas Agendadas'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800.0),
          child: FutureBuilder<List<Appointment>>(
            future: _appointmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error al cargar citas: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No tienes citas agendadas.'));
              }

              final appointments = snapshot.data!;
              // Sort appointments by date, soonest first
              appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  final isProfessional = _currentUserAccountType == 'Profesional';
                  final otherParticipantName = isProfessional
                      ? appointment.patientName
                      : appointment.professionalName;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                      title: Text(
                        'Cita con $otherParticipantName',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('dd/MM/yyyy HH:mm').format(appointment.dateTime)),
                          Text('Estado: ${appointment.status}', style: const TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ),
                      trailing: (appointment.status != 'cancelled' && appointment.status != 'completed')
                          ? IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _showCancelConfirmation(appointment),
                              tooltip: 'Cancelar Cita',
                            )
                          : null,
                      onTap: () {
                        // TODO: Implement navigation to appointment detail screen if needed
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Detalles de la cita con $otherParticipantName')),
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

  Future<void> _showCancelConfirmation(Appointment appointment) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Cancelación'),
          content: Text('¿Estás seguro de que quieres cancelar la cita con ${appointment.professionalName ?? appointment.patientName} el ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.dateTime)}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sí, cancelar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      _cancelAppointment(appointment.id);
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      await _firebaseService.updateAppointmentStatus(appointmentId, 'cancelled');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita cancelada con éxito.')),
        );
        // Refresh the list
        setState(() {
          _appointmentsFuture = (_currentUserAccountType == 'Usuario')
              ? _firebaseService.getAppointmentsForUser(_auth.currentUser!.uid)
              : _firebaseService.getAppointmentsForProfessional(_auth.currentUser!.uid);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cancelar la cita: $e')),
        );
      }
    }
  }
}
