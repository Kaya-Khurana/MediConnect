// lib/admin_dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  final String adminUid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminDashboard({
    super.key,
    required this.adminUid,
  });

  // --- Function to handle approval/rejection (Keep as is) ---
  Future<void> _updateApprovalStatus(BuildContext context, String uid,
      String currentRole, bool approve) async {
    // ... (Keep the existing approval/rejection logic) ...
    try {
      if (approve) {
        String finalRole = (currentRole == 'pending_doctor') ? 'doctor' : 'lab';
        await _firestore
            .collection('users')
            .doc(uid)
            .update({'role': finalRole, 'isApproved': true});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('User Approved.'), backgroundColor: Colors.green));
      } else {
        await _firestore.collection('users').doc(uid).delete();
        if (currentRole == 'pending_doctor') {
          final profileDoc = _firestore.collection('doctorProfiles').doc(uid);
          if ((await profileDoc.get()).exists) await profileDoc.delete();
        } else if (currentRole == 'pending_lab') {
          final profileDoc = _firestore.collection('labProfiles').doc(uid);
          if ((await profileDoc.get()).exists) await profileDoc.delete();
        }
        print("User $uid rejected. REMEMBER TO DELETE FROM AUTHENTICATION.");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('User Rejected and Data Deleted.'),
            backgroundColor: Colors.orange));
      }
    } catch (e) {
      print("Error updating approval: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Users, Professionals (combined), Approvals
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          bottom: TabBar(
            indicatorColor: Theme.of(context).primaryColor,
            labelColor: Colors.black87,
            unselectedLabelColor: Colors.grey[600],
            tabs: [
              Tab(
                  icon: Icon(Icons.people_alt_outlined),
                  text: 'Users'), // Patients + Approved Staff
              Tab(
                  icon: Icon(Icons.work_outline),
                  text: 'Professionals'), // Doctors + Labs
              Tab(icon: Icon(Icons.rule_folder_outlined), text: 'Approvals'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- Tab 1: Approved Users (Patients, Doctors, Labs) ---
            _buildCollectionList(
              context,
              // Query users collection where approved is true
              _firestore
                  .collection('users')
                  .where('isApproved', isEqualTo: true)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              (doc) => _buildUserTile(context, doc), // Use the user tile
            ),

            // --- Tab 2: Professionals (Doctors + Labs from their profile collections) ---
            _buildProfessionalsTab(context),

            // --- Tab 3: Pending Approvals ---
            _buildCollectionList(
              context,
              // Query users collection where approved is false
              _firestore
                  .collection('users')
                  .where('isApproved', isEqualTo: false)
                  .snapshots(),
              (doc) =>
                  _buildApprovalTile(context, doc), // Use the approval tile
            ),
          ],
        ),
      ),
    );
  }

  // Reusable list builder (handles loading, error, empty)
  Widget _buildCollectionList(
    BuildContext context,
    Stream<QuerySnapshot> stream,
    Widget Function(DocumentSnapshot) tileBuilder,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // Check for index errors first
          if (snapshot.error.toString().contains('index')) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Firestore Error:\n\nThe required index for this query is missing.\n\nPlease check the VS Code DEBUG CONSOLE for a link to create it automatically in Firebase, or create it manually.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 15),
                ),
              ),
            );
          }
          // General error
          print("Firestore Stream Error: ${snapshot.error}"); // Log the error
          return Center(
              child: Text(
                  'Error loading data.\nPlease check Firestore Rules or Console Logs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No data found for this view.',
                  style: TextStyle(color: Colors.grey)));
        }

        // Build the list if data exists
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data!.docs[index];
            try {
              return tileBuilder(doc); // Build the specific tile
            } catch (e) {
              print("Error building tile for doc ${doc.id}: $e");
              return ListTile(
                  title: Text("Error displaying item ${doc.id}",
                      style: TextStyle(color: Colors.red))); // Show error tile
            }
          },
        );
      },
    );
  }

  // Widget for the combined Professionals Tab (Doctors + Labs)
  Widget _buildProfessionalsTab(BuildContext context) {
    // Stream for approved doctors (from users collection)
    final doctorsUserStream = _firestore
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('isApproved', isEqualTo: true)
        .snapshots();

    // Stream for approved labs (from users collection)
    final labsUserStream = _firestore
        .collection('users')
        .where('role', isEqualTo: 'lab')
        .where('isApproved', isEqualTo: true)
        .snapshots();

    // We display them in separate lists for simplicity
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text("Doctors",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          // Use _buildUserTile here as we are querying the 'users' collection
          _buildCollectionList(context, doctorsUserStream,
              (doc) => _buildUserTile(context, doc)),

          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
            child: Text("Laboratories",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          // Use _buildUserTile here as well
          _buildCollectionList(
              context, labsUserStream, (doc) => _buildUserTile(context, doc)),
        ],
      ),
    );
  }

  // --- Tile Widgets ---

  // User Tile (Shows role icon/color, includes delete for non-admins)
  Widget _buildUserTile(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = '${data['firstName']} ${data['lastName']}';
    final email = data['email'] ?? 'No email';
    final role = data['role'] ?? 'user';
    final isCurrentAdmin = doc.id == adminUid;

    IconData roleIcon = Icons.person_outline;
    Color roleColor = Colors.grey.shade700;
    Color roleBgColor = Colors.grey.shade100;

    if (role == 'admin') {
      roleIcon = Icons.admin_panel_settings_outlined;
      roleColor = Colors.red.shade700;
      roleBgColor = Colors.red.shade100;
    } else if (role == 'doctor' || role == 'pending_doctor') {
      roleIcon = Icons.medical_services_outlined;
      roleColor = Colors.blue.shade700;
      roleBgColor = Colors.blue.shade100;
    } else if (role == 'lab' || role == 'pending_lab') {
      roleIcon = Icons.science_outlined;
      roleColor = Colors.orange.shade700;
      roleBgColor = Colors.orange.shade100;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
            radius: 20,
            backgroundColor: roleBgColor,
            child: Icon(
              roleIcon,
              color: roleColor,
              size: 20,
            )),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(email,
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        trailing: isCurrentAdmin
            ? const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Text('(You)',
                    style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        fontSize: 12)),
              )
            : IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Colors.red[300], size: 22),
                tooltip: 'Delete User Data',
                onPressed: () => _showDeleteDialog(context, doc, name,
                    role), // Pass current role for delete logic
              ),
      ),
    );
  }

  // Approval Tile (Shows requested role and Approve/Reject buttons)
  Widget _buildApprovalTile(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = '${data['firstName']} ${data['lastName']}';
    final email = data['email'] ?? 'No email';
    final pendingRole = data['role'] ??
        'pending_unknown'; // Should be 'pending_doctor' or 'pending_lab'
    final requestedRole = pendingRole.replaceAll('pending_', '');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: Colors.yellow[50], // Highlight pending
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.orange[100],
          child: Icon(
            requestedRole == 'doctor'
                ? Icons.medical_services_outlined
                : Icons.science_outlined,
            color: Colors.orange[800],
            size: 20,
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            'Email: $email\nWants to be: ${requestedRole.toUpperCase()}',
            style: TextStyle(fontSize: 13)),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.red),
              tooltip: 'Reject',
              iconSize: 24,
              onPressed: () =>
                  _updateApprovalStatus(context, doc.id, pendingRole, false),
            ),
            IconButton(
              icon: const Icon(Icons.check_rounded, color: Colors.green),
              tooltip: 'Approve',
              iconSize: 24,
              onPressed: () =>
                  _updateApprovalStatus(context, doc.id, pendingRole, true),
            ),
          ],
        ),
      ),
    );
  }

  // Delete Confirmation Dialog
  Future<void> _showDeleteDialog(BuildContext context, DocumentSnapshot doc,
      String name, String role) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: SingleChildScrollView(
            child: Text(
                'Are you sure you want to delete "$name"?\n\nTheir data (User Doc + Profile Doc if applicable) will be removed from Firestore.\n\nNOTE: You must manually delete their login from Firebase Authentication.'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete Data'),
              onPressed: () {
                _performDelete(context, doc.id, role);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Performs the Deletion from Firestore
  Future<void> _performDelete(
      BuildContext context, String uid, String role) async {
    // Role here is the role from the 'users' doc
    try {
      // Always delete the 'users' document
      await _firestore.collection('users').doc(uid).delete();

      // Determine profile type based on role (even pending) and delete profile
      if (role == 'doctor' || role == 'pending_doctor') {
        final profileDoc = _firestore.collection('doctorProfiles').doc(uid);
        if ((await profileDoc.get()).exists) await profileDoc.delete();
      } else if (role == 'lab' || role == 'pending_lab') {
        final profileDoc = _firestore.collection('labProfiles').doc(uid);
        if ((await profileDoc.get()).exists) await profileDoc.delete();
      }

      print(
          "User data for $uid deleted. REMEMBER TO DELETE FROM AUTHENTICATION.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('User data deleted from Firestore.'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error deleting user data: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  // --- DEPRECATED: These tiles below are not used for the Professionals tab anymore ---
  // // Doctor Tile (Shows specialty, includes delete for non-admins) - Now handled by _buildUserTile for professionals tab query
  // Widget _buildDoctorTile(BuildContext context, DocumentSnapshot doc) { /* ... */ }
  // // Builds a ListTile for a lab profile - Now handled by _buildUserTile for professionals tab query
  // Widget _buildLabTile(BuildContext context, DocumentSnapshot doc) { /* ... */ }
}
