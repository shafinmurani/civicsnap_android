import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// LOGIN WITH GOOGLE (new google_sign_in API)
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      unawaited(
        googleSignIn.initialize(
          serverClientId:
              "506969417253-4mk05ahmbunoq1ks2lodnkencnelhd1v.apps.googleusercontent.com",
        ),
      );

      // Check if the platform supports authenticate()
      if (!googleSignIn.supportsAuthenticate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In not supported on this platform'),
          ),
        );
        return;
      }

      // Trigger authentication
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login cancelled')));
        return;
      }

      // Get an authorization code from the user
      final auth = await googleUser.authorizationClient.authorizeScopes([
        'email',
        'profile',
      ]);

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
      );

      // Sign in to Firebase
      await _auth.signInWithCredential(credential);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  /// LOGOUT
  Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
