import 'package:flutter/material.dart';
import 'auth_service.dart'; // We will create this file next

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepOrange.shade400, Colors.orange.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your App Icon/Logo
            Image.asset(
              'assets/srpicon.png', // Make sure you have this asset
              height: 120,
            ),
            const SizedBox(height: 20),
            const Text(
              'Smart Route Planner',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Intelligent Routing, Simplified.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 60),
            // Google Sign-In Button
            ElevatedButton.icon(
              icon: Image.asset(
                'assets/google_logo.png',
                height: 24.0,
              ), // A google logo asset
              label: const Text(
                'Sign in with Google',
                style: TextStyle(fontSize: 18, color: Colors.black87),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: const Size(250, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              onPressed: () async {
                try {
                  await authService.signInWithGoogle();
                  // The AuthGate will handle navigation
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to sign in: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
