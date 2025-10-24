import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mediconnect/auth_service.dart';
import 'package:intl/intl.dart';

class BookLabTestPage extends StatefulWidget {
  final String labId;
  final Map<String, dynamic> labData;

  const BookLabTestPage({
    super.key,
    required this.labId,
    required this.labData,
  });

  @override
  State<BookLabTestPage> createState() => _BookLabTestPageState();
}

class _BookLabTestPageState extends State<BookLabTestPage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _testNameController =
      TextEditingController(); // Which test is needed

  bool _isLoading = false;

  // --- Corrected _pickDate function ---
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)), // Added lastDate
    ); // Added closing parenthesis
    if (date != null) {
      setState(() => _selectedDate = date); // Added setState logic
    }
  }

  // --- Corrected _pickTime function (removed duplicate) ---
  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  // --- Corrected _confirmBooking function ---
  Future<void> _confirmBooking() async {
    if (_selectedDate == null ||
        _selectedTime == null ||
        _testNameController.text.trim().isEmpty) {
      // Added trim()
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          // Added actual Snackbar
          content: Text('Please select a date, time, and enter the test name.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        // Added actual Snackbar
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
      // --- Correctly combine date and time ---
      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final patientDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final patientData = patientDoc.data() as Map<String, dynamic>;
      final patientName =
          '${patientData['firstName']} ${patientData['lastName']}';
      final labName = widget.labData['labName'] ?? 'Unknown Lab';

      // --- Save to NEW 'labTestBookings' collection ---
      await _firestore.collection('labTestBookings').add({
        'patientId': user.uid,
        'labId': widget.labId,
        'patientName': patientName,
        'labName': labName,
        'appointmentTime': Timestamp.fromDate(appointmentDateTime),
        'testName': _testNameController.text.trim(),
        'status': 'scheduled', // 'scheduled', 'completed', 'cancelled'
        'createdAt': FieldValue.serverTimestamp(),
        // Add results field later?
      });

      ScaffoldMessenger.of(context).showSnackBar(
        // Added actual Snackbar
        const SnackBar(
          content: Text('Lab test booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Go back to lab list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        // Added actual Snackbar
        SnackBar(
          content: Text('Error booking test: $e'),
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
    _testNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labName = widget.labData['labName'] ?? 'Unnamed Lab';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Lab Test'),
        backgroundColor: Theme.of(context).primaryColor, // Added styling
        foregroundColor: Colors.white, // Added styling
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              // Added styling
              labName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 32),

            // --- Test Name Field ---
            TextField(
              controller: _testNameController,
              decoration: const InputDecoration(
                labelText: 'Test Name / Description',
                hintText: 'e.g., Complete Blood Count (CBC)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.biotech_outlined), // Added icon
              ),
            ),
            const SizedBox(height: 24),

            // --- Date Picker Row ---
            Text('Select Date', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'No date selected'
                        : DateFormat('EEE, MMM d, yyyy')
                            .format(_selectedDate!), // Format date
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: _pickDate,
                  child: const Text('Choose Date'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Time Picker Row ---
            Text('Select Time', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedTime == null
                        ? 'No time selected'
                        : _selectedTime!.format(context), // Format time
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: _pickTime,
                  child: const Text('Choose Time'),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // --- Confirm Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  // Added styling
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        // Improved spinner display
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Confirm Test Booking',
                        style: TextStyle(fontSize: 18), // Added styling
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
