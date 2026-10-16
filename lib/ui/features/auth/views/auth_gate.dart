import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/inbox_repository.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/firestore_storage_service.dart';
import '../../../features/inbox/views/inbox_screen.dart';
import '../../../view_models/inbox_view_model.dart';
import 'auth_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (user == null) return AuthScreen(authService: authService);

        final repository = InboxRepository(
          storageService: FirestoreStorageService(ownerId: user.uid),
        );
        return ChangeNotifierProvider(
          create: (_) => InboxViewModel(repository: repository)..init(),
          child: InboxScreen(authService: authService),
        );
      },
    );
  }
}
