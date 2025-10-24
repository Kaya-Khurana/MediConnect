// lib/write_prescription_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mediconnect/auth_service.dart';

// Helper class to manage controllers for one medication
class MedicationEntry {
  final TextEditingController medicationController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  // We can add notes per medication if needed, or keep one main notes field
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
  // --- NEW: List to hold multiple medication entries ---
  final List<MedicationEntry> _medicationEntries = [
    MedicationEntry()
  ]; // Start with one
  final TextEditingController _notesController =
      TextEditingController(); // Keep one main notes field

  bool _isLoading = false;

  // --- NEW: Function to add a medication line ---
  void _addMedicationLine() {
    setState(() {
      _medicationEntries.add(MedicationEntry());
    });
  }

  // --- NEW: Function to remove a medication line ---
  void _removeMedicationLine(int index) {
    // Prevent removing the last line
    if (_medicationEntries.length > 1) {
      setState(() {
        // Dispose controllers before removing
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

  // --- UPDATED: Function to Save the Prescription ---
  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) {
      return; // Validation will now check all medication fields
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
      final doctorDoc =
          await _firestore.collection('users').doc(doctorUser.uid).get();
      final doctorData = doctorDoc.data() as Map<String, dynamic>;
      final doctorName =
          'Dr. ${doctorData['firstName']} ${doctorData['lastName']}';

      final patientDoc =
          await _firestore.collection('users').doc(_selectedPatientId!).get();
      final patientData = patientDoc.data() as Map<String, dynamic>;
      final patientName =
          '${patientData['firstName']} ${patientData['lastName']}';

      // --- NEW: Gather data from all medication entries ---
      List<Map<String, String>> medicationsList =
          _medicationEntries.map((entry) {
        return {
          'medication': entry.medicationController.text.trim(),
          'dosage': entry.dosageController.text.trim(),
        };
      }).toList();
      // --- End of new data gathering ---

      // Save to 'prescriptions' collection
      await _firestore.collection('prescriptions').add({
        'doctorId': doctorUser.uid,
        'doctorName': doctorName,
        'patientId': _selectedPatientId,
        'patientName': patientName,
        'medications': medicationsList, // <-- Save the list here
        'notes': _notesController.text.trim(), // Keep the overall notes
        'issuedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Go back after saving
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
    // Dispose all dynamic controllers
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
              // --- Patient Selector (no change) ---
              Text('Select Patient',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .where('role', isEqualTo: 'patient')
                    .snapshots(),
                builder: (context, snapshot) {
                  // ... (DropdownButtonFormField code remains the same) ...
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError)
                    return Text('Error: ${snapshot.error}');
                  if (snapshot.data!.docs.isEmpty)
                    return const Text('No patients found.');

                  List<DropdownMenuItem<String>> patientItems =
                      snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = '${data['firstName']} ${data['lastName']}';
                    return DropdownMenuItem<String>(
                        value: doc.id, child: Text(name));
                  }).toList();

                  return DropdownButtonFormField<String>(
                    value: _selectedPatientId,
                    items: patientItems,
                    onChanged: (value) =>
                        setState(() => _selectedPatientId = value),
                    decoration: const InputDecoration(
                      labelText: 'Patient Name',
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

              // --- NEW: Dynamic List of Medication Fields ---
              ListView.builder(
                shrinkWrap: true, // Important inside SingleChildScrollView
                physics:
                    const NeverScrollableScrollPhysics(), // Disable internal scrolling
                itemCount: _medicationEntries.length,
                itemBuilder: (context, index) {
                  return _buildMedicationRow(index);
                },
              ),
              // --- End of Dynamic List ---

              const SizedBox(height: 16),
              // --- NEW: Add Medication Button ---
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
              // --- End of Add Button ---

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // --- Notes Field (no change) ---
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'General Instructions / Notes',
                  hintText: 'e.g., Follow up in 2 weeks...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 4,
                // Make general notes optional
                // validator: (value) => (value == null || value.isEmpty) ? 'Please enter instructions' : null,
              ),
              const SizedBox(height: 32),

              // --- Save Button (no change) ---
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

  // --- NEW: Widget to build one row of medication/dosage fields ---
  Widget _buildMedicationRow(int index) {
    MedicationEntry entry = _medicationEntries[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3, // Medication field takes more space
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
            flex: 2, // Dosage field takes less space
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
          // Remove button (only show if not the first item)
          if (_medicationEntries.length > 1)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _removeMedicationLine(index),
              tooltip: 'Remove Medication',
            )
          else
            const SizedBox(width: 48), // Keep alignment if only one item
        ],
      ),
    );
  }
  // --- End of new widget ---
}
