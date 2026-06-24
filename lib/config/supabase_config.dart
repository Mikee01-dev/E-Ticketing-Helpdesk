import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

class SupabaseConfig {
  static SupabaseConfig? _instance;
  static SupabaseConfig get instance => _instance!;
  
  SupabaseConfig._internal();
  
  static Future<void> init() async {
    if (_instance != null) return;
    
    _instance = SupabaseConfig._internal();
    
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      debug: Env.isDevelopment,
    );
  }
  
  // Langsung akses Supabase.instance.client
  static SupabaseClient get client => Supabase.instance.client;
  
  // Helper method untuk mendapatkan user saat ini
  static User? get currentUser => client.auth.currentUser;
  
  // Cek apakah user login
  static bool get isAuthenticated => currentUser != null;
  
  // Logout
  static Future<void> logout() async {
    await client.auth.signOut();
  }
}