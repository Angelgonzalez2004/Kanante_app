import 'dart:io';
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

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAccountType();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageFocusNode.requestFocus();
    });
  }

  Future<void> _loadCurrentUserAccountType() async {
    final userProfile = await _firebaseService.getUserProfile(_currentUserId);
    if (userProfile != null && mounted) {
      setState(() {
        _currentUserAccountType = userProfile.accountType;
      });
    }
  }

  @override
  void dispose() {
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar mensaje: $e')),
      );
    }
  }

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

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)), // 1 year from now
    );

    if (pickedDate == null) return; // User cancelled

    if (!mounted) return; // Check mounted after async gap

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud de cita enviada con éxito. El profesional te contactará pronto.')),
      );
    } catch (e) {
      if (!mounted) return; // Check mounted after async gap
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar la solicitud de cita: $e')),
      );
    }
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
              child: Text(
                widget.otherUserName,
                overflow: TextOverflow.ellipsis, // Handle long names
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
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Eliminar para mí'),
                onTap: () {
                  Navigator.pop(bc);
                  _deleteMessage(message, false);
                },
              ),
              if (isMe) // Only show 'Delete for everyone' if the current user sent the message
                ListTile(
                  leading: const Icon(Icons.delete_forever),
                  title: const Text('Eliminar para todos'),
                  onTap: () {
                    Navigator.pop(bc);
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