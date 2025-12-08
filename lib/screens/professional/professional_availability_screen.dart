import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:time_range_picker/time_range_picker.dart';

import '../../models/user_model.dart';
import '../../services/firebase_service.dart';

class ProfessionalAvailabilityScreen extends StatefulWidget {
  const ProfessionalAvailabilityScreen({super.key});

  @override
  State<ProfessionalAvailabilityScreen> createState() => _ProfessionalAvailabilityScreenState();
}

class _ProfessionalAvailabilityScreenState extends State<ProfessionalAvailabilityScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserModel? _professionalProfile;
  bool _isLoading = true;
  final Map<String, List<TimeRange>> _dailyWorkingHours = {};
  final Map<String, List<String>> _rawDailyWorkingHours = {}; // Store as List<String> for Firebase
  int _appointmentDuration = 30; // Default to 30 minutes

  final List<String> _daysOfWeek = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfessionalProfile();
  }

  Future<void> _loadProfessionalProfile() async {
    setState(() => _isLoading = true);
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _professionalProfile = await _firebaseService.getUserProfile(currentUser.uid);
    if (_professionalProfile != null && mounted) {
      setState(() {
        _appointmentDuration = _professionalProfile!.appointmentDuration ?? 30;
        _rawDailyWorkingHours.clear();
        _dailyWorkingHours.clear();

        _professionalProfile!.workingHours?.forEach((day, times) {
          _rawDailyWorkingHours[day] = List<String>.from(times);
          _dailyWorkingHours[day] = times.map((timeRangeStr) {
            final parts = timeRangeStr.split('-');
            return TimeRange(
              startTime: TimeOfDay(
                  hour: int.parse(parts[0].split(':')[0]),
                  minute: int.parse(parts[0].split(':')[1])),
              endTime: TimeOfDay(
                  hour: int.parse(parts[1].split(':')[0]),
                  minute: int.parse(parts[1].split(':')[1])),
            );
          }).toList();
        });
      });
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickTimeRange(String day) async {
    final TimeRange? result = await showTimeRangePicker(
      context: context,
      start: const TimeOfDay(hour: 8, minute: 0),
      end: const TimeOfDay(hour: 22, minute: 0),
      // Other optional configurations
    );

    if (result != null) {
      setState(() {
        _dailyWorkingHours.update(day, (existingRanges) => existingRanges..add(result),
            ifAbsent: () => [result]);
        _rawDailyWorkingHours.update(
            day,
            (existingStrings) => existingStrings
              ..add(
                  '${result.startTime.format(context)}-${result.endTime.format(context)}'),
            ifAbsent: () => [
                  '${result.startTime.format(context)}-${result.endTime.format(context)}'
                ]);
      });
    }
  }

  void _removeTimeRange(String day, int index) {
    setState(() {
      _dailyWorkingHours[day]?.removeAt(index);
      _rawDailyWorkingHours[day]?.removeAt(index);
      if (_dailyWorkingHours[day]?.isEmpty == true) {
        _dailyWorkingHours.remove(day);
        _rawDailyWorkingHours.remove(day);
      }
    });
  }

  Future<void> _saveAvailability() async {
    setState(() => _isLoading = true);
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      await _firebaseService.updateUserProfile(currentUser.uid, {
        'workingHours': _rawDailyWorkingHours,
        'appointmentDuration': _appointmentDuration,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disponibilidad guardada con éxito.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar disponibilidad: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Disponibilidad'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveAvailability,
            tooltip: 'Guardar Disponibilidad',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Horas de Trabajo Semanales',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ..._daysOfWeek.map(_buildDayAvailability),
                      const SizedBox(height: 32),
                      Text(
                        'Duración Estándar de la Cita (minutos)',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _appointmentDuration.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duración en minutos',
                          border: OutlineInputBorder(),
                          suffixText: 'min',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _appointmentDuration = int.tryParse(value) ?? 30;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveAvailability,
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar Disponibilidad'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDayAvailability(String day) {
    final times = _dailyWorkingHours[day] ?? [];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      child: ExpansionTile(
        title: Text(day, style: Theme.of(context).textTheme.titleLarge),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (times.isEmpty)
                  Text('No se han añadido horas de trabajo para $day.'),
                ...times.asMap().entries.map((entry) {
                  int index = entry.key;
                  TimeRange timeRange = entry.value;
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                            '${timeRange.startTime.format(context)} - ${timeRange.endTime.format(context)}'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeTimeRange(day, index),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _pickTimeRange(day),
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir Franja Horaria'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
