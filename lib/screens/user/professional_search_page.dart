import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../shared/chat_screen.dart';

class ProfessionalSearchPage extends StatefulWidget {
  const ProfessionalSearchPage({super.key});

  @override
  State<ProfessionalSearchPage> createState() => _ProfessionalSearchPageState();
}

class _ProfessionalSearchPageState extends State<ProfessionalSearchPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  Future<List<UserModel>>? _searchResults; 

  @override
  void initState() {
    super.initState();
    _searchResults = _firebaseService.searchProfessionals(query: '');
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchResults = _firebaseService.searchProfessionals(query: query);
    });
  }

  void _navigateToChat(UserModel professional) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final chatId = await _firebaseService.getOrCreateChat(currentUserId, professional.id);
    
    if (!mounted) return; // Add this line
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          otherUserName: professional.name,
          otherUserImageUrl: professional.profileImageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Profesionales'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o especialidad...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _searchResults,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al buscar profesionales.'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No se encontraron profesionales.'));
                }

                final professionals = snapshot.data!;
                return ListView.builder(
                  itemCount: professionals.length,
                  itemBuilder: (context, index) {
                    final professional = professionals[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundImage: professional.profileImageUrl != null
                              ? CachedNetworkImageProvider(professional.profileImageUrl!)
                              : null,
                          child: professional.profileImageUrl == null
                              ? const Icon(Icons.person, size: 30)
                              : null,
                        ),
                        title: Text(professional.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(professional.specialties.join(', ')),
                        onTap: () => _navigateToChat(professional),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}