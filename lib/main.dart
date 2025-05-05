import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Error handling without print
  }
  
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
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
    final languageProvider = LanguageProvider();
    final themeProvider = ThemeProvider();
    
    return MultiProvider(
      providers: [
        Provider<SupabaseClient>.value(value: supabase),
        ProxyProvider<SupabaseClient, AuthService>(
          update: (context, supabase, previous) => AuthService(supabase),
        ),
        ProxyProvider<SupabaseClient, SupabaseService>(
          update: (context, supabase, previous) => SupabaseService(supabase),
        ),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: languageProvider),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'Dube',
            theme: context.watch<ThemeProvider>().isDarkMode 
                ? AppTheme.darkTheme 
                : AppTheme.lightTheme,
            locale: context.watch<LanguageProvider>().locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('am', ''), // Amharic
            ],
            debugShowCheckedModeBanner: false,
            home: StreamBuilder<AuthState>(
              stream: supabase.auth.onAuthStateChange,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final session = snapshot.data?.session;
                  if (session != null) {
                    return const HomeScreen();
                  }
                }
                return const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
