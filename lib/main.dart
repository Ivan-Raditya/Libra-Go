import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libra_go/screens/splash_screen.dart';
import 'package:libra_go/screens/login_screen.dart';
import 'package:libra_go/screens/register_screen.dart';
import 'package:libra_go/screens/forgot_password_screen.dart';
import 'package:libra_go/screens/main_layout.dart';
import 'package:libra_go/services/firebase_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rdwpusqhwpdoeigkixud.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkd3B1c3Fod3Bkb2VpZ2tpeHVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzMjI2ODQsImV4cCI6MjA5Njg5ODY4NH0.uB_tz-ibhnn4O6IBp6oUC7-YXDnkqLVsrmNK5WIcmL0',
  );

  // Initialize Firebase (safely wrapped in try/catch inside the service)
  await FirebaseNotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Libra Go',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F9FB),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D1B2A)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/dashboard': (context) => const MainLayout(),
      },
    );
  }
}
