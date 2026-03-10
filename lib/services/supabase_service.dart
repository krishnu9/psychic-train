import 'package:supabase_flutter/supabase_flutter.dart';

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
    await client.auth.signOut();
  }

  /// Listen to auth state changes.
  static Stream<AuthState> get onAuthStateChange =>
      client.auth.onAuthStateChange;
}
