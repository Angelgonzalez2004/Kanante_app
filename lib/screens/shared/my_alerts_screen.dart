import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kanante_app/models/alert_model.dart';
import 'package:kanante_app/services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'alert_detail_screen.dart'; // New screen for alert details

class MyAlertsScreen extends StatefulWidget {
  const MyAlertsScreen({super.key});

  @override
  State<MyAlertsScreen> createState() => _MyAlertsScreenState();
}

class _MyAlertsScreenState extends State<MyAlertsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Debes iniciar sesión para ver tus alertas.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Alertas y Avisos'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800.0),
          child: StreamBuilder<List<AlertModel>>(
            stream: _firebaseService.getAlertsForRecipient(currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No tienes alertas o avisos.'));
              }

              final alerts = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(
                        alert.status == 'unread'
                            ? Icons.notifications_active
                            : alert.status == 'replied'
                                ? Icons.reply_all
                                : Icons.notifications_none,
                        color: alert.status == 'unread' ? Colors.red : Colors.grey,
                      ),
                      title: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alert.message, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('Enviado el: ${DateFormat('dd/MM/yyyy').format(alert.timestamp)}'),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () async {
                        // FIX: Capture navigator before async gap.
                        final navigator = Navigator.of(context);
                        await _firebaseService.markAlertAsRead(alert.id);
                        
                        navigator.push(
                          MaterialPageRoute(
                            builder: (context) => AlertDetailScreen(alert: alert),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}