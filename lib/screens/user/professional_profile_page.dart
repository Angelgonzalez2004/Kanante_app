import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../models/publication_model.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../shared/chat_screen.dart';
import '../shared/image_viewer_screen.dart';

class ProfessionalProfilePage extends StatefulWidget {
  final String professionalId;

  const ProfessionalProfilePage({super.key, required this.professionalId});

  @override
  State<ProfessionalProfilePage> createState() => _ProfessionalProfilePageState();
}

class _ProfessionalProfilePageState extends State<ProfessionalProfilePage> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<UserModel?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _firebaseService.getUserProfile(widget.professionalId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<UserModel?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No se pudo cargar el perfil.'));
          }
          final professional = snapshot.data!;
          return _buildTabView(professional);
        },
      ),
    );
  }

  Widget _buildTabView(UserModel professional) {
    return DefaultTabController(
      length: 2,
      child: Center( // Content wrapped in Center and ConstrainedBox
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800.0), // Already added this wrapper
          child: Column( // This column was the body of the nested Scaffold
            children: [
              _buildActionButtons(professional),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildProfileInfoTab(professional),
                    _buildPublicationsTab(professional.id),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoTab(UserModel professional) {
    final bool isVerified = professional.verificationStatus == 'verified';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: professional.profileImageUrl ?? professional.id,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: professional.profileImageUrl != null
                      ? CachedNetworkImageProvider(professional.profileImageUrl!)
                      : null,
                  child: professional.profileImageUrl == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(professional.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    if (isVerified)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Chip(
                          avatar: Icon(Icons.verified,
                              color: Colors.teal.shade800, size: 18),
                          label: const Text('Verificado'),
                          // CORRECCIÓN: withOpacity -> withValues
                          backgroundColor: Colors.teal.withValues(alpha: 0.1),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (professional.specialties.isNotEmpty)
            Text(
              professional.specialties.join(' • '),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.black54),
            ),
        ],
      ),
    );
  }

  Widget _buildPublicationsTab(String professionalId) {
    return FutureBuilder<List<Publication>>(
      future: _firebaseService.getPublicationsForProfessional(professionalId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay publicaciones.'));
        }
        final publications = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: publications.length,
          itemBuilder: (context, index) {
            return _publicationCard(publications[index]);
          },
        );
      },
    );
  }

  Widget _buildActionButtons(UserModel professional) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == professional.id) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.message_rounded),
              label: const Text('Mensaje'),
              onPressed: () => _openChat(professional),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, foregroundColor: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('Agendar Cita'),
              onPressed: () => _showAppointmentRequestDialog(professional),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _publicationCard(Publication publication) {
    final QuillController controller = QuillController(
      document: Document.fromJson(publication.content),
      selection: const TextSelection.collapsed(offset: 0),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (publication.attachments.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: publication.attachments.length,
                itemBuilder: (context, index) {
                  final imageUrl = publication.attachments[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImageViewerScreen(imageUrl: imageUrl),
                        ),
                      );
                    },
                    child: Hero(
                      tag: imageUrl,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: MediaQuery.of(context).size.width *
                              (publication.attachments.length > 1 ? 0.8 : 1),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(publication.title,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                AbsorbPointer(
                  child: QuillEditor.basic(
                    configurations: QuillEditorConfigurations(
                      controller: controller,
                      // CORRECCIÓN: Quitamos readOnly: true (causaba error)
                      sharedConfigurations: const QuillSharedConfigurations(
                        locale: Locale('es'),
                      ),
                      showCursor: false,
                    ),
                    // CORRECCIÓN: Usamos FocusNode para evitar que el teclado se abra
                    focusNode: FocusNode(canRequestFocus: false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openChat(UserModel professional) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para chatear.')),
      );
      return;
    }

    try {
      final chatId = await _firebaseService.getOrCreateChat(
          currentUserId, professional.id);
      
      // CORRECCIÓN: Verificar mounted antes de usar context
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUserName: professional.name,
            otherUserId: professional.id,
            otherUserImageUrl: professional.profileImageUrl,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el chat: $e')),
      );
    }
  }

  void _showAppointmentRequestDialog(UserModel professional) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Debes iniciar sesión para agendar una cita.')),
      );
      return;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (pickedDate == null) return; // User cancelled

    // Verificar mounted después de un await
    if (!mounted) return;

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
      await _firebaseService.requestAppointment(
          professional.id, currentUserId, finalDateTime);
      
      // CORRECCIÓN: Verificar mounted antes de usar context
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud de cita enviada con éxito.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar la solicitud: $e')),
      );
    }
  }
}