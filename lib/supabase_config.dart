import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration for AxoLink project
/// Replace the URL and anonKey with your Supabase project credentials
class SupabaseConfig {
  // TODO: Replace with your Supabase project URL
  static const String supabaseUrl = 'https://nwrbswlmfessthvjrqpx.supabase.co';
  // TODO: Replace with your Supabase anon (public) key
  static const String supabaseAnonKey = 'sb_publishable_M6uS-3hmJS2k8AsEZ_QX0g_bUqg8LOH';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  /// Get the Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;
}
