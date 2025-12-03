import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/publication_model.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class FirebaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final snapshot = await _db.child('users/$userId').get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return UserModel.fromMap(userId, data);
      }
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
    }
    return null;
  }

  Future<UserModel?> checkIfUserExistsByEmail(String email) async {
    try {
      final snapshot = await _db.child('users').orderByChild('email').equalTo(email.toLowerCase()).get();
      if (snapshot.exists && snapshot.value != null) {
        final usersData = Map<String, dynamic>.from(snapshot.value as Map);
        final entry = usersData.entries.first;
        return UserModel.fromMap(entry.key, Map<String, dynamic>.from(entry.value as Map));
      }
    } catch (e) {
      debugPrint("Error checking if user exists by email: $e");
    }
    return null;
  }

  Future<UserModel?> handleGoogleSignIn(User firebaseUser) async {
    UserModel? userModel = await getUserProfile(firebaseUser.uid);
    if (userModel != null) {
      return userModel;
    } else {
      if (firebaseUser.email != null) {
        UserModel? existingUserByEmail = await checkIfUserExistsByEmail(firebaseUser.email!);
        if (existingUserByEmail != null) {
          debugPrint("User with email ${firebaseUser.email} already exists with a different UID.");
          return null;
        }
      }
      return null;
    }
  }

  Future<void> createNewUser({
    required String uid,
    required String email,
    required String name,
    required String accountType,
    String? profileImageUrl,
    DateTime? birthDate,
    String? phone,
    String? rfc,
    List<String> specialties = const [],
  }) async {
    String? formattedBirthDate;
    if (birthDate != null) {
      formattedBirthDate = DateFormat('yyyy-MM-dd').format(birthDate);
    }
    
    UserModel newUser = UserModel(
      id: uid,
      email: email,
      name: name,
      accountType: accountType,
      profileImageUrl: profileImageUrl,
      birthDate: formattedBirthDate,
      specialties: specialties,
      verificationStatus: 'pending',
      bio: '',
      phone: phone ?? '',
      address: '',
      appointmentPrice: 0.0,
      patientIds: [],
    );
    await _db.child('users/$uid').set(newUser.toMap());
  }

  // --- Other methods from the original file ---

  Future<List<UserModel>> getAllProfessionals({String? searchQuery}) async {
    try {
      final event = await _db.child('users').orderByChild('accountType').equalTo('Profesional').once();
      final snapshot = event.snapshot;

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final usersData = Map<String, dynamic>.from(snapshot.value as Map);
      List<UserModel> professionals = usersData.entries.map((entry) {
        return UserModel.fromMap(entry.key, Map<String, dynamic>.from(entry.value as Map));
      }).toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        professionals = professionals.where((prof) {
          return prof.name.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
      }

      return professionals;
    } catch (e) {
      debugPrint("Error fetching all professionals: $e");
      return [];
    }
  }

  Future<List<UserModel>> getAllUsers({String? searchQuery}) async {
    try {
      final event = await _db.child('users').once();
      final snapshot = event.snapshot;

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final usersData = Map<String, dynamic>.from(snapshot.value as Map);
      List<UserModel> allUsers = usersData.entries.map((entry) {
        return UserModel.fromMap(entry.key, Map<String, dynamic>.from(entry.value as Map));
      }).toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        allUsers = allUsers.where((user) {
          return user.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                 user.accountType.toLowerCase().contains(searchQuery.toLowerCase()) ||
                 user.specialties.any((s) => s.toLowerCase().contains(searchQuery.toLowerCase()));
        }).toList();
      }

      return allUsers;
    } catch (e) {
      debugPrint("Error fetching all users: $e");
      return [];
    }
  }

  Future<List<Publication>> getPublicationsForProfessional(String professionalId) async {
    try {
      final event = await _db.child('publications').orderByChild('professionalUid').equalTo(professionalId).once();
      final snapshot = event.snapshot;

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final publicationsData = Map<String, dynamic>.from(snapshot.value as Map);
      final List<Publication> publications = publicationsData.entries.map((entry) {
        return Publication.fromMap(entry.key, Map<String, dynamic>.from(entry.value as Map));
      }).toList();

      publications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return publications;
    } catch (e) {
      debugPrint("Error fetching publications: $e");
      return [];
    }
  }

  Future<List<Publication>> getAllPublications() async {
    try {
      final event = await _db.child('publications').once();
      final snapshot = event.snapshot;

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final publicationsData = Map<String, dynamic>.from(snapshot.value as Map);
      final List<Publication> publications = publicationsData.entries.map((entry) {
        return Publication.fromMap(entry.key, Map<String, dynamic>.from(entry.value as Map));
      }).toList();

      for (var pub in publications) {
        final author = await getUserProfile(pub.professionalUid);
        pub.authorName = author?.name;
        pub.authorImageUrl = author?.profileImageUrl;
        pub.authorVerificationStatus = author?.verificationStatus;
      }

      publications.shuffle();

      return publications;
    } catch (e) {
      debugPrint("Error fetching all publications: $e");
      return [];
    }
  }

  Future<List<UserModel>> getPatientsForProfessional(String professionalId) async {
    try {
      final professional = await getUserProfile(professionalId);
      if (professional == null || professional.patientIds.isEmpty) {
        return [];
      }
      final patientFutures = professional.patientIds.map((patientId) => getUserProfile(patientId)).toList();
      final results = await Future.wait(patientFutures);
      return results.where((patient) => patient != null).cast<UserModel>().toList();
    } catch (e) {
      debugPrint("Error fetching patients for professional: $e");
      return [];
    }
  }

  Future<List<Appointment>> getAppointmentsForProfessional(String professionalId) async {
    try {
      final event = await _db.child('appointments').orderByChild('professionalUid').equalTo(professionalId).once();
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return [];

      final appointmentsData = Map<String, dynamic>.from(snapshot.value as Map);
      final List<Appointment> appointments = [];
      for (var entry in appointmentsData.entries) {
        appointments.add(Appointment.fromMap(entry.key, Map<String, dynamic>.from(entry.value as Map)));
      }

      await Future.wait(appointments.map((appointment) async {
        final patient = await getUserProfile(appointment.patientUid);
        appointment.patientName = patient?.name ?? 'Paciente Desconocido';
      }));

      appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return appointments;
    } catch (e) {
      debugPrint("Error fetching appointments for professional: $e");
      return [];
    }
  }

  Future<void> requestAppointment(String professionalUid, String patientUid, DateTime dateTime) async {
    final appointmentRef = _db.child('appointments').push();
    await appointmentRef.set({
      'professionalUid': professionalUid,
      'patientUid': patientUid,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'status': 'pending',
    });
  }

  Future<void> updateAppointmentStatus(String appointmentId, String newStatus) async {
    await _db.child('appointments/$appointmentId').update({'status': newStatus});
  }

  Future<List<Appointment>> getAppointmentsForUser(String userId) async {
    try {
      final event = await _db.child('appointments').orderByChild('patientUid').equalTo(userId).once();
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) return [];

      final appointmentsData = Map<String, dynamic>.from(snapshot.value as Map);
      final List<Appointment> appointments = [];
      for (var entry in appointmentsData.entries) {
        appointments.add(Appointment.fromMap(entry.key, Map<String, dynamic>.from(entry.value as Map)));
      }

      await Future.wait(appointments.map((appointment) async {
        final professional = await getUserProfile(appointment.professionalUid);
        appointment.professionalName = professional?.name ?? 'Profesional Desconocido';
      }));

      appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return appointments;
    } catch (e) {
      debugPrint("Error fetching appointments for user: $e");
      return [];
    }
  }

  Future<List<ChatConversation>> getConversationsForProfessional(String professionalId) async {
    try {
      final event = await _db.child('chats').orderByChild('participants/$professionalId').equalTo(true).once();
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];

      final List<ChatConversation> conversations = [];
      for (final child in snapshot.children) {
        if (child.key != null && child.value != null) {
          conversations.add(ChatConversation.fromMap(child.key!, Map<String, dynamic>.from(child.value as Map)));
        }
      }

      await Future.wait(conversations.map((convo) async {
        final otherId = convo.participants.firstWhere((p) => p != professionalId, orElse: () => '');
        if (otherId.isNotEmpty) {
          final user = await getUserProfile(otherId);
          convo.otherParticipantName = user?.name ?? 'Usuario Desconocido';
          convo.otherParticipantImageUrl = user?.profileImageUrl;
        }
      }));

      conversations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return conversations;
    } catch (e) {
      debugPrint("Error fetching conversations for professional: $e");
      return [];
    }
  }

  Future<List<ChatConversation>> getConversationsForUser(String userId) async {
    try {
      final event = await _db.child('chats').orderByChild('participants/$userId').equalTo(true).once();
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];
       final List<ChatConversation> conversations = [];
      for (final child in snapshot.children) {
        if (child.key != null && child.value != null) {
          conversations.add(ChatConversation.fromMap(child.key!, Map<String, dynamic>.from(child.value as Map)));
        }
      }

      await Future.wait(conversations.map((convo) async {
        final otherId = convo.participants.firstWhere((p) => p != userId, orElse: () => '');
        if (otherId.isNotEmpty) {
          final user = await getUserProfile(otherId);
          convo.otherParticipantName = user?.name ?? 'Usuario Desconocido';
          convo.otherParticipantImageUrl = user?.profileImageUrl;
        }
      }));

      conversations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return conversations;
    } catch (e) {
      debugPrint("Error fetching conversations for user: $e");
      return [];
    }
  }

  Future<List<UserModel>> searchProfessionals({String? query}) async {
    try {
      final event = await _db.child('users').orderByChild('accountType').equalTo('Profesional').once();
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];

      final usersData = Map<String, dynamic>.from(snapshot.value as Map);
      List<UserModel> professionals = usersData.entries
          .map((e) => UserModel.fromMap(e.key, Map<String, dynamic>.from(e.value as Map)))
          .toList();

      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        professionals = professionals.where((p) =>
            p.name.toLowerCase().contains(lowerQuery) ||
            p.specialties.any((s) => s.toLowerCase().contains(lowerQuery))).toList();
      }
      return professionals;
    } catch (e) {
      debugPrint("Error searching professionals: $e");
      return [];
    }
  }

  Future<String> getOrCreateChat(String currentUserId, String otherUserId) async {
    final participants = [currentUserId, otherUserId]..sort();
    final chatId = participants.join('_');
    final chatRef = _db.child('chats/$chatId');
    final snapshot = await chatRef.get();
    if (!snapshot.exists) {
      await chatRef.set({
        'participants': {currentUserId: true, otherUserId: true},
        'lastMessage': '',
        'timestamp': ServerValue.timestamp,
      });
    }
    return chatId;
  }

  Stream<List<Message>> getMessagesStream(String chatId) {
    final messagesRef = _db.child('messages/$chatId').orderByChild('timestamp');
    return messagesRef.onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries
          .map((e) => Message.fromMap(e.key, Map<String, dynamic>.from(e.value as Map)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  Future<void> sendMessage(Message message) async {
    final messageRef = _db.child('messages/${message.chatId}').push();
    await messageRef.set(message.toMap());
    final chatRef = _db.child('chats/${message.chatId}');
    await chatRef.update({
      'lastMessage': message.type == MessageType.text ? message.content : 'Archivo adjunto',
      'timestamp': ServerValue.timestamp,
    });
  }

  Future<void> deleteMessage(String messageId, String chatId, bool deleteForEveryone) async {
    if (deleteForEveryone) {
      await _db.child('messages/$chatId/$messageId').remove();
    } else {
      await _db.child('messages/$chatId/$messageId').update({
        'content': 'Mensaje eliminado',
        'type': 'text',
        'deletedForSender': true,
      });
    }
  }

  Future<String> uploadFile(String chatId, File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child('chat_files/$chatId/$fileName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading file: $e");
      rethrow;
    }
  }
}
