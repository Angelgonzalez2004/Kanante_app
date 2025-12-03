
class UserModel {
  final String id;
  final String name;
  final String email;
  final String accountType;
  final String? profileImageUrl;
  final String? birthDate;
  final String? phone;
  final String? verificationStatus;
  final List<String> specialties;
  final List<String> patientIds;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.accountType,
    this.profileImageUrl,
    this.birthDate,
    this.phone,
    this.verificationStatus,
    this.specialties = const [],
    this.patientIds = const [],
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    // Safely handle patient IDs
    final patientsData = data['patients'];
    List<String> patientIds = [];
    if (patientsData is Map) {
      patientIds = patientsData.keys.toList().cast<String>();
    }

    return UserModel(
      id: id,
      name: data['name'] ?? 'Nombre no disponible',
      email: data['email'] ?? 'Email no disponible',
      accountType: data['accountType'] ?? 'Usuario',
      profileImageUrl: data['profileImageUrl'],
      birthDate: data['birthDate'],
      phone: data['phone'],
      verificationStatus: data['verificationStatus'],
      specialties: List<String>.from(data['specialties'] ?? []),
      patientIds: patientIds,
    );
  }
}
