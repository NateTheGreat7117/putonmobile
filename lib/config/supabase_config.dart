import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Replace these with your actual Supabase credentials
  static const String supabaseUrl = 'https://xyfhefjpxxrtbfjukawr.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh5ZmhlZmpweHhydGJmanVrYXdyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwNTk3NjEsImV4cCI6MjA4NTYzNTc2MX0.4dU-dFZqbnHBnUzV246liF-GwfqmeiRm3xxWbkuxY8s';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}