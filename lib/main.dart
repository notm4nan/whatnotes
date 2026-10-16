import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'data/services/auth_service.dart';
import 'data/services/firebase_config.dart';
import 'ui/core/app_theme.dart';
import 'ui/core/theme_controller.dart';
import 'ui/features/auth/views/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeController = ThemeController();
  await themeController.load();

  var firebaseConfigured = false;
  try {
    await Firebase.initializeApp(
      options: FirebaseConfig.hasDartDefines ? FirebaseConfig.options : null,
    );
    firebaseConfigured = true;
  } catch (error) {
    debugPrint('Firebase initialization failed: $error');
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: themeController)],
      child: ByteInboxApp(firebaseConfigured: firebaseConfigured),
    ),
  );
}

class ByteInboxApp extends StatelessWidget {
  const ByteInboxApp({super.key, required this.firebaseConfigured});

  final bool firebaseConfigured;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, theme, _) => MaterialApp(
        title: 'WhatNotes',
        debugShowCheckedModeBanner: false,
        theme: theme.mode == AppThemeMode.retro
            ? AppTheme.retroTheme
            : AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: theme.mode == AppThemeMode.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: firebaseConfigured
            ? AuthGate(authService: AuthService())
            : const FirebaseSetupRequiredScreen(),
      ),
    );
  }
}

class FirebaseSetupRequiredScreen extends StatelessWidget {
  const FirebaseSetupRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Firebase is not configured. Add android/app/google-services.json and rebuild the app.',
        ),
      ),
    ),
  );
}
