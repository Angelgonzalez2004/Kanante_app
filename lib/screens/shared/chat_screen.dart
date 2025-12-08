import 'dart:io';
import 'dart:async'; // Import for Timer
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';
import '../../services/firebase_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String otherUserId;
  final String? otherUserImageUrl;
  final bool isProfessionalChat; // New parameter to indicate if it's a chat with a professional

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    required this.otherUserId,
    this.otherUserImageUrl,
    this.isProfessionalChat = false, // Default to false
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _messageController = TextEditingController();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final FocusNode _messageFocusNode = FocusNode();

  String? _currentUserAccountType;
  Timer? _debounce; // For typing indicator debounce

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAccountType();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageFocusNode.requestFocus();
    });

    _messageController.addListener(_onMessageChanged);
  }

  Future<void> _loadCurrentUserAccountType() async {
    final userProfile = await _firebaseService.getUserProfile(_currentUserId);
    if (userProfile != null && mounted) {
      setState(() {
        _currentUserAccountType = userProfile.accountType;
      });
    }
  }

  void _onMessageChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (_messageController.text.isNotEmpty) {
      _firebaseService.setTypingStatus(widget.chatId, _currentUserId, true);
      _debounce = Timer(const Duration(milliseconds: 1000), () {
        _firebaseService.setTypingStatus(widget.chatId, _currentUserId, false);
      });
    } else {
      _firebaseService.setTypingStatus(widget.chatId, _currentUserId, false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _firebaseService.setTypingStatus(widget.chatId, _currentUserId, false); // Clear typing status on dispose
    _messageController.removeListener(_onMessageChanged);
    _messageFocusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = Message(
      id: '',
      chatId: widget.chatId,
      senderId: _currentUserId,
      type: MessageType.text,
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    try {
      await _firebaseService.sendMessage(message);
      _messageController.clear();
      _firebaseService.setTypingStatus(widget.chatId, _currentUserId, false); // Ensure typing status is reset
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar mensaje: $e')),
      );
    }
  }
  // ... rest of the code remains the same

  void _sendImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enviando imagen...')),
      );

      try {
        final imageUrl = await _firebaseService.uploadFile(widget.chatId, file);
        final message = Message(
          id: '',
          chatId: widget.chatId,
          senderId: _currentUserId,
          type: MessageType.image,
          content: imageUrl,
          timestamp: DateTime.now(),
        );
        await _firebaseService.sendMessage(message);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar imagen: $e')),
        );
      }
    }
  }

  void _deleteMessage(Message message, bool deleteForEveryone) async {
    try {
      await _firebaseService.deleteMessage(message.id, widget.chatId, deleteForEveryone);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar mensaje: $e')),
      );
    }
  }

  Future<void> _showAppointmentRequestDialog() async {
    if (_currentUserAccountType != 'Usuario') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo los usuarios pueden solicitar citas.')),
      );
      return;
    }

    // Fetch professional's availability
    final professionalProfile = await _firebaseService.getUserProfile(widget.otherUserId);
    if (professionalProfile == null || professionalProfile.accountType != 'Profesional') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar la disponibilidad del profesional.')),
      );
      return;
    }

    final Map<String, List<String>>? workingHours = professionalProfile.workingHours;
    final int appointmentDuration = professionalProfile.appointmentDuration ?? 30; // Default to 30 min

    if (workingHours == null || workingHours.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El profesional no ha configurado su disponibilidad.')),
      );
      return;
    }

    final navigator = Navigator.of(context); // Capture navigator before async gap
    final messenger = ScaffoldMessenger.of(context); // Capture messenger

    // Map day names from int (DateTime.weekday) to String
    final Map<int, String> weekdayToString = {
      1: 'Lunes', 2: 'Martes', 3: 'Miércoles', 4: 'Jueves', 5: 'Viernes', 6: 'Sábado', 7: 'Domingo',
    };

    final DateTime? pickedDate = await showDatePicker(
      context: navigator.context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)), // 1 year from now
      selectableDayPredicate: (DateTime date) {
        // Only allow selection of days where the professional has working hours
        final String? dayName = weekdayToString[date.weekday];
        return dayName != null && (workingHours[dayName]?.isNotEmpty == true);
      },
    );

    if (pickedDate == null) return; // User cancelled

    if (!mounted) return; // Check mounted after async gap

    // Generate available time slots for the pickedDate
    final String? dayName = weekdayToString[pickedDate.weekday];
    final List<String> dailyWorkingHours = workingHours[dayName!] ?? [];
    
    // Convert string time ranges to TimeOfDay objects
    final List<TimeOfDay> availableTimeSlots = [];
    for (String range in dailyWorkingHours) {
      final parts = range.split('-');
      final TimeOfDay startTime = TimeOfDay(hour: int.parse(parts[0].split(':')[0]), minute: int.parse(parts[0].split(':')[1]));
      final TimeOfDay endTime = TimeOfDay(hour: int.parse(parts[1].split(':')[0]), minute: int.parse(parts[1].split(':')[1]));

      TimeOfDay currentTime = startTime;
      while (currentTime.hour * 60 + currentTime.minute + appointmentDuration <= endTime.hour * 60 + endTime.minute) {
        availableTimeSlots.add(currentTime);
        currentTime = TimeOfDay(hour: currentTime.hour, minute: currentTime.minute + appointmentDuration);
      }
    }

    // Show a dialog with selectable time slots
    final TimeOfDay? pickedTime = await _showTimeSlotPicker(navigator.context, availableTimeSlots);

    if (pickedTime == null) return; // User cancelled

    final DateTime finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    try {
      await _firebaseService.requestAppointment(widget.otherUserId, _currentUserId, finalDateTime);
      if (!mounted) return; // Check mounted after async gap
      messenger.showSnackBar(
        const SnackBar(content: Text('Solicitud de cita enviada con éxito. El profesional te contactará pronto.')),
      );
    } catch (e) {
      if (!mounted) return; // Check mounted after async gap
      messenger.showSnackBar(
        SnackBar(content: Text('Error al enviar la solicitud de cita: $e')),
      );
    }
  }

  Future<TimeOfDay?> _showTimeSlotPicker(BuildContext context, List<TimeOfDay> availableSlots) {
    if (availableSlots.isEmpty) {
      final navigator = Navigator.of(context); // Capture navigator
      return showDialog<TimeOfDay?>(
        context: navigator.context, // Use captured navigator's context
        builder: (context) => AlertDialog(
          title: const Text('Sin Horas Disponibles'),
          content: const Text('No hay horas disponibles para agendar en este día.'),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }

    final navigator = Navigator.of(context); // Capture navigator
    return showDialog<TimeOfDay?>(
      context: navigator.context, // Use captured navigator's context
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecciona una Hora'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: availableSlots.map((time) {
                return ChoiceChip(
                  label: Text(time.format(navigator.context)), // Use captured navigator's context
                  selected: false, // Will be handled by the dialog's state, or just pop
                  onSelected: (selected) {
                    if (selected) {
                      navigator.pop(time);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only show the appointment button if current user is a 'Usuario' and the chat is with a professional
    final bool canRequestAppointment = _currentUserAccountType == 'Usuario' && widget.isProfessionalChat;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.otherUserImageUrl != null
                  ? CachedNetworkImageProvider(widget.otherUserImageUrl!)
                  : null,
              child: widget.otherUserImageUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StreamBuilder<bool>(
                stream: _firebaseService.getTypingStatusStream(widget.chatId, widget.otherUserId),
                builder: (context, snapshot) {
                  final bool isOtherUserTyping = snapshot.data ?? false;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.otherUserName,
                        overflow: TextOverflow.ellipsis, // Handle long names
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (isOtherUserTyping)
                        const Text(
                          'Escribiendo...',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white70),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        actions: [
          if (canRequestAppointment)
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: _showAppointmentRequestDialog,
              tooltip: 'Agendar Cita',
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700.0), // Max width for chat on large screens
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<Message>>(
                    stream: _firebaseService.getMessagesStream(widget.chatId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.chat_bubble_outline_rounded),
                            label: const Text('Iniciar conversación'),
                            onPressed: () {
                              _messageFocusNode.requestFocus();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        );
                      }
                      final messages = snapshot.data!;
                      // Mark messages as read when they are received by the other user
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        for (var message in messages) {
                          if (message.senderId == widget.otherUserId && !message.readBy.contains(_currentUserId)) {
                            _firebaseService.markMessageAsRead(widget.chatId, message.id, _currentUserId);
                          }
                        }
                      });
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == _currentUserId;
                          final bool showDate;
                          if (index == messages.length - 1) {
                            showDate = true;
                          } else {
                            final currentMessage = messages[index];
                            final nextMessage = messages[index + 1];
                            showDate = currentMessage.timestamp.day != nextMessage.timestamp.day;
                          }

                          return Column(
                            children: [
                              if (showDate) _buildDateSeparator(messages[index].timestamp),
                              _buildMessageBubble(message, isMe),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        DateFormat.yMMMMd('es').format(date),
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showDeleteOptions(Message message, bool isMe) {
    final navigator = Navigator.of(context); // Capture navigator
    showModalBottomSheet(
      context: navigator.context, // Use captured navigator's context
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Eliminar para mí'),
                onTap: () {
                  navigator.pop(); // Use captured navigator
                  _deleteMessage(message, false);
                },
              ),
              if (isMe) // Only show 'Delete for everyone' if the current user sent the message
                ListTile(
                  leading: const Icon(Icons.delete_forever),
                  title: const Text('Eliminar para todos'),
                  onTap: () {
                    navigator.pop(); // Use captured navigator
                    _deleteMessage(message, true);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMe ? Colors.teal.shade300 : Colors.grey.shade300;
    final textColor = isMe ? Colors.black87 : Colors.black87;

    return GestureDetector(
      onLongPress: () => _showDeleteOptions(message, isMe),
      child: Container(
        alignment: alignment,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              message.deletedForSender
                  ? Text('Mensaje eliminado', style: TextStyle(color: textColor, fontStyle: FontStyle.italic))
                  : (message.type == MessageType.text
                      ? Text(message.content, style: TextStyle(color: textColor))
                      : CachedNetworkImage(
                          imageUrl: message.content,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                          width: 200,
                        )),
              const SizedBox(height: 4),
              Text(
                DateFormat.Hm().format(message.timestamp),
                style: TextStyle(
                  color: textColor.withAlpha(179), // Replaced withOpacity
                  fontSize: 12,
                ),
              ),
              if (isMe) // Only show read status for messages sent by the current user
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Icon(
                    message.readBy.contains(widget.otherUserId) ? Icons.done_all : Icons.done,
                    size: 16,
                    color: message.readBy.contains(widget.otherUserId) ? Colors.blue : textColor.withAlpha(179),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [BoxShadow(blurRadius: 1, color: Colors.black12)],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image, color: Colors.teal),
            onPressed: _sendImage,
          ),
          Expanded(
            child: TextField(
              focusNode: _messageFocusNode,
              controller: _messageController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Escribe un mensaje...',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.teal),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}