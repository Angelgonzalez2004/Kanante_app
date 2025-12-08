import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kanante_app/models/user_model.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:kanante_app/screens/professional/profile_page.dart';
import 'package:kanante_app/screens/professional/professional_publications_list_screen.dart';
import 'package:kanante_app/screens/shared/chat_screen.dart';
import 'package:kanante_app/models/review_model.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

class ProfessionalProfileViewerPage extends StatefulWidget {
  final String professionalUid;

  const ProfessionalProfileViewerPage({super.key, required this.professionalUid});

  @override
  State<ProfessionalProfileViewerPage> createState() => _ProfessionalProfileViewerPageState();
}

class _ProfessionalProfileViewerPageState extends State<ProfessionalProfileViewerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _currentAppUser;
  UserModel? _viewingProfessional;
  bool _isLoading = true;
  String? _chatId;
  double? _averageRating;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
    _loadAverageRating();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      _currentAppUser = await _firebaseService.getUserProfile(firebaseUser.uid);
      if (_currentAppUser != null && _currentAppUser!.id != widget.professionalUid) {
        _chatId = await _firebaseService.getOrCreateChat(_currentAppUser!.id, widget.professionalUid);
      }
    }
    _viewingProfessional = await _firebaseService.getUserProfile(widget.professionalUid);
    setState(() => _isLoading = false);
  }

  Future<void> _loadAverageRating() async {
    final double? avg = await _firebaseService.getAverageRatingForProfessional(widget.professionalUid);
    if (mounted) {
      setState(() {
        _averageRating = avg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_viewingProfessional == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil no encontrado')),
        body: const Center(child: Text('No se pudo cargar la información del profesional.')),
      );
    }

    final bool isUserAndNotSelf = _currentAppUser != null &&
                                  _currentAppUser!.accountType == 'Usuario' &&
                                  _currentAppUser!.id != _viewingProfessional!.id;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_viewingProfessional!.name),
            if (_averageRating != null)
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _averageRating!.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Publicaciones', icon: Icon(Icons.article)),
            Tab(text: 'Perfil', icon: Icon(Icons.person)),
            Tab(text: 'Mensajes', icon: Icon(Icons.message)),
            Tab(text: 'Reseñas', icon: Icon(Icons.star)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ProfessionalPublicationsListScreen(professionalUid: widget.professionalUid),
          ProfessionalProfilePage(professionalUid: widget.professionalUid),
          Builder(
            builder: (BuildContext innerContext) {
              if (isUserAndNotSelf && _chatId != null) {
                return ChatScreen(
                  chatId: _chatId!,
                  otherUserName: _viewingProfessional!.name,
                  otherUserId: _viewingProfessional!.id,
                  otherUserImageUrl: _viewingProfessional!.profileImageUrl,
                  isProfessionalChat: true,
                );
              } else if (!isUserAndNotSelf) {
                return const Center(child: Text('No puedes enviar mensajes a este perfil.'));
              } else {
                return const Center(child: Text('Cargando chat...'));
              }
            },
          ),
          _buildReviewsTab(),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return FutureBuilder<List<Review>>(
      future: _firebaseService.getReviewsForProfessional(widget.professionalUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar reseñas: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Este profesional aún no tiene reseñas.'));
        }

        final reviews = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FutureBuilder<UserModel?>(
                          future: _firebaseService.getUserProfile(review.userId),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                              return const Text('Cargando usuario...');
                            }
                            if (userSnapshot.hasData && userSnapshot.data != null) {
                              return Text(userSnapshot.data!.name, style: const TextStyle(fontWeight: FontWeight.bold));
                            }
                            return const Text('Usuario Anónimo', style: TextStyle(fontWeight: FontWeight.bold));
                          },
                        ),
                        RatingBarIndicator(
                          rating: review.rating,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 20.0,
                          direction: Axis.horizontal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (review.comment != null && review.comment!.isNotEmpty)
                      Text(review.comment!),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(review.timestamp),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}