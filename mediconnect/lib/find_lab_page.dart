import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mediconnect/book_lab_test_page.dart'; // We will create this next

class FindLabPage extends StatelessWidget {
  const FindLabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Laboratory'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('labProfiles').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text(
              'No laboratories found.', /* styling */
            ));
          }

          final labs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: labs.length,
            itemBuilder: (context, index) {
              final labDoc = labs[index];
              final data = labDoc.data() as Map<String, dynamic>;

              final labName = data['labName'] ?? 'Unnamed Lab';
              final address = data['address'] ?? 'No address';
              final services =
                  (data['services'] as List<dynamic>?)?.join(', ') ??
                      'No services listed';

              return Card(
                elevation: 3.0,
                margin: const EdgeInsets.only(bottom: 16.0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(labName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(address,
                                  style: TextStyle(color: Colors.grey[800]))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Services: $services',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 13)),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookLabTestPage(
                                  labId: labDoc.id,
                                  labData: data,
                                ),
                              ),
                            );
                          },
                          child: const Text('Book Test'),
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
