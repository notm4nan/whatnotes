import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../data/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _isSignIn = true;
  bool _isBusy = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isBusy = true; _error = null; });
    try {
      if (_isSignIn) {
        await widget.authService.signIn(identifier: _identifier.text, password: _password.text);
      } else {
        await widget.authService.signUp(identifier: _identifier.text, password: _password.text);
      }
    } on FirebaseAuthException catch (error) {
      setState(() => _error = _friendlyError(error));
    } catch (error) {
      setState(() => _error = 'Could not connect. Check your internet and try again.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _friendlyError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect username/email or password.';
      case 'email-already-in-use':
        return 'That username/email is already registered.';
      case 'weak-password':
        return 'Use a password with at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Check your connection and retry.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled in Firebase. Enable it in Firebase Console → Authentication → Sign-in method.';
      case 'invalid-email':
        return 'Enter a valid email address or a username without spaces.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.all_inbox_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(_isSignIn ? 'Welcome back' : 'Create your account', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Use an email or username to keep your inbox synced.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _identifier,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email or username', prefixIcon: Icon(Icons.person_outline)),
                    validator: (value) => value == null || value.trim().length < 3 ? 'Enter at least 3 characters.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                    validator: (value) => value == null || value.length < 6 ? 'Use at least 6 characters.' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(onPressed: _isBusy ? null : _submit, child: _isBusy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_isSignIn ? 'Sign in' : 'Sign up')),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isBusy
                        ? null
                        : () => setState(() {
                            _isSignIn = !_isSignIn;
                            _error = null;
                          }),
                    icon: Icon(_isSignIn ? Icons.person_add_alt_1 : Icons.login),
                    label: Text(_isSignIn ? 'Create a new account' : 'Back to sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
