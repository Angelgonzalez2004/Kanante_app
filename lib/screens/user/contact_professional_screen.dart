import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/fade_in_slide.dart';
import 'professional_profile_page.dart';

class ContactProfessionalScreen extends StatefulWidget {
  const ContactProfessionalScreen({super.key});

  @override
  State<ContactProfessionalScreen> createState() => _ContactProfessionalScreenState();
}

class _ContactProfessionalScreenState extends State<ContactProfessionalScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _allProfessionals = [];
  List<UserModel> _filteredProfessionals = [];
  Timer? _debounce;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfessionals();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadProfessionals() async {
    final professionals = await _firebaseService.getAllProfessionals();
    if (mounted) {
      setState(() {
        _allProfessionals = professionals;
        _filteredProfessionals = professionals;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredProfessionals = _allProfessionals.where((prof) {
          return prof.name.toLowerCase().contains(query) || 
                 prof.specialties.any((s) => s.toLowerCase().contains(query));
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
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildProfessionalsList()),
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
          hintText: 'Buscar por nombre o especialidad...',
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

  Widget _buildProfessionalsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_allProfessionals.isEmpty) {
      return const Center(child: Text('No se encontraron profesionales.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemCount: _filteredProfessionals.length,
      itemBuilder: (context, index) {
        final professional = _filteredProfessionals[index];
        return FadeInSlide(
          delay: Duration(milliseconds: index * 100),
          child: _professionalCard(professional),
        );
      },
    );
  }

  Widget _professionalCard(UserModel professional) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfessionalProfilePage(professionalId: professional.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Hero(
                tag: professional.profileImageUrl ?? professional.id,
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.teal.shade100,
                  backgroundImage: professional.profileImageUrl != null
                      ? CachedNetworkImageProvider(professional.profileImageUrl!)
                      : null,
                  child: professional.profileImageUrl == null
                      ? const Icon(Icons.person, size: 35, color: Colors.teal)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professional.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (professional.specialties.isNotEmpty)
                      Text(
                        professional.specialties.join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.teal),
            ],
          ),
        ),
      ),
    );
  }
}