// lib/find_doctor_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mediconnect/booking_page.dart';

class FindDoctorPage extends StatelessWidget {
  const FindDoctorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Doctor'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // Use typed QuerySnapshot to avoid casting issues
        stream: FirebaseFirestore.instance
            .collection('doctorProfiles')
            .withConverter<Map<String, dynamic>>(
              fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
              toFirestore: (map, _) => map,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No doctors have registered yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doctorDoc = docs[index];
              final data = doctorDoc.data();

              // Defensive field extraction to avoid runtime errors
              final firstName = (data['firstName'] ?? '').toString();
              final lastName = (data['lastName'] ?? '').toString();
              final name = 'Dr. ${firstName} ${lastName}'.trim();
              final specialty =
                  (data['specialty'] ?? 'No specialty').toString();
              final location =
                  (data['clinicAddress'] ?? 'No location').toString();

              // Ensure fee is a double
              double fee = 0.0;
              final feeVal = data['consultationFee'];
              if (feeVal is num) {
                fee = feeVal.toDouble();
              } else if (feeVal is String) {
                fee = double.tryParse(feeVal) ?? 0.0;
              }

              return Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                Theme.of(context).primaryColorLight,
                            child: Icon(
                              Icons.medical_services_outlined,
                              size: 30,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  specialty,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: Colors.grey[600], size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[800]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.attach_money_outlined,
                              color: Colors.grey[600], size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Fee: \$${fee.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[800]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to the Booking Page (defensive - passes id and data map)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingPage(
                                  doctorId: doctorDoc.id,
                                  doctorData: data,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Book Appointment'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
