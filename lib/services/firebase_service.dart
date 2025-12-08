// lib\services\firebase_service.dart

import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/appointment_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/publication_model.dart';
import '../models/user_model.dart';
import '../models/support_ticket_model.dart';
import '../models/alert_model.dart'; // New import
import '../models/comment_model.dart'; // New import
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class FirebaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirebaseStorage get storage => _storage;

  // --- User Profile Methods ---

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

  Future<void> createNewUser({
    required String uid,
    required String email,
    required String name,
    required String accountType,
    String? profileImageUrl,
    DateTime? birthDate,
    String? phone,
    String? rfc,
    String? gender, // New parameter
    List<dynamic> specialties = const [],
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
      gender: gender, // Pass new field
      specialties: specialties.cast<String>(),
      verificationStatus: 'pending',
      bio: '',
      phone: phone ?? '',
      address: '',
      appointmentPrice: 0.0,
      patientIds: [],
    );
    await _db.child('users/$uid').set(newUser.toMap());
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) {
    return _db.child('users/$uid').update(data);
  }

  Future<void> deleteUser(String userId) {
    // This removes the user's data from the Realtime Database.
    // Note: This does NOT delete the user from Firebase Authentication.
    // That requires the Admin SDK and should be handled by a backend function.
    return _db.child('users/$userId').remove();
  }

  // --- Support Ticket Methods ---

  Future<void> createSupportTicket(SupportTicket ticket) async {
    final ticketRef = _db.child('support_tickets').push();
    await ticketRef.set(ticket.toMap());
  }

  Stream<List<SupportTicket>> getSupportTickets() {
    return _db.child('support_tickets').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return [];
      }
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries.map((e) => SupportTicket.fromMap(e.key, Map<String, dynamic>.from(e.value as Map))).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> replyToSupportTicket(String ticketId, String response) async {
    await _db.child('support_tickets/$ticketId').update({
      'adminResponse': response,
      'respondedAt': DateTime.now().millisecondsSinceEpoch,
      'status': 'closed',
    });
  }

  // --- Alert Methods ---

  Future<void> sendAlert(AlertModel alert) async {
    final alertRef = _db.child('alerts').push();
    await alertRef.set(alert.toMap());
  }

  Stream<List<AlertModel>> getAlertsForRecipient(String recipientId) {
    return _db.child('alerts').orderByChild('recipientId').equalTo(recipientId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return [];
      }
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return data.entries.map((e) => AlertModel.fromMap(e.key, Map<String, dynamic>.from(e.value as Map))).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  Future<void> replyToAlert(String alertId, String replyMessage, String newStatus) async {
    await _db.child('alerts/$alertId').update({
      'recipientReply': replyMessage,
      'replyTimestamp': DateTime.now().millisecondsSinceEpoch,
      'status': newStatus,
    });
  }

  Future<void> markAlertAsRead(String alertId) async {
    await _db.child('alerts/$alertId').update({
      'status': 'read',
    });
  }

  // --- Support Chat Methods ---

  Future<String> getOrCreateSupportChat(String userId, String userName, String userRole) async {
    final chatId = 'support_$userId';
    final chatRef = _db.child('support_chats/$chatId');
    final snapshot = await chatRef.get();
    if (!snapshot.exists) {
      await chatRef.set({
        'participants': {userId: true, 'support_admin': true},
        'lastMessage': 'Chat de soporte iniciado.',
        'timestamp': ServerValue.timestamp,
        'userName': userName,
        'userRole': userRole,
        'userId': userId,
      });
    }
    return chatId;
  }
  
  Stream<List<ChatConversation>> getSupportChats() {
    return _db.child('support_chats').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return [];
      }
      final data = Map<String, dynamic>.from(event.snapshot.value as Map<dynamic, dynamic>);
      final conversations = data.entries.map((e) {
        final chatData = Map<String, dynamic>.from(e.value as Map<dynamic, dynamic>);
        
        // CORRECCIÓN APLICADA AQUÍ: Se utiliza .cast<String>().toList() para asegurar List<String>
        final List<String> participantKeys = (chatData['participants'] as Map<dynamic, dynamic>).keys.cast<String>().toList();

        // We manually construct a ChatConversation-like object for the admin view
        return ChatConversation(
          id: e.key,
          participants: participantKeys, 
          lastMessage: chatData['lastMessage'] ?? '',
          timestamp: DateTime.fromMillisecondsSinceEpoch(chatData['timestamp']),
          // Custom fields for admin view
          otherParticipantName: chatData['userName'] ?? 'Usuario Desconocido',
          otherParticipantImageUrl: null, // No image for admin view for now
        );
      }).toList();
      conversations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return conversations;
    });
  }

  Stream<List<Message>> getSupportMessagesStream(String chatId) {
    return getMessagesStream(chatId); // Can reuse the same logic
  }

  Future<void> sendMessageToSupport(Message message) async {
    // Reusing the base sendMessage and targeting the 'support_chats' node for the update
    final messageRef = _db.child('messages/${message.chatId}').push();
    await messageRef.set(message.toMap());
    final chatRef = _db.child('support_chats/${message.chatId}');
    await chatRef.update({
      'lastMessage': message.type == MessageType.text ? message.content : 'Archivo adjunto',
      'timestamp': ServerValue.timestamp,
    });
  }

  // --- User/Professional Fetching Methods ---

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

  // --- Publication Methods ---

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

  Stream<List<Publication>> getPublicationsStream() {
    return _db.child('publications').onValue.asyncMap((event) async {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return [];
      }

      final publicationsData = Map<String, dynamic>.from(event.snapshot.value as Map);
      final List<Publication> publications = [];

      for (var entry in publicationsData.entries) {
        publications.add(Publication.fromMap(entry.key, Map<String, dynamic>.from(entry.value as Map)));
      }

      for (var pub in publications) {
        final author = await getUserProfile(pub.professionalUid);
        pub.authorName = author?.name;
        pub.authorImageUrl = author?.profileImageUrl;
        pub.authorVerificationStatus = author?.verificationStatus;
      }

      publications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return publications;
    });
  }

  Future<void> toggleLikePublication(String publicationId, String userId) async {
    final pubRef = _db.child('publications/$publicationId');
    await pubRef.runTransaction((Object? post) {
      if (post == null) {
        return Transaction.abort();
      }

      final Map<String, dynamic> postData = Map<String, dynamic>.from(post as Map);
      final List<String> likedBy = List<String>.from(postData['likedBy'] ?? []);
      
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }
      
      postData['likedBy'] = likedBy;
      postData['likes'] = likedBy.length;

      return Transaction.success(postData);
    });
  }

  Future<void> addCommentToPublication(String publicationId, CommentModel comment) async {
    final commentRef = _db.child('publications/$publicationId/comments').push();
    await commentRef.set(comment.toMap());
  }

  // --- Patient/Appointment Methods ---

  Future<List<UserModel>> getPatientsForProfessional(String professionalId) async {
    try {
      final professional = await getUserProfile(professionalId);
      if (professional == null || professional.patientIds.isEmpty) {
        return [];
      }
      // patientIds es List<String> por definición en UserModel
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

  // --- Chat Conversation Methods ---

  Future<List<ChatConversation>> getConversationsForProfessional(String professionalId) async {
    try {
      final event = await _db.child('chats').orderByChild('participants/$professionalId').equalTo(true).once();
      final snapshot = event.snapshot;
      if (!snapshot.exists) return [];

      final List<ChatConversation> conversations = [];
      for (final child in snapshot.children) {
        if (child.key != null && child.value != null) {
          conversations.add(ChatConversation.fromMap(child.key!, Map<String, dynamic>.from(child.value as Map<dynamic, dynamic>)));
        }
      }

      await Future.wait(conversations.map((convo) async {
        // En ChatConversation, `participants` es List<String>. El método .firstWhere es seguro.
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
          conversations.add(ChatConversation.fromMap(child.key!, Map<String, dynamic>.from(child.value as Map<dynamic, dynamic>)));
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

  // --- Chat Management Methods ---

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
          // La ordenación es opcional aquí, dependiendo de si el Stream de la UI necesita el orden inverso.
          // Si orderByChild('timestamp') ya trae ordenado, esta línea podría omitirse.
          // Se mantiene la lógica original: ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); 
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp)); // Revertido a orden ascendente para un chat
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

  // --- Search Methods (Duplicated logic merged/cleaned) ---

  Future<List<UserModel>> searchProfessionals({String? query}) async {
    // Reutiliza getAllProfessionals con la misma lógica de búsqueda
    return getAllProfessionals(searchQuery: query);
  }
}