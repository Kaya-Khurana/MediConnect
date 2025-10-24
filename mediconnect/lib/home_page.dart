import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mediconnect/auth_service.dart';
import 'package:mediconnect/admin_dashboard.dart';
import 'package:mediconnect/find_doctor_page.dart';
import 'package:mediconnect/appointment_requests_page.dart';
import 'package:mediconnect/my_appointments_page.dart';
import 'package:mediconnect/my_schedule_page.dart';
import 'package:mediconnect/write_prescription_page.dart';
import 'package:mediconnect/my_prescriptions_page.dart';
import 'package:mediconnect/find_lab_page.dart';
import 'package:mediconnect/lab_dashboard_page.dart';
import 'package:mediconnect/pending_approval_page.dart'; // <-- Import Pending Page

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      // AuthGate should handle this, but provide a fallback
      return const Scaffold(body: Center(child: Text("Not logged in.")));
    }

    // Use a top-level Scaffold for loading/error states before data fetch
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          // --- Handle Loading State ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          // --- Handle Error State ---
          if (snapshot.hasError) {
            return Scaffold(
                body: Center(
                    child:
                        Text("Error fetching user data: ${snapshot.error}")));
          }
          // --- Handle Missing User Data State ---
          if (!snapshot.hasData || !snapshot.data!.exists) {
            print(
                "Error: User document not found in Firestore for UID ${user.uid}");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              authService.signOut();
            });
            return const Scaffold(
                body: Center(
                    child:
                        Text("Error: User data missing. Please login again.")));
          }

          // --- User Data Loaded Successfully ---
          Map<String, dynamic> userData =
              snapshot.data!.data() as Map<String, dynamic>;
          String role = userData['role'] ?? 'user';
          String name = userData['firstName'] ?? 'User';
          // Default approved to false if field is missing, except for patients
          bool isApproved = userData['isApproved'] ?? (role == 'patient');

          // --- Determine which page content to show ---
          Widget pageToShow;
          String appBarTitle;
          bool showLogout = true; // Show logout by default
          bool showBackButton = false; // Don't show back on main dashboards

          // 1. Check if approval is required and pending
          if (!isApproved &&
              (role == 'pending_doctor' ||
                  role == 'pending_lab' ||
                  role == 'doctor' ||
                  role == 'lab')) {
            pageToShow = const PendingApprovalPage();
            appBarTitle = 'Account Pending';
            showLogout = false; // Pending page has its own logout
            showBackButton = false;
          }
          // 2. Check for specific roles if approved
          else if (role == 'admin') {
            pageToShow = AdminDashboard(adminUid: user.uid);
            appBarTitle = 'Admin Portal';
          } else if (role == 'lab') {
            pageToShow = LabDashboardPage();
            appBarTitle = 'Lab Dashboard';
          } else {
            // Doctor (approved) or Patient
            pageToShow = _buildPatientDoctorDashboard(context, name, role);
            appBarTitle =
                (role == 'doctor') ? 'Doctor Dashboard' : 'MediConnect';
          }

          // Build the final Scaffold with the correct AppBar and Body
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              title: Text(appBarTitle),
              automaticallyImplyLeading: showBackButton, // Control back arrow
              actions: [
                if (showLogout) // Only show if not pending page
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Logout',
                    onPressed: () {
                      authService.signOut();
                    },
                  )
              ],
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: pageToShow, // Use the determined page widget
          );
          // --- END OF UPDATED LOGIC ---
        },
      ),
    );
  }

  // --- This function builds the Patient and Doctor Dashboards ---
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
          'title': 'Book Lab Test',
          'subtitle': 'Find nearby labs',
          'icon': Icons.biotech_outlined,
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
                        } else if (action['title'] == 'Prescriptions') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MyPrescriptionsPage()),
                          );
                        } else if (action['title'] == 'Book Lab Test') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const FindLabPage()),
                          );
                        }
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
                        // --- Placeholder ---
                        else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Navigating to ${action['title']}')),
                          );
                        }
                      },
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

  // --- Action Card Widget (No changes needed) ---
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
