import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  late Future<DocumentSnapshot<Map<String, dynamic>>>
      _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final user = _currentUser;

    if (user == null) {
      return;
    }

    _profileFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
  }

  void _retryLoadingProfile() {
    if (_currentUser == null) {
      return;
    }

    setState(() {
      _loadProfile();
    });
  }

  Future<void> _signOut() async {
    try {
      await AuthService.instance.signOut();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not sign out.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(
          child: Text('You are not currently logged in.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: FutureBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 52,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Could not load your profile.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _retryLoadingProfile,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            );
          }

          final document = snapshot.data;
          final data = document?.data() ?? {};

          final firstName =
              data['firstName'] as String? ?? '';

          final lastName =
              data['lastName'] as String? ?? '';

          final firestoreName =
              '$firstName $lastName'.trim();

          final displayedName = firestoreName.isNotEmpty
              ? firestoreName
              : user.displayName ?? 'Not set';

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const CircleAvatar(
                radius: 48,
                child: Icon(
                  Icons.person,
                  size: 52,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Name'),
                subtitle: Text(displayedName),
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(user.email ?? 'Not set'),
              ),
              if (document != null && !document.exists)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No Firestore profile document was found. '
                    'Showing information from your login account instead.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          );
        },
      ),
    );
  }
}