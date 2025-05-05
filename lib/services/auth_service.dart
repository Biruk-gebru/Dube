import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class AuthService {
  final SupabaseClient _supabaseClient;

  AuthService(this._supabaseClient);

  User? get currentUser => _supabaseClient.auth.currentUser;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _supabaseClient.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user != null) {
      final profile = Profile(
        id: response.user!.id, // This will be the UUID
        userId: response.user!.id, // This will be the same UUID
        username: username,
        email: email,
        createdAt: DateTime.now(),
      );

      await _supabaseClient.from('profiles').insert(profile.toJson());
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      // Check if profile exists
      final profileResponse = await _supabaseClient
          .from('profiles')
          .select()
          .eq('user_id', response.user!.id)
          .maybeSingle();

      if (profileResponse == null) {
        // Create profile if it doesn't exist
        final profile = Profile(
          id: response.user!.id, // This will be the UUID
          userId: response.user!.id, // This will be the same UUID
          username: email.split('@')[0], // Use email prefix as username
          email: email,
          createdAt: DateTime.now(),
        );

        await _supabaseClient.from('profiles').insert(profile.toJson());
      }
    }

    return response;
  }

  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  Future<Profile?> getCurrentUser() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) return null;

    final response = await _supabaseClient
        .from('profiles')
        .select()
        .eq('user_id', user.id)
        .single();
    return Profile.fromJson(response);
  }

  Stream<AuthState> get authStateChanges => _supabaseClient.auth.onAuthStateChange;

  Future<void> resetPassword(String email) async {
    await _supabaseClient.auth.resetPasswordForEmail(email);
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabaseClient.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> updateEmail(String newEmail) async {
    await _supabaseClient.auth.updateUser(
      UserAttributes(email: newEmail),
    );
  }
} 