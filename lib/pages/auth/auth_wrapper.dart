import 'package:civicsnap_android/pages/auth/login.dart';
import 'package:civicsnap_android/pages/home.dart';
import 'package:civicsnap_android/services/db_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Checking the connection state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If an error occurred
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Something went wrong!')),
          );
        }

        // If user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          DbServices.checkAndCreateDocument(
            FirebaseAuth.instance.currentUser?.uid,
            FirebaseAuth.instance.currentUser?.displayName,
            FirebaseAuth.instance.currentUser?.email,
          );
          return const HomePage();
        }

        // If user is NOT logged in
        return const LoginPage();
      },
    );
  }
}
