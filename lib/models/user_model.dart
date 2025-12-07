class UserModel {
  final String id;
  final String name;
  final String email;
  final String accountType; // 'Usuario', 'Profesional', 'Admin'
  final String? profileImageUrl;
  final String? birthDate;
  final String? phone;
  final String? rfc; // Added rfc field
  final String? gender; // New field
  final String? preferredLanguage; // New field
  final String? timezone; // New field
  final String? website; // New field for professionals
  final Map<String, String>? socialMediaLinks; // New field for professionals
  final List<String>? education; // New field for professionals
  final List<String>? certifications; // New field for professionals
  
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
    this.gender, // New field
    this.preferredLanguage, // New field
    this.timezone, // New field
    this.website, // New field for professionals
    this.socialMediaLinks, // New field for professionals
    this.education, // New field for professionals
    this.certifications, // New field for professionals
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
      gender: data['gender'], // New field
      preferredLanguage: data['preferredLanguage'], // New field
      timezone: data['timezone'], // New field
      website: data['website'], // New field
      socialMediaLinks: (data['socialMediaLinks'] as Map<String, dynamic>?)?.map((key, value) => MapEntry(key, value as String)), // New field
      education: List<String>.from(data['education'] ?? []), // New field
      certifications: List<String>.from(data['certifications'] ?? []), // New field
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
      'gender': gender, // New field
      'preferredLanguage': preferredLanguage, // New field
      'timezone': timezone, // New field
      'website': website, // New field
      'socialMediaLinks': socialMediaLinks, // New field
      'education': education, // New field
      'certifications': certifications, // New field
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