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
      print('Login Error: ${e.message}'); // Added context
      return null;
    } catch (e) {
      print('General Login Error: $e'); // Added context
      return null;
    }
  }

  // --- UPDATED SIGN UP METHOD for Lab Role ---
  Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
    String firstName, // For lab, this is contact person's first name
    String lastName, // For lab, this is contact person's last name
    String role, {
    Map<String, dynamic>? doctorData,
    Map<String, dynamic>? labData, // --- NEW: Lab specific data ---
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
        // 2. Create user document (common for all roles)
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'firstName': firstName, // Contact person first name
          'lastName': lastName, // Contact person last name
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 3. If Doctor, create doctor profile
        if (role == 'doctor' && doctorData != null) {
          doctorData['firstName'] = firstName;
          doctorData['lastName'] = lastName;
          doctorData['email'] = email;
          await _firestore
              .collection('doctorProfiles')
              .doc(user.uid)
              .set(doctorData);
        }
        // 4. If Lab, create lab profile
        else if (role == 'lab' && labData != null) {
          labData['contactFirstName'] = firstName; // Store contact person name
          labData['contactLastName'] = lastName;
          labData['email'] = email; // Store contact email
          // Ensure lab name and address are included from labData
          await _firestore.collection('labProfiles').doc(user.uid).set(labData);
        }
        // --- End of Lab Profile creation ---
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
