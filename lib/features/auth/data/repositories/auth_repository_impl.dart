import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:turf_app/core/error/failure.dart';
import 'package:turf_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl(this._auth, this._googleSignIn);

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<Either<Failure, UserCredential>> loginWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return right(credential);
    } on FirebaseAuthException catch (e) {
      return left(AuthFailure(e.message ?? 'Login failed'));
    } catch (e) {
      return left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserCredential>> loginWithPhone(String phoneNumber, String password) async {
    try {
      // Using phone number as email identifier for simplicity in this prototype
      final email = "$phoneNumber@turfapp.com";
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return right(credential);
    } on FirebaseAuthException catch (e) {
      return left(AuthFailure(e.message ?? 'Login failed'));
    } catch (e) {
      return left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserCredential>> signUpWithEmail(
    String email, 
    String password, 
    String username, 
    String contact,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await credential.user?.updateDisplayName(username);
      return right(credential);
    } on FirebaseAuthException catch (e) {
      return left(AuthFailure(e.message ?? 'Signup failed'));
    } catch (e) {
      return left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      return right(null);
    } catch (e) {
      return left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserCredential>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return left(AuthFailure('Google sign-in cancelled'));

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return right(userCredential);
    } catch (e) {
      return left(AuthFailure(e.toString()));
    }
  }
}
