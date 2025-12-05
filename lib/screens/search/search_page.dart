import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _allPublications = [
    'Psicología moderna', 'Ayuda psicológica', 'Estrés y ansiedad', 'Consejos para dormir', 'Manejo de emociones'
  ]; // Mock data
  List<String> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchResults = _allPublications;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchPublications(_searchController.text);
  }

  void _searchPublications(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = _allPublications;
      });
      return;
    }
    setState(() {
      _searchResults = _allPublications
          .where((publication) =>
              publication.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Publicaciones'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por título o palabra clave...',
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
                          _searchPublications('');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_searchResults[index]),
            onTap: () {
              // TODO: Navigate to PublicationDetailPage with actual publication data
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Navegar a: ${_searchResults[index]}')),
              );
            },
          );
        },
      ),
    );
  }
}
