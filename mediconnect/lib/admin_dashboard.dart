// lib/admin_dashboard.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  final String adminUid; // <-- ADD THIS
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminDashboard({
    super.key,
    required this.adminUid, // <-- ADD THIS
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: Theme.of(context).primaryColor,
            labelColor: Colors.black87,
            unselectedLabelColor: Colors.grey[600],
            tabs: [
              Tab(
                icon: Icon(Icons.people_alt_outlined),
                text: 'All Users',
              ),
              Tab(
                icon: Icon(Icons.medical_services_outlined),
                text: 'All Doctors',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- Tab 1: All Users List ---
            _buildCollectionList(
              context,
              _firestore.collection('users').snapshots(),
              (doc) => _buildUserTile(context, doc),
            ),

            // --- Tab 2: All Doctors List ---
            _buildCollectionList(
              context,
              _firestore.collection('doctorProfiles').snapshots(),
              (doc) => _buildDoctorTile(context, doc),
            ),
          ],
        ),
      ),
    );
  }

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
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No data found.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data!.docs[index];
            return tileBuilder(doc);
          },
        );
      },
    );
  }

  // --- UPDATED USER TILE ---
  Widget _buildUserTile(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = '${data['firstName']} ${data['lastName']}';
    final email = data['email'] ?? 'No email';
    final role = data['role'] ?? 'user';
    final isCurrentAdmin = doc.id == adminUid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: role == 'admin'
              ? Colors.red[100]
              : (role == 'doctor' ? Colors.blue[100] : Colors.grey[100]),
          child: Icon(
            role == 'admin'
                ? Icons.admin_panel_settings
                : (role == 'doctor' ? Icons.medical_services : Icons.person),
            color: role == 'admin'
                ? Colors.red
                : (role == 'doctor' ? Colors.blue : Colors.grey[800]),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(email),
        trailing: isCurrentAdmin
            ? const Text(
                '(You)',
                style:
                    TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              )
            : IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  _showDeleteDialog(context, doc, name, role);
                },
              ),
      ),
    );
  }

  // --- UPDATED DOCTOR TILE ---
  Widget _buildDoctorTile(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = 'Dr. ${data['firstName']} ${data['lastName']}';
    final specialty = data['specialty'] ?? 'No specialty';
    final location = data['clinicAddress'] ?? 'No location';
    final isCurrentAdmin = doc.id == adminUid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColorLight,
          child: Icon(
            Icons.medical_services_outlined,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$specialty\n$location'),
        isThreeLine: true,
        trailing: isCurrentAdmin
            ? const Text(
                '(You)',
                style:
                    TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              )
            : IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  // We pass 'doctor' role to ensure both collections are deleted
                  _showDeleteDialog(context, doc, name, 'doctor');
                },
              ),
      ),
    );
  }

  // --- NEW: Confirmation Dialog ---
  Future<void> _showDeleteDialog(BuildContext context, DocumentSnapshot doc,
      String name, String role) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete User?'),
          content: SingleChildScrollView(
            child: Text(
                'Are you sure you want to delete "$name"?\n\nThis action cannot be undone.'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                _performDelete(context, doc.id, role);
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // --- NEW: Delete Logic ---
  Future<void> _performDelete(
      BuildContext context, String uid, String role) async {
    try {
      // 1. Delete the 'users' document
      await _firestore.collection('users').doc(uid).delete();

      // 2. If it's a doctor, also delete their 'doctorProfiles' document
      if (role == 'doctor') {
        await _firestore.collection('doctorProfiles').doc(uid).delete();
      }

      // 3. (Important) Delete the user from Firebase Authentication
      // This is a backend task. For now, we've only deleted their
      // database records. They can still log in (but their data is gone).
      // We'll add a note for this.

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User deleted from database.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
