import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:turf_app/core/error/failure.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  
  Future<Either<Failure, UserCredential>> loginWithEmail(String email, String password);
  
  Future<Either<Failure, UserCredential>> loginWithPhone(String phoneNumber, String password);
  
  Future<Either<Failure, UserCredential>> signUpWithEmail(String email, String password, String username, String contact);
  
  Future<Either<Failure, void>> signOut();
  
  Future<Either<Failure, UserCredential>> signInWithGoogle();

  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException error) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? resendToken,
  });

  Future<Either<Failure, UserCredential>> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  });
}
