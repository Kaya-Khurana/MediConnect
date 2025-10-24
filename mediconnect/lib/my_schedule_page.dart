import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mediconnect/auth_service.dart';
import 'package:intl/intl.dart'; // For formatting dates

class MySchedulePage extends StatelessWidget {
  MySchedulePage({super.key});

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(
          body: Center(child: Text('You must be logged in.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query for appointments for THIS doctor that are 'confirmed'
        stream: _firestore
            .collection('appointments')
            .where('doctorId', isEqualTo: user.uid)
            .where('status',
                isEqualTo: 'confirmed') // <<<--- Only confirmed ones
            // .orderBy('appointmentTime') // <<<--- REMOVED for now (needs index)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // --- NEW: Check for Index Error ---
            if (snapshot.error.toString().contains('index')) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Firestore Error:\n\nThe required index for this query is missing.\n\nPlease check the VS Code DEBUG CONSOLE for a link to create it automatically in Firebase.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              );
            }
            // --- End of Index Error Check ---
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'You have no confirmed appointments scheduled.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final appointments = snapshot.data!.docs;
          // Sort the appointments here in the code since we removed orderBy
          appointments.sort((a, b) {
            final timeA = (a.data() as Map<String, dynamic>)['appointmentTime']
                as Timestamp;
            final timeB = (b.data() as Map<String, dynamic>)['appointmentTime']
                as Timestamp;
            return timeA.compareTo(timeB); // Sorts oldest to newest
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final doc = appointments[index];
              final data = doc.data() as Map<String, dynamic>;

              final patientName = data['patientName'];
              final reason = data['reason'];
              final time = (data['appointmentTime'] as Timestamp).toDate();
              final formattedTime =
                  DateFormat('EEE, MMM d, yyyy  at  h:mm a').format(time);

              // --- Display Card for Confirmed Appointment ---
              return Card(
                elevation: 3.0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(
                        color: Colors.green.shade100, width: 1) // Green border
                    ),
                margin: const EdgeInsets.only(bottom: 16.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[50],
                    child: Icon(Icons.check_circle_outline,
                        color: Colors.green[600]),
                  ),
                  title: Text(
                    patientName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '$formattedTime\nReason: $reason',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
