import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:io';

void main() async {
  await Supabase.initialize(
    url: 'https://rdwpusqhwpdoeigkixud.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkd3B1c3Fod3Bkb2VpZ2tpeHVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzMjI2ODQsImV4cCI6MjA5Njg5ODY4NH0.uB_tz-ibhnn4O6IBp6oUC7-YXDnkqLVsrmNK5WIcmL0',
  );
  
  final client = Supabase.instance.client;
  
  try {
    final profiles = await client.from('profiles').select().limit(5);
    print('Profiles data: ${jsonEncode(profiles)}');
  } catch (e) {
    print('Error fetching profiles: $e');
  }
  
  exit(0);
}
