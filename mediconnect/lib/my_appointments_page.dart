// lib/my_appointments_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mediconnect/auth_service.dart';
import 'package:intl/intl.dart'; // For formatting dates

class MyAppointmentsPage extends StatelessWidget {
  MyAppointmentsPage({super.key});

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper widget to show the status chip (No change needed)
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
    // ... (rest of _buildStatusChip code remains the same)
    return Chip(
      avatar: Icon(iconData, color: Colors.white, size: 18),
      label: Text(
        statusText,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(
          horizontal: 6, vertical: 2), // Adjust padding
      labelPadding:
          const EdgeInsets.only(left: 2, right: 4), // Adjust label padding
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(
          body: Center(child: Text('You must be logged in.')));
    }

    // --- Stream for Doctor Appointments ---
    final doctorAppointmentsStream = _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: user.uid)
        .snapshots();

    // --- Stream for Lab Test Bookings ---
    final labTestsStream = _firestore
        .collection('labTestBookings')
        .where('patientId', isEqualTo: user.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'), // Renamed AppBar
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: doctorAppointmentsStream,
        builder: (context, doctorSnapshot) {
          // --- Also listen to the Lab Test stream ---
          return StreamBuilder<QuerySnapshot>(
            stream: labTestsStream,
            builder: (context, labSnapshot) {
              // --- Handle Loading States ---
              if (doctorSnapshot.connectionState == ConnectionState.waiting ||
                  labSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // --- Handle Errors ---
              if (doctorSnapshot.hasError || labSnapshot.hasError) {
                // Check for index errors specifically if needed
                if (doctorSnapshot.error.toString().contains('index') ||
                    labSnapshot.error.toString().contains('index')) {
                  // Display index error message
                  return const Center(/* ... Index Error Message ... */);
                }
                return Center(
                    child: Text(
                        'Error: ${doctorSnapshot.error ?? labSnapshot.error}'));
              }

              // --- Combine and Sort Data ---
              List<QueryDocumentSnapshot> combinedList = [];
              if (doctorSnapshot.hasData) {
                combinedList.addAll(doctorSnapshot.data!.docs);
              }
              if (labSnapshot.hasData) {
                combinedList.addAll(labSnapshot.data!.docs);
              }

              if (combinedList.isEmpty) {
                return const Center(
                  child: Text(
                    'You have no bookings yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }

              // Sort the combined list by date
              combinedList.sort((a, b) {
                Timestamp timeA =
                    (a.data() as Map<String, dynamic>)['appointmentTime'];
                Timestamp timeB =
                    (b.data() as Map<String, dynamic>)['appointmentTime'];
                return timeB.compareTo(timeA); // Show newest first
              });
              // --- End Combine and Sort ---

              // --- Build the List View ---
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: combinedList.length,
                itemBuilder: (context, index) {
                  final doc = combinedList[index];
                  final data = doc.data() as Map<String, dynamic>;

                  // Determine if it's a doctor or lab booking
                  bool isDoctorAppointment = data.containsKey('doctorId');
                  bool isLabTest = data.containsKey('labId');

                  // Extract common data
                  final status = data['status'] ?? 'unknown';
                  final time = (data['appointmentTime'] as Timestamp).toDate();
                  final formattedTime =
                      DateFormat('EEE, MMM d, yyyy  at  h:mm a').format(time);

                  // Extract specific data
                  String title;
                  String subtitle;
                  IconData leadingIcon;
                  Color iconColor;

                  if (isDoctorAppointment) {
                    title = data['doctorName'] ?? 'Unknown Doctor';
                    subtitle = 'Reason: ${data['reason'] ?? 'Not specified'}';
                    leadingIcon = Icons.medical_services_outlined;
                    iconColor =
                        Colors.blue; // Or Theme.of(context).primaryColor
                  } else if (isLabTest) {
                    title = data['labName'] ?? 'Unknown Lab';
                    subtitle = 'Test: ${data['testName'] ?? 'Not specified'}';
                    leadingIcon = Icons.biotech_outlined;
                    iconColor = Colors.orange;
                  } else {
                    // Fallback for unexpected data
                    title = 'Unknown Booking';
                    subtitle = 'Details unavailable';
                    leadingIcon = Icons.help_outline;
                    iconColor = Colors.grey;
                  }

                  // --- Display Card (Unified Look) ---
                  return Card(
                    elevation: 3.0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                // Icon indicating type
                                radius: 20,
                                backgroundColor: iconColor.withOpacity(0.15),
                                child: Icon(leadingIcon,
                                    color: iconColor, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  title, // Doctor or Lab Name
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusChip(status), // Status chip
                            ],
                          ),
                          const Divider(height: 20),
                          Text(
                            formattedTime, // Date and Time
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle, // Reason or Test Name
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
              // --- End Build List View ---
            },
          );
        },
      ),
    );
  }
}
