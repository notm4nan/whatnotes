import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({required String identifier, required String password}) {
    return _auth.signInWithEmailAndPassword(email: _normaliseEmail(identifier), password: password);
  }

  Future<UserCredential> signUp({required String identifier, required String password}) {
    return _auth.createUserWithEmailAndPassword(email: _normaliseEmail(identifier), password: password);
  }

  Future<void> signOut() => _auth.signOut();

  String _normaliseEmail(String identifier) {
    final value = identifier.trim();
    if (value.contains('@')) return value;
    return '$value@byteinbox.local';
  }
}
