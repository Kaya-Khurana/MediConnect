import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mediconnect/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:mediconnect/constants.dart';

class MyPrescriptionsPage extends StatelessWidget {
  MyPrescriptionsPage({super.key});

  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Function to generate and save PDF ---
  Future<void> _generateAndSavePdf(
      BuildContext context, Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // Load Logo Image
    final logoImage = pw.MemoryImage(
      (await DefaultAssetBundle.of(context).load(AppConstants.appLogo))
          .buffer
          .asUint8List(),
    );

    // Extract data
    final doctorName = data['doctorName'] ?? 'Unknown Doctor';

    // --- FIX: Robust Patient Name Check ---
    // 1. Try to get name from the prescription doc
    // 2. If missing, use a default string (or you could fetch the user doc here)
    final patientName = data['patientName'] ?? 'Patient';

    final List<dynamic> medicationsList = data['medications'] ?? [];
    final notes = data['notes'] ?? 'No additional notes';
    final issuedAt = (data['issuedAt'] as Timestamp?)?.toDate();
    final formattedDate = issuedAt != null
        ? DateFormat('MMM d, yyyy').format(issuedAt)
        : 'Date unknown';
    final formattedTime =
        issuedAt != null ? DateFormat('h:mm a').format(issuedAt) : '';

    // Define colors
    final PdfColor primaryColor = PdfColor.fromHex("#42A5F5");
    final PdfColor lightBgColor = PdfColor.fromHex("#E3F2FD");
    final PdfColor darkTextColor = PdfColors.black;
    final PdfColor lightTextColor = PdfColors.grey600;

    // Build PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        build: (pw.Context pdfContext) {
          const double spacing = 10;
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Image(logoImage, height: 45, width: 45),
                        pw.SizedBox(width: spacing),
                        pw.Text('MediConnect',
                            style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor)),
                      ]),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Prescription',
                            style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: darkTextColor)),
                        pw.SizedBox(height: 3),
                        pw.Text(formattedDate,
                            style: pw.TextStyle(
                                fontSize: 11, color: lightTextColor)),
                        if (formattedTime.isNotEmpty)
                          pw.Text(formattedTime,
                              style: pw.TextStyle(
                                  fontSize: 11, color: lightTextColor)),
                      ]),
                ],
              ),
              pw.Divider(
                  thickness: 1.5,
                  color: PdfColors.grey300,
                  height: spacing * 3),

              // Patient & Doctor Info
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: spacing * 1.5, vertical: spacing),
                margin: const pw.EdgeInsets.only(bottom: spacing * 2),
                decoration: pw.BoxDecoration(
                  color: lightBgColor,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('PATIENT',
                                style: pw.TextStyle(
                                    color: primaryColor,
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text(patientName,
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 13,
                                    color: darkTextColor)),
                          ]),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('PRESCRIBED BY',
                                style: pw.TextStyle(
                                    color: primaryColor,
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text(doctorName,
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 13,
                                    color: darkTextColor)),
                          ]),
                    ]),
              ),

              // Medications
              pw.Text('Medications',
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor)),
              pw.SizedBox(height: spacing / 1.5),
              if (medicationsList.isNotEmpty)
                pw.Table(
                    columnWidths: const {
                      0: pw.FlexColumnWidth(3),
                      1: pw.FlexColumnWidth(2),
                    },
                    border:
                        pw.TableBorder.all(color: PdfColors.grey200, width: 1),
                    children: [
                      pw.TableRow(
                          decoration: pw.BoxDecoration(color: primaryColor),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: spacing, vertical: spacing / 2),
                              child: pw.Text('Medication',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.white,
                                      fontSize: 11)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: spacing, vertical: spacing / 2),
                              child: pw.Text('Dosage / Instructions',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.white,
                                      fontSize: 11)),
                            ),
                          ]),
                      ...medicationsList.map((med) {
                        final medMap = med as Map<String, dynamic>? ?? {};
                        return pw.TableRow(children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: spacing, vertical: spacing / 1.5),
                            child: pw.Text(medMap['medication'] ?? 'N/A',
                                style: pw.TextStyle(
                                    fontSize: 10, color: darkTextColor)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: spacing, vertical: spacing / 1.5),
                            child: pw.Text(medMap['dosage'] ?? 'N/A',
                                style: pw.TextStyle(
                                    fontSize: 10, color: darkTextColor)),
                          ),
                        ]);
                      }).toList(),
                    ])
              else
                pw.Container(),

              pw.SizedBox(height: spacing * 2),

              // Notes
              if (notes.isNotEmpty) ...[
                pw.Text('Additional Notes',
                    style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor)),
                pw.SizedBox(height: spacing / 1.5),
                pw.Container(
                  padding: const pw.EdgeInsets.all(spacing),
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey200),
                    borderRadius: pw.BorderRadius.circular(4),
                    color: PdfColors.grey50,
                  ),
                  child: pw.Text(notes,
                      style: pw.TextStyle(fontSize: 10, color: darkTextColor)),
                ),
                pw.SizedBox(height: spacing * 2),
              ],

              // Footer
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300, height: spacing),
              pw.SizedBox(height: spacing / 2),
              pw.Center(
                child: pw.Text(
                    'This is a digitally generated prescription from MediConnect.',
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey500)),
              )
            ],
          );
        },
      ),
    );

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      print("Error generating PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(
          body: Center(child: Text('You must be logged in.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('prescriptions')
            .where('patientId', isEqualTo: user.uid)
            .orderBy('issuedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            if (snapshot.error.toString().contains('index')) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                      'Firestore Error: Index missing. Check Debug Console.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red)),
                ),
              );
            }
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('You have no prescriptions.',
                    style: TextStyle(fontSize: 18, color: Colors.grey)));
          }

          final prescriptions = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: prescriptions.length,
            itemBuilder: (context, index) {
              final doc = prescriptions[index];
              final data = doc.data() as Map<String, dynamic>;

              // --- Get Doctor Name ---
              final doctorName = data['doctorName'] ?? 'Unknown Doctor';

              // --- FIX: Get Patient Name Safely ---
              final patientName = data['patientName'] ?? 'Patient';

              final List<dynamic> medicationsList = data['medications'] ?? [];
              final notes = data['notes'] ?? 'No additional notes';
              final issuedAt = (data['issuedAt'] as Timestamp?)?.toDate();
              final formattedDate = issuedAt != null
                  ? DateFormat('EEE, MMM d, yyyy').format(issuedAt)
                  : 'Date unknown';

              return Card(
                elevation: 3.0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Prescription',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Prescribed by: $doctorName',
                        style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500),
                      ),
                      // --- FIX: Display Patient Name on UI Card ---
                      const SizedBox(height: 4),
                      Text(
                        'For: $patientName',
                        style: TextStyle(color: Colors.grey[800], fontSize: 13),
                      ),

                      const Divider(height: 20),

                      if (medicationsList.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: medicationsList.map((med) {
                            final medMap = med as Map<String, dynamic>? ?? {};
                            final medName = medMap['medication'] ?? 'N/A';
                            final medDosage = medMap['dosage'] ?? 'N/A';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.medication_outlined,
                                      size: 18, color: Colors.green[700]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text('$medName - $medDosage',
                                          style:
                                              const TextStyle(fontSize: 15))),
                                ],
                              ),
                            );
                          }).toList(),
                        )
                      else
                        const Text('No medications listed.',
                            style: TextStyle(fontStyle: FontStyle.italic)),

                      const SizedBox(height: 16),
                      if (notes.isNotEmpty) ...[
                        const Text('Notes:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(notes,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700])),
                      ],

                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: Icon(Icons.picture_as_pdf_outlined,
                              color: Theme.of(context).primaryColor),
                          label: Text('Save as PDF',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor)),
                          onPressed: () => _generateAndSavePdf(context, data),
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
