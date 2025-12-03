import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/appointment_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/publication_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Fetches a user's profile by their ID
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final snapshot = await _db.child('users/$userId').get();
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return UserModel.fromMap(userId, data);
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
    return null;
  }

  // Fetches all professionals, with optional name filtering
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

      // Filter by search query if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        professionals = professionals.where((prof) {
          return prof.name.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
      }

      return professionals;
    } catch (e) {
      print("Error fetching all professionals: $e");
      return [];
    }
  }

  // Fetches all users (professionals and regular users), with optional name/specialty filtering
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

      // Filter by search query if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        allUsers = allUsers.where((user) {
          return user.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                 user.accountType.toLowerCase().contains(searchQuery.toLowerCase()) ||
                 user.specialties.any((s) => s.toLowerCase().contains(searchQuery.toLowerCase()));
        }).toList();
      }

      return allUsers;
    } catch (e) {
      print("Error fetching all users: $e");
      return [];
    }
  }

  // Fetches all publications for a specific professional
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

      // Sort publications by creation date (newest first)
      publications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return publications;
    } catch (e) {
      print("Error fetching publications: $e");
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

      // Enrich with author details
      for (var pub in publications) {
        final author = await getUserProfile(pub.professionalUid);
        pub.authorName = author?.name;
        pub.authorImageUrl = author?.profileImageUrl;
        pub.authorVerificationStatus = author?.verificationStatus;
      }

      // Shuffle for a random feed effect
      publications.shuffle();

      return publications;
    } catch (e) {
      print("Error fetching all publications: $e");
      return [];
    }
  }

  // Fetches the full profiles of all patients for a given professional
  Future<List<UserModel>> getPatientsForProfessional(String professionalId) async {
    try {
      // First, get the professional's list of patient IDs
      final professional = await getUserProfile(professionalId);
      if (professional == null || professional.patientIds.isEmpty) {
        return [];
      }

      // Then, fetch the profile for each patient ID
      final patientFutures = professional.patientIds.map((patientId) => getUserProfile(patientId)).toList();
      
      // Wait for all futures to complete
      final results = await Future.wait(patientFutures);

      // Filter out any null results (if a patient profile failed to load)
      return results.where((patient) => patient != null).cast<UserModel>().toList();

    } catch (e) {
      print("Error fetching patients for professional: $e");
      return [];
    }
  }

  // Fetches all appointments for a professional and enriches them with patient names.
  Future<List<Appointment>> getAppointmentsForProfessional(String professionalId) async {
    try {
      final event = await _db.child('appointments').orderByChild('professionalUid').equalTo(professionalId).once();
      final snapshot = event.snapshot;

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final appointmentsData = Map<String, dynamic>.from(snapshot.value as Map);
      final List<Appointment> appointments = [];

      for (var entry in appointmentsData.entries) {
        final appointment = Appointment.fromMap(entry.key, Map<String, dynamic>.from(entry.value as Map));
        appointments.add(appointment);
      }

      // Enrich appointments with patient names
      final List<Future<void>> enrichmentFutures = [];
      for (var appointment in appointments) {
        enrichmentFutures.add(() async {
          final patient = await getUserProfile(appointment.patientUid);
          appointment.patientName = patient?.name ?? 'Paciente Desconocido';
        }());
      }

      await Future.wait(enrichmentFutures);

      // Sort appointments by date (most recent first)
      appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      return appointments;

    } catch (e) {
      print("Error fetching appointments for professional: $e");
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
    await _db.child('appointments/$appointmentId').update({
      'status': newStatus,
    });
  }

  Future<List<Appointment>> getAppointmentsForUser(String userId) async {
    try {
      final event = await _db.child('appointments').orderByChild('patientUid').equalTo(userId).once();
      final snapshot = event.snapshot;

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final appointmentsData = Map<String, dynamic>.from(snapshot.value as Map);
      final List<Appointment> appointments = [];

      for (var entry in appointmentsData.entries) {
        final appointment = Appointment.fromMap(entry.key, Map<String, dynamic>.from(entry.value as Map));
        appointments.add(appointment);
      }

      // Enrich appointments with professional names
      for (var appointment in appointments) {
        final professional = await getUserProfile(appointment.professionalUid);
        appointment.professionalName = professional?.name ?? 'Profesional Desconocido';
      }

      appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      return appointments;

    } catch (e) {
      print("Error fetching appointments for user: $e");
      return [];
    }
  }

  // Fetches all conversations for a professional and enriches them with the other user's details.
  Future<List<ChatConversation>> getConversationsForProfessional(String professionalId) async {
    try {
      final event = await _db.child('chats').orderByChild('participants/$professionalId').equalTo(true).once();
      final snapshot = event.snapshot;

      final List<ChatConversation> conversations = [];

      // Iterate through the children of the snapshot
      // Each child represents a chat
      for (final child in snapshot.children) {
        final chatId = child.key;
        final chatData = child.value;

        if (chatId != null && chatData != null && chatData is Map) {
          final conversation = ChatConversation.fromMap(chatId, Map<String, dynamic>.from(chatData));
          conversations.add(conversation);
        }
      }

      // Enrich conversations with the other participant's details
      final List<Future<void>> enrichmentFutures = [];
      for (var convo in conversations) {
        enrichmentFutures.add(() async {
          final otherParticipantId = convo.participants.firstWhere((p) => p != professionalId, orElse: () => '');
          if (otherParticipantId.isNotEmpty) {
            final user = await getUserProfile(otherParticipantId);
            convo.otherParticipantName = user?.name ?? 'Usuario Desconocido';
            convo.otherParticipantImageUrl = user?.profileImageUrl;
          }
        }());
      }

      await Future.wait(enrichmentFutures);

      // Sort conversations by timestamp (most recent first)
      conversations.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return conversations;

    } catch (e) {
      print("Error fetching conversations for professional: $e");
      return [];
    }
  }

  Future<List<ChatConversation>> getConversationsForUser(String userId) async {
    try {
      final event = await _db.child('chats').orderByChild('participants/$userId').equalTo(true).once();
      final snapshot = event.snapshot;

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final List<ChatConversation> conversations = [];

      for (final child in snapshot.children) {
        final chatId = child.key;
        final chatData = child.value;

        if (chatId != null && chatData != null && chatData is Map) {
          final conversation = ChatConversation.fromMap(chatId, Map<String, dynamic>.from(chatData));
          conversations.add(conversation);
        }
      }

      final List<Future<void>> enrichmentFutures = [];
      for (var convo in conversations) {
        enrichmentFutures.add(() async {
          final otherParticipantId = convo.participants.firstWhere((p) => p != userId, orElse: () => '');
          if (otherParticipantId.isNotEmpty) {
            final user = await getUserProfile(otherParticipantId);
            convo.otherParticipantName = user?.name ?? 'Usuario Desconocido';
            convo.otherParticipantImageUrl = user?.profileImageUrl;
          }
        }());
      }

      await Future.wait(enrichmentFutures);

      conversations.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return conversations;

    } catch (e) {
      print("Error fetching conversations for user: $e");
      return [];
    }
  }

  Future<List<UserModel>> searchProfessionals({String? query}) async {
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

      if (query != null && query.isNotEmpty) {
        final lowerCaseQuery = query.toLowerCase();
        professionals = professionals.where((prof) {
          final nameMatch = prof.name.toLowerCase().contains(lowerCaseQuery);
          final specialtyMatch = prof.specialties.any((s) => s.toLowerCase().contains(lowerCaseQuery));
          return nameMatch || specialtyMatch;
        }).toList();
      }

      return professionals;
    } catch (e) {
      print("Error searching professionals: $e");
      return [];
    }
  }

  // --- Chat Methods ---

  Future<String> getOrCreateChat(String currentUserId, String otherUserId) async {
    // Generate a consistent chat ID
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
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return [];
      }
      final messagesData = Map<String, dynamic>.from(event.snapshot.value as Map);
      return messagesData.entries.map((entry) {
        return Message.fromMap(entry.key, Map<String, dynamic>.from(entry.value as Map));
      }).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  Future<void> sendMessage(Message message) async {
    final messageRef = _db.child('messages/${message.chatId}').push();
    await messageRef.set(message.toMap());

    // Update the last message in the chat node
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
      // For 'delete for me', we'll update the message content and add a flag.
      // A more robust solution for 'delete for me' would involve a more complex data structure
      // to track deletion status per user.
      await _db.child('messages/$chatId/$messageId').update({
        'content': 'Mensaje eliminado',
        'type': 'text', // Ensure it's displayed as text
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
      print("Error uploading file: $e");
      rethrow;
    }
  }
}
