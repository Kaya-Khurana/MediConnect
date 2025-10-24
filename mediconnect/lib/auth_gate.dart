import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mediconnect/auth_service.dart';
import 'package:mediconnect/home_page.dart';
import 'package:mediconnect/login_page.dart';
import 'package:provider/provider.dart'; // We'll wrap our app with this

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // User is not logged in
        if (!snapshot.hasData) {
          return LoginPage();
        }

        // User is logged in
        // We can add logic here to check role
        // For now, just go to HomePage
        return HomePage();
      },
    );
  }
}
