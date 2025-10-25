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

  // --- Function to handle approval/rejection ---
  Future<void> _updateApprovalStatus(BuildContext context, String uid,
      String currentRole, bool approve) async {
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
      length: 3, // Users, Professionals, Approvals
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0, // Remove shadow
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.0,
                  ),
                ),
              ),
              child: TabBar(
                indicatorColor: Theme.of(context).primaryColor,
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.grey[600],
                indicatorWeight: 3.0,
                tabs: const [
                  Tab(icon: Icon(Icons.people_alt_outlined), text: 'Users'),
                  Tab(icon: Icon(Icons.work_outline), text: 'Professionals'),
                  Tab(
                      icon: Icon(Icons.rule_folder_outlined),
                      text: 'Approvals'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // --- Tab 1: Approved Users (Patients, Doctors, Labs) ---
            _buildCollectionList(
                context,
                _firestore
                    .collection('users')
                    .where('isApproved', isEqualTo: true)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                (doc) => _buildUserTile(context, doc),
                "No approved users found."),

            // --- Tab 2: Enhanced Professionals Tab with Detailed Doctor View ---
            _buildEnhancedProfessionalsTab(context),

            // --- Tab 3: Pending Approvals ---
            _buildCollectionList(
                context,
                _firestore
                    .collection('users')
                    .where('isApproved', isEqualTo: false)
                    .snapshots(),
                (doc) => _buildApprovalTile(context, doc),
                "No pending approvals."),
          ],
        ),
      ),
    );
  }

  // Reusable list builder
  Widget _buildCollectionList(
    BuildContext context,
    Stream<QuerySnapshot> stream,
    Widget Function(DocumentSnapshot) tileBuilder,
    String emptyMessage,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
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
          print("Firestore Stream Error: ${snapshot.error}");
          return Center(
              child: Text('Error loading data.',
                  style: TextStyle(color: Colors.red.shade700)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text(emptyMessage,
                  style: const TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data!.docs[index];
            try {
              return tileBuilder(doc);
            } catch (e) {
              print("Error building tile for doc ${doc.id}: $e");
              return ListTile(
                  title: Text("Error displaying item ${doc.id}",
                      style: TextStyle(color: Colors.red)));
            }
          },
        );
      },
    );
  }

  // --- ENHANCED: Widget for the combined Professionals Tab ---
  Widget _buildEnhancedProfessionalsTab(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 2.0,
              tabs: const [
                Tab(text: 'Doctors'),
                Tab(text: 'Laboratories'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Doctors Tab
                _buildDoctorsTab(context),
                // Laboratories Tab
                _buildLabsTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsTab(BuildContext context) {
    final doctorsStream = _firestore
        .collection('users')
        .where('role', whereIn: ['doctor', 'pending_doctor']).snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: doctorsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red.shade700)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No doctors found',
                  style: TextStyle(color: Colors.grey)));
        }

        final doctors = snapshot.data!.docs;

        return Column(
          children: [
            // Statistics Header
            _buildDoctorsStatsHeader(doctors),
            // Doctors List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: doctors.length,
                itemBuilder: (context, index) {
                  final doc = doctors[index];
                  return _buildEnhancedDoctorTile(context, doc);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDoctorsStatsHeader(List<QueryDocumentSnapshot> doctors) {
    final activeDoctors = doctors.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['role'] == 'doctor' && data['isApproved'] == true;
    }).length;

    final pendingDoctors = doctors.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['role'] == 'pending_doctor';
    }).length;

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.blue[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Total Doctors', doctors.length, Icons.people),
          _buildStatCard('Active Doctors', activeDoctors, Icons.check_circle),
          _buildStatCard('Pending', pendingDoctors, Icons.pending),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[700], size: 24),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLabsTab(BuildContext context) {
    final labsStream = _firestore
        .collection('users')
        .where('role', whereIn: ['lab', 'pending_lab']).snapshots();

    return _buildCollectionList(context, labsStream,
        (doc) => _buildUserTile(context, doc), "No laboratories found.");
  }

  // --- Enhanced Doctor Tile with More Details ---
  Widget _buildEnhancedDoctorTile(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = '${data['firstName']} ${data['lastName']}';
    final email = data['email'] ?? 'No email';
    final role = data['role'] ?? 'user';
    final isApproved = data['isApproved'] ?? false;
    final isCurrentAdmin = doc.id == adminUid;

    // Get additional doctor profile data
    final doctorProfileStream =
        _firestore.collection('doctorProfiles').doc(doc.id).snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: doctorProfileStream,
      builder: (context, profileSnapshot) {
        final profileData =
            profileSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        final specialization = profileData['specialization'] ?? 'Not specified';
        final experience = profileData['experience'] ?? 'Not specified';
        final qualification = profileData['qualification'] ?? 'Not specified';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.blue[100],
              child: Icon(
                Icons.medical_services,
                color: Colors.blue[700],
                size: 24,
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  specialization,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Email: $email'),
                Text('Qualification: $qualification'),
                Text('Experience: $experience'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            isApproved ? Colors.green[100] : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isApproved ? 'Approved' : 'Pending',
                        style: TextStyle(
                          color: isApproved
                              ? Colors.green[800]
                              : Colors.orange[800],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!isApproved)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.red, size: 20),
                            onPressed: () => _updateApprovalStatus(
                                context, doc.id, role, false),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check,
                                color: Colors.green, size: 20),
                            onPressed: () => _updateApprovalStatus(
                                context, doc.id, role, true),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            trailing: isCurrentAdmin
                ? const Text('(You)',
                    style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        fontSize: 12))
                : IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                    onPressed: () =>
                        _showDeleteDialog(context, doc, name, role),
                  ),
            onTap: () {
              // Show detailed doctor information
              _showDoctorDetails(context, doc, profileData);
            },
          ),
        );
      },
    );
  }

  // --- Show Detailed Doctor Information ---
  void _showDoctorDetails(BuildContext context, DocumentSnapshot doc,
      Map<String, dynamic> profileData) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = '${data['firstName']} ${data['lastName']}';
    final email = data['email'] ?? 'No email';
    final phone = data['phone'] ?? 'Not provided';
    final specialization = profileData['specialization'] ?? 'Not specified';
    final experience = profileData['experience'] ?? 'Not specified';
    final qualification = profileData['qualification'] ?? 'Not specified';
    final bio = profileData['bio'] ?? 'No bio provided';
    final address = profileData['address'] ?? 'Not specified';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.medical_services, color: Colors.blue[700]),
            const SizedBox(width: 8),
            const Text('Doctor Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', name),
              _buildDetailRow('Email', email),
              _buildDetailRow('Phone', phone),
              _buildDetailRow('Specialization', specialization),
              _buildDetailRow('Qualification', qualification),
              _buildDetailRow('Experience', experience),
              _buildDetailRow('Address', address),
              const SizedBox(height: 8),
              const Text('Bio:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(bio),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // --- Existing Tile Widgets ---
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
                onPressed: () => _showDeleteDialog(context, doc, name, role),
              ),
      ),
    );
  }

  Widget _buildApprovalTile(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = '${data['firstName']} ${data['lastName']}';
    final email = data['email'] ?? 'No email';
    final pendingRole = data['role'] ?? 'pending_unknown';
    final requestedRole = pendingRole.replaceAll('pending_', '');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: Colors.yellow[50],
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

  // --- Delete Confirmation Dialog ---
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
                _performDelete(
                    context, doc.id, role); // Pass the role from user doc
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- Performs the Deletion from Firestore ---
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
}
