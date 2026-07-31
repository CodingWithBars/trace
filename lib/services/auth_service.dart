import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      if (cred.user != null) {
        final doc = await FirestoreService.admins.doc(cred.user!.uid).get();
        if (!doc.exists) {
          await _auth.signOut();
          return 'Access Denied: You do not have admin privileges.';
        }
      }

      return null; // success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found for this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Try again later.';
        default:
          return 'Login failed. Please try again.';
      }
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> createAdmin(String name, String email, String password) async {
    try {
      // Initialize a secondary Firebase app to prevent logging out the current admin
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'tempAdminCreator',
        options: Firebase.app().options,
      );
      
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final userCred = await tempAuth.createUserWithEmailAndPassword(email: email, password: password);
      
      if (userCred.user != null) {
        await FirestoreService.admins.doc(userCred.user!.uid).set({
          'name': name,
          'email': email,
          'role': 'admin',
          'created_at': FieldValue.serverTimestamp(),
          'status': 'active',
        });
      }

      await tempApp.delete();
      return null; // success
    } on FirebaseAuthException catch (e) {
      try {
        await Firebase.app('tempAdminCreator').delete();
      } catch (_) {}
      
      switch (e.code) {
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'weak-password':
          return 'The password provided is too weak.';
        default:
          return e.message ?? 'Failed to create admin account.';
      }
    } catch (e) {
      try {
        await Firebase.app('tempAdminCreator').delete();
      } catch (_) {}
      return 'An unexpected error occurred.';
    }
  }
}

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    // Enable offline persistence
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  static FirebaseFirestore get db => _db;

  // Collections
  static CollectionReference get students => _db.collection('students');
  static CollectionReference get events => _db.collection('events');
  static CollectionReference get attendance => _db.collection('attendance');
  static CollectionReference get funds => _db.collection('funds');
  static CollectionReference get announcements => _db.collection('announcements');
  static CollectionReference get admins => _db.collection('admins');
}
