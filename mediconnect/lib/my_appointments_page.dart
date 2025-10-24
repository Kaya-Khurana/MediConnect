import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mediconnect/auth_service.dart';
import 'package:intl/intl.dart'; // For formatting dates

class MyAppointmentsPage extends StatelessWidget {
  MyAppointmentsPage({super.key});

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper widget to show the status
  Widget _buildStatusChip(String status) {
    Color chipColor;
    String statusText;
    IconData iconData;

    switch (status) {
      case 'scheduled':
        chipColor = Colors.orange;
        statusText = 'Pending';
        iconData = Icons.hourglass_empty;
        break;
      case 'confirmed':
        chipColor = Colors.green;
        statusText = 'Confirmed';
        iconData = Icons.check_circle_outline;
        break;
      case 'cancelled':
        chipColor = Colors.red;
        statusText = 'Cancelled';
        iconData = Icons.cancel_outlined;
        break;
      default:
        chipColor = Colors.grey;
        statusText = 'Unknown';
        iconData = Icons.help_outline;
    }

    return Chip(
      avatar: Icon(iconData, color: Colors.white, size: 18),
      label: Text(
        statusText,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: chipColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(
          body: Center(child: Text('You must be logged in.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query for appointments for THIS patient
        stream: _firestore
            .collection('appointments')
            .where('patientId', isEqualTo: user.uid) // Show newest first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'You have no appointments.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final appointments = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final doc = appointments[index];
              final data = doc.data() as Map<String, dynamic>;

              final doctorName = data['doctorName'];
              final reason = data['reason'];
              final status = data['status'];
              final time = (data['appointmentTime'] as Timestamp).toDate();
              final formattedTime =
                  DateFormat('EEE, MMM d, yyyy  at  h:mm a').format(time);

              return Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              doctorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          _buildStatusChip(status), // Our new status chip
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Divider(height: 20),
                      Text(
                        'Reason: $reason',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
