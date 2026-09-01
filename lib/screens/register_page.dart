import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/auth_scaffold.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _key = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _hidden = true;

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _password, _confirm]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AuthService.instance.register(
        firstName: _first.text,
        lastName: _last.text,
        email: _email.text,
        password: _password.text,
      );
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Could not create account.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration decoration(String label) => InputDecoration(labelText: label);
    return AuthScaffold(
      title: 'Create your account',
      child: Form(
        key: _key,
        child: Column(
          children: [
            Row(children: [
              Expanded(child: TextFormField(controller: _first, decoration: decoration('First name'), validator: _required)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _last, decoration: decoration('Last name'), validator: _required)),
            ]),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: decoration('U of G email'),
              validator: (v) => AuthService.isUofGuelphEmail(v ?? '') ? null : 'Use a valid @uoguelph.ca email.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _hidden,
              decoration: decoration('Password').copyWith(
                helperText: '10+ characters with upper, lower, number, and symbol',
                suffixIcon: IconButton(onPressed: () => setState(() => _hidden = !_hidden), icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off)),
              ),
              validator: (v) => AuthService.passwordError(v ?? ''),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              obscureText: _hidden,
              decoration: decoration('Confirm password'),
              validator: (v) => v == _password.text ? null : 'Passwords do not match.',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _busy ? null : _register, child: Text(_busy ? 'Creating...' : 'Create account')),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) => (value ?? '').trim().isEmpty ? 'Required' : null;
}
