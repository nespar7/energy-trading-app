import 'package:energy_app/auth/auth_gate.dart';
import 'package:energy_app/auth/auth_service.dart';
import 'package:flutter/material.dart';

class Session {
  static Future<void> logout(BuildContext context) async {
    final auth = AuthService();
    try {
      await auth.signOut();

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Signout failed')));
    }
  }
}
