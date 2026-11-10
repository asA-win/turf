import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_providers.g.dart';

@riverpod
FirebaseAuth firebaseAuth(Ref ref) {
  return FirebaseAuth.instance;
}

@riverpod
GoogleSignIn googleSignIn(Ref ref) {
  // Use a realistic client ID for web or load from environment variables
  // IMPORTANT: For Web, you MUST provide the Web Client ID from GCP Console.
  const webClientId = String.fromEnvironment('GOOGLE_CLIENT_ID', 
    defaultValue: '600790618967-j12p6a3c6j3k4r5l6m7n8o9p0q1r2s3t.apps.googleusercontent.com');
  
  return GoogleSignIn(
    clientId: kIsWeb ? webClientId : null,
  );
}
