import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Centralized access to the Supabase client.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  /// Current authenticated user, or null if not logged in.
  static User? get currentUser => client.auth.currentUser;

  /// Whether a user is currently signed in.
  static bool get isAuthenticated => currentUser != null;

  /// Sign up with email & password.
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return client.auth.signUp(email: email, password: password);
  }

  /// Sign in with email & password.
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  /// Sign out.
  static Future<void> signOut() async {
    final googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut();
    }
    await client.auth.signOut();
  }

  /// Sign in with Google (platform-aware).
  static Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _signInWithGoogleWeb();
    } else {
      await _signInWithGoogleMobile();
    }
  }

  /// Web: OAuth redirect flow via Supabase.
  static Future<void> _signInWithGoogleWeb() async {
    final uri = Uri.base;
    final redirectTo = '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );
  }

  /// Mobile: native Google Sign-In plugin.
  static Future<void> _signInWithGoogleMobile() async {
    const webClientId = '558063778130-iljeoh96pm97mrklq3hvok5f8lqe5aof.apps.googleusercontent.com';
    const iosClientId = '558063778130-n962ih4qij3ihmd349n6nm1n9dscv084.apps.googleusercontent.com';

    final googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Google sign in was canceled.');
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw const AuthException('No Google ID Token found.');
    }

    await client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  /// Listen to auth state changes.
  static Stream<AuthState> get onAuthStateChange =>
      client.auth.onAuthStateChange;
}
