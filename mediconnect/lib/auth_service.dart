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
      print(e.message);
      return null;
    }
  }

  // --- UPDATED SIGN UP METHOD ---
  Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
    String firstName,
    String lastName,
    String role, {
    Map<String, dynamic>? doctorData, // Make doctor data optional
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
        // 2. Create a document in the 'users' collection for everyone
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 3. --- NEW: If the user is a doctor, create a profile document ---
        if (role == 'doctor' && doctorData != null) {
          // Add user's name to the profile data before saving
          doctorData['firstName'] = firstName;
          doctorData['lastName'] = lastName;
          doctorData['email'] = email; // Store email for easy lookup

          await _firestore
              .collection('doctorProfiles')
              .doc(user.uid)
              .set(doctorData);
        }
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print(e.message);
      return null;
    }
  }
  // --- END OF UPDATED METHOD ---

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
