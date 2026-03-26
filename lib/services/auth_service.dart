import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../supabase_config.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Auth state stream — maps Supabase events to User?
  Stream<User?> get authStateChanges =>
      _supabase.auth.onAuthStateChange.map((event) => event.session?.user);

  /// Current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign up with email and password
  /// Supabase automatically sends a verification OTP to the email
  Future<AuthResponse> signUpWithEmail(String email, String password, String name) async {
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': name.trim()},
    );
    return response;
  }

  /// Verify OTP code (for signup, recovery, or email change)
  Future<AuthResponse> verifyOTP(String email, String token, OtpType type) async {
    return await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: type,
    );
  }

  /// Resend OTP for signup verification
  Future<void> resendSignupOTP(String email) async {
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  /// Send password reset email (sends OTP)
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim());
  }

  /// Update user password (must be authenticated or have recovery session)
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    if (kIsWeb) {
      // Web: use Supabase OAuth popup
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: '${Uri.base.origin}/',
      );
      // The OAuth flow redirects, so we won't get a direct response here.
      // The auth state change listener will pick up the session.
      // Return a placeholder — the actual session comes via redirect.
      throw Exception('OAuth redirect initiated');
    } else {
      // Mobile: use google_sign_in package + Supabase signInWithIdToken
      const webClientId = '935006171646-8q6avai37vi7leb2bnpufoevtf29a71p.apps.googleusercontent.com';
      final googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google Sign-In cancelled');
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) throw Exception('No ID token from Google');

      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    }
  }

  /// Update user display name
  Future<void> updateDisplayName(String name) async {
    await _supabase.auth.updateUser(
      UserAttributes(data: {'display_name': name.trim()}),
    );
  }

  /// Update user profile in the profiles table
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null) return;
    await _supabase.from('profiles').update(data).eq('id', user.id);
  }

  /// Get user profile from the profiles table
  Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    return response;
  }

  /// Listen to profile changes in real-time
  Stream<Map<String, dynamic>> profileStream(String userId) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((list) => list.isNotEmpty ? list.first : {});
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }
    } catch (_) {}
    await _supabase.auth.signOut();
  }

  /// Get friendly error message
  static String getErrorMessage(dynamic e) {
    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('user not found') || msg.contains('invalid login')) {
        return 'Invalid email or password. Please try again.';
      }
      if (msg.contains('email already')) {
        return 'Email already registered. Please sign in.';
      }
      if (msg.contains('invalid email')) {
        return 'Please enter a valid email address.';
      }
      if (msg.contains('weak password')) {
        return 'Password is too weak. Please use a stronger password.';
      }
      if (msg.contains('otp') || msg.contains('token')) {
        return 'Invalid or expired verification code. Please try again.';
      }
      return e.message;
    }
    final str = e.toString();
    if (str.contains('cancelled') || str.contains('popup-closed')) {
      return '';
    }
    return str;
  }
}
