import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get the stream of user authentication changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign In with Email & Password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Login Error: ${e.message}');
      return null;
    } catch (e) {
      print('General Login Error: $e');
      return null;
    }
  }

  // --- UPDATED SIGN UP METHOD for Pending Approval ---
  Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
    String firstName,
    String lastName,
    String selectedRole, // Role selected by user (patient, doctor, lab)
    {
    Map<String, dynamic>? doctorData,
    Map<String, dynamic>? labData,
  }) async {
    try {
      // 1. Create the user in Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // --- Determine initial role and approval status ---
        String finalRole;
        bool isApproved = true; // Patients are approved by default

        if (selectedRole == 'doctor') {
          finalRole = 'pending_doctor';
          isApproved = false;
        } else if (selectedRole == 'lab') {
          finalRole = 'pending_lab';
          isApproved = false;
        } else {
          finalRole = 'patient'; // Default to patient
        }
        // --- End Role/Approval Logic ---

        // 2. Create user document (common for all roles)
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'role': finalRole, // <-- Use the determined role
          'isApproved': isApproved, // <-- Add the approval flag
          'createdAt': FieldValue.serverTimestamp(),
        });

        // --- 3. Save Profile Data ---
        // If Doctor, create doctor profile
        if (selectedRole == 'doctor' && doctorData != null) {
          doctorData['firstName'] = firstName;
          doctorData['lastName'] = lastName;
          doctorData['email'] = email;
          // Optionally add an 'approvalStatus': 'pending' field here too
          await _firestore
              .collection('doctorProfiles')
              .doc(user.uid)
              .set(doctorData);
        }
        // If Lab, create lab profile
        else if (selectedRole == 'lab' && labData != null) {
          labData['contactFirstName'] = firstName;
          labData['contactLastName'] = lastName;
          labData['email'] = email;
          // Optionally add an 'approvalStatus': 'pending' field here too
          await _firestore.collection('labProfiles').doc(user.uid).set(labData);
        }
        // --- End Profile Saving ---
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Signup Error: ${e.message}');
      return null;
    } catch (e) {
      print('General Signup Error: $e');
      return null;
    }
  }
  // --- END OF UPDATED METHOD ---

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
