class Appointment {
  final String id;
  final String professionalUid;
  final String patientUid;
  final DateTime dateTime;
  final String status;
  final String? service;

  // This field will be populated after fetching the patient's details
  String? patientName;
  String? professionalName;

  Appointment({
    required this.id,
    required this.professionalUid,
    required this.patientUid,
    required this.dateTime,
    required this.status,
    this.service,
    this.patientName,
    this.professionalName,
  });

  factory Appointment.fromMap(String id, Map<String, dynamic> data) {
    return Appointment(
      id: id,
      professionalUid: data['professionalUid'] ?? '',
      patientUid: data['patientUid'] ?? '',
      dateTime: DateTime.fromMillisecondsSinceEpoch(data['dateTime'] ?? 0),
      status: data['status'] ?? 'desconocido',
      service: data['service'],
    );
  }
}
