import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const GryphMarketApp());
}

class GryphMarketApp extends StatelessWidget {
  const GryphMarketApp({super.key});

  static const gryphonRed = Color(0xFFC20430);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GryphMarket',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: gryphonRed),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
