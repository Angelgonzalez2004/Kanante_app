import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  late final FirebaseService _firebaseService;
  late Future<List<UserModel>> _patientsFuture;

  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseService();
    _patientsFuture = _fetchPatients();
  }

  Future<List<UserModel>> _fetchPatients() async {
    // Get the current professional's ID from Firebase Auth
    final professionalId = FirebaseAuth.instance.currentUser?.uid;
    if (professionalId == null) {
      // If for some reason there is no user logged in, return an empty list
      // or handle the error appropriately.
      throw Exception("Profesional no autenticado.");
    }
    return _firebaseService.getPatientsForProfessional(professionalId);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final titleStyle = TextStyle(
      fontSize: MediaQuery.of(context).size.width * 0.06,
      fontWeight: FontWeight.bold,
      color: Colors.teal,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mis Pacientes', style: titleStyle),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _patientsFuture,
              builder: (context, snapshot) {
                // Loading State
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error State
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error al cargar pacientes: ${snapshot.error}'),
                  );
                }

                // Empty State
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No tienes pacientes asignados aún.'),
                  );
                }

                // Data State
                final patients = snapshot.data!;
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 2 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isWide ? 4 : 5,
                  ),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return _patientCard(patient);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientCard(UserModel patient) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to patient detail screen
          // Navigator.push(context, MaterialPageRoute(builder: (_) => PatientDetailPage(patientId: patient.id)));
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.teal.shade100,
                backgroundImage: patient.profileImageUrl != null
                    ? CachedNetworkImageProvider(patient.profileImageUrl!)
                    : null,
                child: patient.profileImageUrl == null
                    ? const Icon(Icons.person, color: Colors.teal, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${patient.id}', // Example detail
                      style: TextStyle(color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
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