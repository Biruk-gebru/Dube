import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../models/profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = context.read<AuthService>().currentUser?.id;
      if (userId != null) {
        final profile = await context.read<SupabaseService>().getProfile(userId);
        if (profile != null) {
          setState(() => _profile = profile);
          _usernameController.text = profile.username;
          _emailController.text = profile.email;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _promptForPassword() {
    _currentPasswordController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Verify Password'),
          content: TextField(
            controller: _currentPasswordController,
            decoration: const InputDecoration(
              labelText: 'Current Password',
              hintText: 'Enter your current password to continue',
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_currentPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password is required')),
                  );
                  return;
                }
                Navigator.of(context).pop();
                _enterEditMode();
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _enterEditMode() {
    setState(() {
      _isEditing = true;
      _usernameController.text = _profile?.username ?? '';
      _emailController.text = _profile?.email ?? '';
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset fields when canceling edit
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _usernameController.text = _profile?.username ?? '';
        _emailController.text = _profile?.email ?? '';
      }
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if new password and confirm password match
    if (_newPasswordController.text.isNotEmpty && 
        _newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = context.read<AuthService>().currentUser?.id;
      if (userId != null) {
        // Update email if changed
        if (_emailController.text != _profile?.email) {
          await context.read<AuthService>().updateEmail(_emailController.text);
        }

        // Update password if provided
        if (_newPasswordController.text.isNotEmpty) {
          try {
            await context.read<AuthService>().updatePassword(_newPasswordController.text);
          } catch (e) {
            // Handle specific password-related errors
            String errorMessage = 'Could not update password';
            
            if (e.toString().contains('same password') || 
                e.toString().contains('must be different') ||
                e.toString().contains('previous password')) {
              errorMessage = 'Please choose a new password that you haven\'t used before';
            } else if (e.toString().contains('weak') || 
                       e.toString().contains('strength')) {
              errorMessage = 'Please choose a stronger password with a mix of letters, numbers, and symbols';
            }
            
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
            );
            return;
          }
        }

        // Update profile
        final updatedProfile = _profile!.copyWith(
          username: _usernameController.text,
          email: _emailController.text,
        );
        await context.read<SupabaseService>().updateProfile(updatedProfile);
        await _loadProfile();

        // Exit edit mode
        setState(() => _isEditing = false);
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Generic error handling
      String errorMessage = 'Error updating profile';
      
      if (e.toString().contains('password')) {
        errorMessage = 'There was a problem with your password. Please try a different one.';
      } else if (e.toString().contains('email')) {
        errorMessage = 'There was a problem with your email. Please try a different one.';
      } else if (e.toString().contains('username')) {
        errorMessage = 'That username is not available. Please try a different one.';
      } else {
        errorMessage = 'Error updating profile: ${e.toString().split(']').last.trim()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Profile',
              onPressed: _promptForPassword,
            )
          else
          IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _isEditing ? _buildEditForm() : _buildProfileView(),
            ),
    );
  }

  Widget _buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          _profile?.username ?? 'Username',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _profile?.email ?? 'Email',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Username'),
          subtitle: Text(_profile?.username ?? ''),
        ),
        ListTile(
          leading: const Icon(Icons.email),
          title: const Text('Email'),
          subtitle: Text(_profile?.email ?? ''),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Member Since'),
          subtitle: Text(_profile?.createdAt != null
              ? '${_profile!.createdAt.day}/${_profile!.createdAt.month}/${_profile!.createdAt.year}'
              : ''),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 50,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
          const Divider(),
                    const Text(
            'Change Password (Optional)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: Icon(Icons.lock_outline),
              hintText: 'Leave empty to keep current password',
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(
              labelText: 'Confirm New Password',
              prefixIcon: Icon(Icons.lock_outline),
              hintText: 'Confirm your new password',
            ),
            obscureText: true,
            validator: (value) {
              if (_newPasswordController.text.isNotEmpty && value != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
                    const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _toggleEditMode,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                  child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
        ],
            ),
    );
  }
} 