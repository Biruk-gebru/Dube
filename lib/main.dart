import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Error loading .env file: $e");
    // Provide fallback values or handle the error appropriately
  }
  
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    print("Error: Supabase credentials are missing or empty");
    // Handle the error appropriately
  }
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    
    return MultiProvider(
      providers: [
        Provider<SupabaseClient>.value(value: supabase),
        ProxyProvider<SupabaseClient, AuthService>(
          update: (context, supabase, previous) => AuthService(supabase),
        ),
        ProxyProvider<SupabaseClient, SupabaseService>(
          update: (context, supabase, previous) => SupabaseService(supabase),
        ),
      ],
      child: MaterialApp(
        title: 'Transaction Logger',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: StreamBuilder<AuthState>(
          stream: supabase.auth.onAuthStateChange,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final session = snapshot.data?.session;
              if (session != null) {
                return const HomeScreen();
              } else {
                return const LoginScreen();
              }
            }
            return const Scaffold(
      body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        ),
      ),
    );
  }
}
