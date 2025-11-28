// lib/write_prescription_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mediconnect/auth_service.dart';

// Helper class to manage controllers for one medication
class MedicationEntry {
  final TextEditingController medicationController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
}

class WritePrescriptionPage extends StatefulWidget {
  const WritePrescriptionPage({super.key});

  @override
  State<WritePrescriptionPage> createState() => _WritePrescriptionPageState();
}

class _WritePrescriptionPageState extends State<WritePrescriptionPage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _selectedPatientId;

  // List to hold multiple medication entries
  final List<MedicationEntry> _medicationEntries = [MedicationEntry()];

  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;

  // Function to add a medication line
  void _addMedicationLine() {
    setState(() {
      _medicationEntries.add(MedicationEntry());
    });
  }

  // Function to remove a medication line
  void _removeMedicationLine(int index) {
    if (_medicationEntries.length > 1) {
      setState(() {
        _medicationEntries[index].medicationController.dispose();
        _medicationEntries[index].dosageController.dispose();
        _medicationEntries.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot remove the last medication line.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Function to Save the Prescription
  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final doctorUser = _authService.currentUser;
    if (doctorUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: You are not logged in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch doctor's details
      final doctorDoc =
          await _firestore.collection('users').doc(doctorUser.uid).get();
      final doctorData = doctorDoc.data() as Map<String, dynamic>;
      final doctorName =
          'Dr. ${doctorData['firstName']} ${doctorData['lastName']}';

      // Fetch patient's details
      final patientDoc =
          await _firestore.collection('users').doc(_selectedPatientId!).get();
      final patientData = patientDoc.data() as Map<String, dynamic>;
      final patientName =
          '${patientData['firstName']} ${patientData['lastName']}';

      // Gather data from all medication entries
      List<Map<String, String>> medicationsList =
          _medicationEntries.map((entry) {
        return {
          'medication': entry.medicationController.text.trim(),
          'dosage': entry.dosageController.text.trim(),
        };
      }).toList();

      // Save to 'prescriptions' collection
      await _firestore.collection('prescriptions').add({
        'doctorId': doctorUser.uid,
        'doctorName': doctorName,
        'patientId': _selectedPatientId,
        'patientName': patientName,
        'medications': medicationsList,
        'notes': _notesController.text.trim(),
        'issuedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving prescription: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (var entry in _medicationEntries) {
      entry.medicationController.dispose();
      entry.dosageController.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Prescription'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Patient Selector ---
              Text('Select Patient',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              StreamBuilder<QuerySnapshot>(
                // --- FIXED QUERY: Simple fetch, manual sort ---
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    // Print error to debug console
                    print("Error fetching users: ${snapshot.error}");
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No users found in database.');
                  }

                  // Filter out the current doctor from the list
                  final doctorUid = _authService.currentUser?.uid;
                  final users = snapshot.data!.docs
                      .where((doc) => doc.id != doctorUid)
                      .toList();

                  // Sort alphabetically in code (safer than database index)
                  users.sort((a, b) {
                    final nameA = (a.data() as Map)['firstName'] ?? '';
                    final nameB = (b.data() as Map)['firstName'] ?? '';
                    return nameA.toString().compareTo(nameB.toString());
                  });

                  if (users.isEmpty) {
                    return const Text('No other users found.');
                  }

                  List<DropdownMenuItem<String>> patientItems =
                      users.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = '${data['firstName']} ${data['lastName']}';
                    final role = data['role'] ?? 'User';
                    return DropdownMenuItem<String>(
                        value: doc.id, child: Text('$name ($role)'));
                  }).toList();

                  return DropdownButtonFormField<String>(
                    value: _selectedPatientId,
                    items: patientItems,
                    onChanged: (value) =>
                        setState(() => _selectedPatientId = value),
                    decoration: const InputDecoration(
                      labelText: 'Search User',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_search_outlined),
                    ),
                    validator: (value) =>
                        value == null ? 'Please select a patient' : null,
                  );
                },
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text('Medications',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),

              // --- Dynamic List of Medication Fields ---
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _medicationEntries.length,
                itemBuilder: (context, index) {
                  return _buildMedicationRow(index);
                },
              ),

              const SizedBox(height: 16),
              // --- Add Medication Button ---
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Medication'),
                onPressed: _addMedicationLine,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // --- Notes Field ---
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'General Instructions / Notes',
                  hintText: 'e.g., Follow up in 2 weeks...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 32),

              // --- Save Button ---
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _savePrescription,
                icon: _isLoading
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3),
                      )
                    : const Icon(Icons.save_alt_outlined),
                label: const Text('Save Prescription'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget to build one row of medication/dosage fields ---
  Widget _buildMedicationRow(int index) {
    MedicationEntry entry = _medicationEntries[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: entry.medicationController,
              decoration: InputDecoration(
                labelText: 'Medication ${index + 1}',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.medication_liquid_outlined),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: entry.dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.science_outlined),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Required' : null,
            ),
          ),
          // Remove button
          if (_medicationEntries.length > 1)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _removeMedicationLine(index),
              tooltip: 'Remove Medication',
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
