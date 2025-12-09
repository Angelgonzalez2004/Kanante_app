// lib/screens/shared/appointments_reminder_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../services/firebase_service.dart';
import 'review_submission_screen.dart';

class AppointmentsReminderScreen extends StatefulWidget {
  const AppointmentsReminderScreen({super.key});

  @override
  State<AppointmentsReminderScreen> createState() => _AppointmentsReminderScreenState();
}

class _AppointmentsReminderScreenState extends State<AppointmentsReminderScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserAccountType;
  Future<List<Appointment>> _appointmentsFuture = Future.value([]);

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
          _appointmentsFuture = Future.value([]);
        }
      });
    }
  }
  
  void _navigateToReviewSubmission(Appointment appointment) async {
    if (_currentUserAccountType != 'Usuario') return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewSubmissionScreen(
          professionalId: appointment.professionalUid,
          professionalName: appointment.professionalName ?? 'Profesional',
          appointmentId: appointment.id,
        ),
      ),
    );

    if (result == true) { 
      _loadUserDataAndAppointments(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

                  final bool showActionButtons = appointment.status != 'cancelled' && appointment.status != 'completed';
                  final bool showReviewButton = !isProfessional && appointment.status == 'completed' && appointment.dateTime.isBefore(DateTime.now());

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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min, 
                        children: [
                          if (showActionButtons)
                            IconButton(
                              icon: const Icon(Icons.edit_calendar, color: Colors.blue), 
                              onPressed: () => _showRescheduleDialog(appointment),
                              tooltip: 'Reprogramar Cita',
                            ),
                          if (showActionButtons)
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _showCancelConfirmation(appointment),
                              tooltip: 'Cancelar Cita',
                            ),
                          if (showReviewButton)
                            IconButton(
                              icon: const Icon(Icons.star_rate_rounded, color: Colors.amber),
                              onPressed: () => _navigateToReviewSubmission(appointment),
                              tooltip: 'Dejar Reseña',
                            ),
                        ],
                      ),
                      onTap: () {
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

  Future<void> _showRescheduleDialog(Appointment appointment) async {
    // Usamos el context local actual antes de cualquier await para configurar el picker
    // pero debemos verificar mounted después.
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: appointment.dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)), 
    );

    if (pickedDate == null) return; 
    if (!mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appointment.dateTime),
    );

    if (pickedTime == null) return; 
    if (!mounted) return;

    final DateTime newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (newDateTime.isAtSameMomentAs(appointment.dateTime)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La nueva fecha y hora son idénticas a la actual.')),
      );
      return;
    }

    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Reprogramación'),
          content: Text('¿Estás seguro de que quieres reprogramar la cita con ${appointment.professionalName ?? appointment.patientName} al ${DateFormat('dd/MM/yyyy HH:mm').format(newDateTime)}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, reprogramar', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      if (!mounted) return;
      _rescheduleAppointment(appointment.id, newDateTime);
    }
  }

  Future<void> _rescheduleAppointment(String appointmentId, DateTime newDateTime) async {
    try {
      await _firebaseService.updateAppointmentDateTime(appointmentId, newDateTime);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita reprogramada con éxito.')),
        );
        setState(() {
          _appointmentsFuture = (_currentUserAccountType == 'Usuario')
              ? _firebaseService.getAppointmentsForUser(_auth.currentUser!.uid)
              : _firebaseService.getAppointmentsForProfessional(_auth.currentUser!.uid);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reprogramar la cita: $e')),
        );
      }
    }
  }

  Future<void> _showCancelConfirmation(Appointment appointment) async {
    // ELIMINADO: final navigator = Navigator.of(context); (No se usaba y causaba warning)
    
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Cancelación'),
          content: Text('¿Estás seguro de que quieres cancelar la cita con ${appointment.professionalName ?? appointment.patientName} el ${DateFormat('dd/MM/yyyy HH:mm').format(appointment.dateTime)}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, cancelar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      if (!mounted) return;
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