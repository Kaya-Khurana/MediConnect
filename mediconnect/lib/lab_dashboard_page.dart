// lib/lab_dashboard_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mediconnect/auth_service.dart';
import 'package:intl/intl.dart';

class LabDashboardPage extends StatelessWidget {
  LabDashboardPage({super.key});

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to update status (remains the same)
  Future<void> _updateTestStatus(
      BuildContext context, String docId, String newStatus) async {
    try {
      await _firestore
          .collection('labTestBookings')
          .doc(docId)
          .update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Test booking ${newStatus == 'confirmed' ? 'confirmed' : 'cancelled'}.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }

    // --- NEW: Use DefaultTabController ---
    return DefaultTabController(
      length: 2, // Two tabs: Pending and Confirmed
      child: Scaffold(
        appBar: AppBar(
          title: const Text(''),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          // --- NEW: Add TabBar ---
          bottom: TabBar(
            indicatorColor: Colors.white, // Color of the underline
            labelColor: Colors.white, // Color of selected tab text
            unselectedLabelColor:
                Colors.white70, // Color of unselected tab text
            tabs: const [
              Tab(
                icon: Icon(Icons.hourglass_empty_outlined),
                text: 'Pending Requests',
              ),
              Tab(
                icon: Icon(Icons.calendar_month_outlined),
                text: 'Confirmed Schedule',
              ),
            ],
          ),
          // --- End TabBar ---
        ),
        // --- NEW: Use TabBarView ---
        body: TabBarView(
          children: [
            // --- View 1: Pending Requests ---
            _buildTestList(context, user.uid, 'scheduled'),

            // --- View 2: Confirmed Schedule ---
            _buildTestList(context, user.uid, 'confirmed'),
          ],
        ),
        // --- End TabBarView ---
      ),
    );
  }

  // --- NEW: Reusable function to build the list for a given status ---
  Widget _buildTestList(BuildContext context, String labUid, String status) {
    return StreamBuilder<QuerySnapshot>(
      // Query adjusted based on the 'status' parameter
      stream: _firestore
          .collection('labTestBookings')
          .where('labId', isEqualTo: labUid)
          .where('status', isEqualTo: status)
          // .orderBy('appointmentTime') // Needs index - add back later if needed
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // Check for Firestore index error
          if (snapshot.error.toString().contains('index')) {
            return Center(/* ... Index Error Message ... */);
          }
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text(
            status == 'scheduled'
                ? 'No pending test requests.'
                : 'No confirmed tests scheduled.',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ));
        }

        final tests = snapshot.data!.docs;
        // Sort manually
        tests.sort((a, b) {
          final timeA = (a.data() as Map<String, dynamic>)['appointmentTime']
              as Timestamp;
          final timeB = (b.data() as Map<String, dynamic>)['appointmentTime']
              as Timestamp;
          return timeA.compareTo(timeB); // Oldest to newest
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: tests.length,
          itemBuilder: (context, index) {
            final doc = tests[index];
            final data = doc.data() as Map<String, dynamic>;

            final patientName = data['patientName'] ?? 'Unknown Patient';
            final testName = data['testName'] ?? 'Test unspecified';
            final time = (data['appointmentTime'] as Timestamp).toDate();
            final formattedTime =
                DateFormat('EEE, MMM d, yyyy  h:mm a').format(time);

            // Use different card appearance based on status
            if (status == 'scheduled') {
              // --- Card for Pending Requests ---
              return Card(
                elevation: 4.0,
                margin: const EdgeInsets.only(bottom: 16.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patientName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(formattedTime,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          )),
                      const Divider(height: 20),
                      Text('Test Required: $testName',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 16),
                      Row(
                        // Approve / Deny Buttons
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                _updateTestStatus(context, doc.id, 'cancelled'),
                            child: const Text('Deny',
                                style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () =>
                                _updateTestStatus(context, doc.id, 'confirmed'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white),
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            } else {
              // --- Card for Confirmed Schedule ---
              return Card(
                elevation: 2.0, // Less elevation for confirmed
                color: Colors.green[50], // Light green background
                margin: const EdgeInsets.only(bottom: 16.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child:
                        Icon(Icons.check_circle_outline, color: Colors.green),
                  ),
                  title: Text(patientName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('$formattedTime\nTest: $testName'),
                  isThreeLine: true,
                ),
              );
            }
          },
        );
      },
    );
  }
}
