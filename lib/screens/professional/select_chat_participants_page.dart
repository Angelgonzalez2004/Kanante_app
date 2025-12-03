import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../shared/chat_screen.dart';

class SelectChatParticipantsPage extends StatefulWidget {
  const SelectChatParticipantsPage({super.key});

  @override
  State<SelectChatParticipantsPage> createState() => _SelectChatParticipantsPageState();
}

class _SelectChatParticipantsPageState extends State<SelectChatParticipantsPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<UserModel>> _usersFuture;
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  Timer? _debounce;
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _usersFuture = _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  Future<List<UserModel>> _loadUsers() async {
    final users = await _firebaseService.getAllUsers();
    setState(() {
      _allUsers = users.where((user) => user.id != _currentUserId).toList(); // Exclude current user
      _filteredUsers = _allUsers;
    });
    return _allUsers;
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredUsers = _allUsers.where((user) {
          return user.name.toLowerCase().contains(query) ||
                 user.accountType.toLowerCase().contains(query) ||
                 user.specialties.any((s) => s.toLowerCase().contains(query));
        }).toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Nuevo Chat', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        elevation: 2,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildUsersList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, tipo o especialidad...',
          prefixIcon: const Icon(Icons.search, color: Colors.teal),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return FutureBuilder<List<UserModel>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar usuarios: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No se encontraron usuarios.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          itemCount: _filteredUsers.length,
          itemBuilder: (context, index) {
            final user = _filteredUsers[index];
            return _userCard(user);
          },
        );
      },
    );
  }

  Widget _userCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () async {
          final chatId = await _firebaseService.getOrCreateChat(_currentUserId, user.id);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatId: chatId,
                  otherUserName: user.name,
                  otherUserImageUrl: user.profileImageUrl,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.teal.shade100,
                backgroundImage: user.profileImageUrl != null
                    ? CachedNetworkImageProvider(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null
                    ? const Icon(Icons.person, size: 35, color: Colors.teal)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.accountType,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                    if (user.specialties.isNotEmpty)
                      Text(
                        user.specialties.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chat_bubble_outline, color: Colors.teal),
            ],
          ),
        ),
      ),
    );
  }
}
