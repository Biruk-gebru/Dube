import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import '../../theme/app_theme.dart';
import 'signup_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/language_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    
    final input = _emailOrUsernameController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // Check if input is email or username
      if (input.contains('@')) {
        // Direct email login
        await context.read<AuthService>().signIn(
          email: input,
          password: password,
        );
      } else {
        // Username login - get email from profiles table
        final supabase = Supabase.instance.client;
        final response = await supabase
            .from('profiles')
            .select('email')
            .eq('username', input)
            .maybeSingle();
        
        if (response == null) {
          throw Exception(AppLocalizations.of(context)!.invalidCredentials);
        }
        
        final email = response['email'];
        
        // Sign in with the email
        await context.read<AuthService>().signIn(
          email: email,
          password: password,
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.loginFailed),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.login),
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            tooltip: l10n.language,
            onSelected: (Locale locale) {
              context.read<LanguageProvider>().setLocale(locale);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
              PopupMenuItem<Locale>(
                value: const Locale('en'),
                child: Text(l10n.english),
              ),
              PopupMenuItem<Locale>(
                value: const Locale('am'),
                child: Text(l10n.amharic),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Icon(
                    Icons.account_balance,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  l10n.welcomeBack,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailOrUsernameController,
                  decoration: InputDecoration(
                    labelText: l10n.emailOrUsername,
                    prefixIcon: const Icon(Icons.email),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                      tooltip: _passwordVisible ? l10n.hidePassword : l10n.showPassword,
                    ),
                  ),
                  obscureText: !_passwordVisible,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(l10n.signIn),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    );
                  },
                  child: Text(l10n.dontHaveAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 