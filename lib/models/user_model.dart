class UserModel {
  final String id;
  final String name;
  final String email;
  final String accountType; // 'Usuario', 'Profesional', 'Admin'
  final String? profileImageUrl;
  final String? birthDate;
  final String? phone;
  final String? rfc; // Added rfc field
  
  // Verification fields for professionals
  final String? verificationStatus; // e.g., 'unverified', 'pending', 'verified', 'rejected'
  final String? verificationNotes;
  final List<String>? verificationDocuments;

  final List<String> specialties;
  final List<String> patientIds;
  final String? bio;
  final String? address;
  final double? appointmentPrice;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.accountType,
    this.profileImageUrl,
    this.birthDate,
    this.phone,
    this.rfc, // Added rfc to constructor
    this.verificationStatus,
    this.verificationNotes,
    this.verificationDocuments,
    this.specialties = const [],
    this.patientIds = const [],
    this.bio,
    this.address,
    this.appointmentPrice,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] ?? 'Nombre no disponible',
      email: data['email'] ?? 'Email no disponible',
      accountType: data['accountType'] ?? 'Usuario',
      profileImageUrl: data['profileImageUrl'],
      birthDate: data['birthDate'],
      phone: data['phone'],
      rfc: data['rfc'], // Added rfc to fromMap
      verificationStatus: data['verificationStatus'] ?? 'unverified',
      verificationNotes: data['verificationNotes'],
      verificationDocuments: List<String>.from(data['verificationDocuments'] ?? []),
      specialties: List<String>.from(data['specialties'] ?? []),
      patientIds: data['patientIds'] is Map ? Map<String, dynamic>.from(data['patientIds']).keys.toList() : List<String>.from(data['patientIds'] ?? []),
      bio: data['bio'],
      address: data['address'],
      appointmentPrice: (data['appointmentPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'accountType': accountType,
      'profileImageUrl': profileImageUrl,
      'birthDate': birthDate,
      'phone': phone,
      'rfc': rfc, // Added rfc to toMap
      'verificationStatus': verificationStatus,
      'verificationNotes': verificationNotes,
      'verificationDocuments': verificationDocuments,
      'specialties': specialties,
      'patientIds': patientIds,
      'bio': bio,
      'address': address,
      'appointmentPrice': appointmentPrice,
    };
  }
}