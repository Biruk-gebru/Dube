import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import '../../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    setState(() => _loading = true);
    
    final input = _emailOrUsernameController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
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
            throw Exception('Invalid username or email');
          }
          
          final email = response['email'];
          
          // Sign in with the email
          await context.read<AuthService>().signIn(
            email: email,
            password: password,
          );
        }
      } else {
        // Sign up
        final username = _usernameController.text.trim();
        
        // Basic validation
        if (username.isEmpty || input.isEmpty || password.isEmpty) {
          throw Exception('All fields are required');
        }

        // Username format validation
        if (username.length < 3) {
          throw Exception('Username must be at least 3 characters long');
        }

        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
          throw Exception('Username can only contain letters, numbers, and underscores');
        }

        // Email format validation
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input)) {
          throw Exception('Please enter a valid email address');
        }

        // Password strength validation
        if (password.length < 6) {
          throw Exception('Password must be at least 6 characters long');
        }

        await context.read<AuthService>().signUp(
          email: input,
          password: password,
          username: username,
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.account_balance,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                _isLogin ? 'Welcome Back' : 'Create Account',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!_isLogin) ...[
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailOrUsernameController,
                decoration: InputDecoration(
                  labelText: _isLogin ? 'Email or Username' : 'Email',
                  prefixIcon: const Icon(Icons.email),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _authenticate(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _authenticate,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_isLogin ? 'Sign In' : 'Sign Up'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() => _isLogin = !_isLogin);
                },
                child: Text(
                  _isLogin
                      ? 'Don\'t have an account? Sign Up'
                      : 'Already have an account? Sign In',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 