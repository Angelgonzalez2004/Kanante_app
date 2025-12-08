import 'package:flutter/material.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:kanante_app/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart'; // For profile images
import 'package:kanante_app/screens/professional/professional_profile_viewer_page.dart'; // To navigate to professional profile


class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  List<UserModel> _allProfessionals = [];
  List<UserModel> _searchResults = [];
  bool _isLoading = true;
  String? _selectedSpecialtyFilter;

  // Assume a list of all possible specialties for the filter dropdown
  final List<String> _allSpecialties = const [
    'Psicología Clínica', 'Psicoterapia', 'Neuropsicología', 'Psiquiatría', 'Terapia Familiar', 'Todas'
  ]; 

  @override
  void initState() {
    super.initState();
    _loadAllProfessionals();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllProfessionals() async {
    setState(() => _isLoading = true);
    try {
      _allProfessionals = await _firebaseService.getAllProfessionals();
      setState(() {
        _searchResults = _allProfessionals;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar profesionales: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    _searchProfessionals(_searchController.text);
  }

  void _searchProfessionals(String query) {
    List<UserModel> filteredByQuery = [];
    if (query.isEmpty) {
      filteredByQuery = _allProfessionals;
    } else {
      filteredByQuery = _allProfessionals.where((professional) {
        return professional.name.toLowerCase().contains(query.toLowerCase()) ||
               professional.email.toLowerCase().contains(query.toLowerCase()) ||
               (professional.specialties.any((s) => s.toLowerCase().contains(query.toLowerCase())));
      }).toList();
    }
    
    // Apply specialty filter
    if (_selectedSpecialtyFilter != null && _selectedSpecialtyFilter != 'Todas') {
      _searchResults = filteredByQuery.where((professional) {
        return professional.specialties.contains(_selectedSpecialtyFilter);
      }).toList();
    } else {
      _searchResults = filteredByQuery;
    }
    setState(() {}); // Update UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Profesionales'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight * 2), // Increased height for filter
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, especialidad o email...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchProfessionals('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSpecialtyFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por Especialidad',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _allSpecialties.map((String specialty) {
                    return DropdownMenuItem<String>(
                      value: specialty,
                      child: Text(specialty),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSpecialtyFilter = newValue;
                      _searchProfessionals(_searchController.text); // Re-run search with new filter
                    });
                  },
                ),
              ),
              const SizedBox(height: 8), // Spacing below filter
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(child: Text(_searchController.text.isEmpty && _selectedSpecialtyFilter == null
                  ? 'No hay profesionales disponibles.'
                  : 'No se encontraron profesionales.'))
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final professional = _searchResults[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: professional.profileImageUrl != null
                              ? CachedNetworkImageProvider(professional.profileImageUrl!)
                              : null,
                          child: professional.profileImageUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(professional.name),
                        subtitle: Text(professional.specialties.join(', ')),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfessionalProfileViewerPage(professionalUid: professional.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

