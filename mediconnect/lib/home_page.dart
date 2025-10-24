import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mediconnect/auth_service.dart';
import 'package:mediconnect/admin_dashboard.dart';
import 'package:mediconnect/find_doctor_page.dart';
import 'package:mediconnect/appointment_requests_page.dart';
import 'package:mediconnect/my_appointments_page.dart';
import 'package:mediconnect/my_schedule_page.dart';
import 'package:mediconnect/write_prescription_page.dart';
import 'package:mediconnect/my_prescriptions_page.dart'; // <-- Ensure this is imported

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Error: Not logged in.")));
    }

    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Could not find user data."));
          }

          Map<String, dynamic> userData =
              snapshot.data!.data() as Map<String, dynamic>;
          String role = userData['role'] ?? 'user';
          String name = userData['firstName'] ?? 'User';

          Widget dashboardBody;
          if (role == 'admin') {
            dashboardBody = AdminDashboard(adminUid: user.uid);
          } else {
            dashboardBody = _buildPatientDoctorDashboard(context, name, role);
          }

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              title: Text(role == 'admin'
                  ? 'Admin Portal'
                  : (role == 'doctor' ? 'Doctor Dashboard' : 'MediConnect')),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () {
                    authService.signOut();
                  },
                )
              ],
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: dashboardBody,
          );
        },
      ),
    );
  }

  Widget _buildPatientDoctorDashboard(
      BuildContext context, String name, String role) {
    final List<Map<String, dynamic>> actions;

    if (role == 'doctor') {
      // Doctor actions list...
      actions = [
        {
          'title': 'Appointment Requests',
          'subtitle': 'Approve or deny requests',
          'icon': Icons.playlist_add_check_outlined,
          'color': Colors.blue,
        },
        {
          'title': 'My Schedule',
          'subtitle': 'Manage your availability',
          'icon': Icons.calendar_month_outlined,
          'color': Colors.purple,
        },
        {
          'title': 'Write Prescription',
          'subtitle': 'Create new e-prescriptions',
          'icon': Icons.edit_note_outlined,
          'color': Colors.green,
        },
        {
          'title': 'Patient History',
          'subtitle': 'View patient records',
          'icon': Icons.people_alt_outlined,
          'color': Colors.orange,
        },
      ];
    } else {
      // Patient actions list...
      actions = [
        {
          'title': 'Find a Doctor',
          'subtitle': 'Book an appointment',
          'icon': Icons.search,
          'color': Colors.blue,
        },
        {
          'title': 'My Appointments',
          'subtitle': 'View upcoming visits',
          'icon': Icons.calendar_today,
          'color': Colors.purple,
        },
        {
          'title': 'Medical Records',
          'subtitle': 'View your history',
          'icon': Icons.folder_shared_outlined,
          'color': Colors.orange,
        },
        {
          'title': 'Prescriptions',
          'subtitle': 'View your e-scripts',
          'icon': Icons.medication_outlined,
          'color': Colors.green,
        },
      ];
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 900,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello,',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Text(
                  name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'What would you like to do today?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[800],
                      ),
                ),
                const SizedBox(height: 32),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: actions.length,
                  itemBuilder: (context, index) {
                    final action = actions[index];
                    return _buildActionCard(
                      context,
                      title: action['title'],
                      subtitle: action['subtitle'],
                      icon: action['icon'],
                      color: action['color'],
                      // --- THIS IS THE UPDATED onTap FUNCTION ---
                      onTap: () {
                        // --- Patient Navigation ---
                        if (action['title'] == 'Find a Doctor') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const FindDoctorPage()),
                          );
                        } else if (action['title'] == 'My Appointments') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MyAppointmentsPage()),
                          );
                        }
                        // --- Link Prescriptions Page ---
                        else if (action['title'] == 'Prescriptions') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MyPrescriptionsPage()),
                          );
                        }
                        // --- END OF Link ---

                        // --- Doctor Navigation ---
                        else if (action['title'] == 'Appointment Requests') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    AppointmentRequestsPage()),
                          );
                        } else if (action['title'] == 'My Schedule') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MySchedulePage()),
                          );
                        } else if (action['title'] == 'Write Prescription') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const WritePrescriptionPage()),
                          );
                        }

                        // --- Placeholder for other buttons ---
                        else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Navigating to ${action['title']}')),
                          );
                        }
                      },
                      // --- END OF UPDATE ---
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(20.0),
        onTap: onTap, // Uses the updated onTap logic
        splashColor: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(
                  icon,
                  size: 30,
                  color: color,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
