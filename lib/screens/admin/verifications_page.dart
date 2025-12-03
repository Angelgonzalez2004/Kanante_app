import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../models/user_model.dart';
import 'verification_detail_page.dart'; 

class VerificationsPage extends StatefulWidget {
  const VerificationsPage({super.key});

  @override
  State<VerificationsPage> createState() => _VerificationsPageState();
}

class _VerificationsPageState extends State<VerificationsPage> {
  final _db = FirebaseDatabase.instance.ref();
  late Future<List<UserModel>> _pendingProfessionals;

  @override
  void initState() {
    super.initState();
    _pendingProfessionals = _fetchPendingProfessionals();
  }

  Future<List<UserModel>> _fetchPendingProfessionals() async {
    try {
      final snapshot = await _db
          .child('users')
          .orderByChild('verificationStatus')
          .equalTo('pending')
          .get();

      if (!snapshot.exists) {
        return [];
      }

      final professionals = <UserModel>[];
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((key, value) {
        // Only add if they are indeed a Professional
        if (value['accountType'] == 'Profesional') {
          professionals.add(UserModel.fromMap(key, Map<String, dynamic>.from(value)));
        }
      });
      return professionals;
    } catch (e) {
      // Handle error, maybe show a snackbar
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profesionales Pendientes'),
        backgroundColor: Colors.indigo,
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _pendingProfessionals,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Ocurrió un error al cargar los datos.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No hay profesionales pendientes de verificación.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final professionals = snapshot.data!;

          return ListView.builder(
            itemCount: professionals.length,
            itemBuilder: (context, index) {
              final professional = professionals[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: professional.profileImageUrl != null
                        ? NetworkImage(professional.profileImageUrl!)
                        : null,
                    child: professional.profileImageUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(professional.name),
                  subtitle: Text(professional.email),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => VerificationDetailPage(professionalId: professional.id),
                      ),
                    ).then((_) {
                      // Refresh the list when coming back
                      setState(() {
                        _pendingProfessionals = _fetchPendingProfessionals();
                      });
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
