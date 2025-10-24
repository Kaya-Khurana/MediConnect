import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mediconnect/auth_service.dart'; // To get the current patient's ID

class BookingPage extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> doctorData;

  const BookingPage({
    super.key,
    required this.doctorId,
    required this.doctorData,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _reasonController = TextEditingController();

  bool _isLoading = false;

  // Function to show date picker
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now()
          .add(const Duration(days: 60)), // Can book 60 days in advance
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  // Function to show time picker
  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  // Function to confirm and create the appointment
  Future<void> _confirmBooking() async {
    if (_selectedDate == null ||
        _selectedTime == null ||
        _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date, time, and enter a reason.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
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
      // Combine Date and Time into a single DateTime object
      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Get current user's data to store their name
      final patientDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final patientData = patientDoc.data() as Map<String, dynamic>;
      final patientName =
          '${patientData['firstName']} ${patientData['lastName']}';
      final doctorName =
          'Dr. ${widget.doctorData['firstName']} ${widget.doctorData['lastName']}';

      // Create a new document in the 'appointments' collection
      await _firestore.collection('appointments').add({
        'patientId': user.uid,
        'doctorId': widget.doctorId,
        'patientName': patientName,
        'doctorName': doctorName,
        'appointmentTime': Timestamp.fromDate(appointmentDateTime),
        'reason': _reasonController.text,
        'status': 'scheduled', // 'scheduled', 'completed', 'cancelled'
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Show success and go back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Go back to the doctor list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking appointment: $e'),
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
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name =
        'Dr. ${widget.doctorData['firstName']} ${widget.doctorData['lastName']}';
    final specialty = widget.doctorData['specialty'] ?? 'No specialty';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              specialty,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const Divider(height: 32),

            // --- Reason Field ---
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Appointment',
                hintText: 'e.g., Annual checkup, fever...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // This is handled by the controller
              },
            ),
            const SizedBox(height: 24),

            // --- Date Picker ---
            Text('Select Date', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'No date selected'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
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

            // --- Time Picker ---
            Text('Select Time', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedTime == null
                        ? 'No time selected'
                        : _selectedTime!.format(context),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirm Booking',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
