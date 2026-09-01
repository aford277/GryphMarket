import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  static bool isUofGuelphEmail(String value) {
    return RegExp(r'^[^@\s]+@uoguelph\.ca$', caseSensitive: false)
        .hasMatch(value.trim());
  }

  static String? passwordError(String value) {
    if (value.length < 10) return 'Use at least 10 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Add an uppercase letter.';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Add a lowercase letter.';
    if (!RegExp(r'\d').hasMatch(value)) return 'Add a number.';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) return 'Add a symbol.';
    return null;
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName('${firstName.trim()} ${lastName.trim()}');
    await _db.collection('users').doc(user.uid).set({
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': normalizedEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

  Future<void> signOut() => _auth.signOut();
}
