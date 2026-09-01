import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() ?? {};
          final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
          return ListView(padding: const EdgeInsets.all(24), children: [
            const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 52)),
            const SizedBox(height: 20),
            ListTile(leading: const Icon(Icons.badge_outlined), title: const Text('Name'), subtitle: Text(name.isEmpty ? (user.displayName ?? 'Not set') : name)),
            ListTile(leading: const Icon(Icons.email_outlined), title: const Text('Email'), subtitle: Text(user.email ?? '')),
            const SizedBox(height: 20),
            OutlinedButton.icon(onPressed: AuthService.instance.signOut, icon: const Icon(Icons.logout), label: const Text('Sign out')),
          ]);
        },
      ),
    );
  }
}
