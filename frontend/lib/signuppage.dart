//import 'package:byte_eat/phone_signup-page.dart';
import 'phone_signup-page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final Uri baseUrl = Uri.parse('http://localhost:5000'); // Flask backend

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  // Check if user is already authenticated (for OAuth callback)

  // In class _SignUpPageState...

  void _checkAuthState() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // User is logged in. Check if a profile exists for them in our 'users' table.
      final userProfile = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id) // Query by the user's unique ID
          .maybeSingle();

      // If no profile exists, create one.
      if (userProfile == null && user.email != null) {
        await Supabase.instance.client.from('users').insert({
          'id': user.id, // Link to the auth user
          'email': user.email,
          'name': user.userMetadata?['full_name'] ?? 'New User',
        });
      }

      // Now that we're sure the user is saved, navigate to the home page.
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Traditional sign-up with Flask
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Sign up failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Improved Google Sign-In with Supabase
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // This gets the current URL of your Flutter app
      final redirectUrl = kIsWeb
          ? html.window.location.origin
          : 'io.supabase.flutter://login';

      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl, // Use the dynamic URL
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  /*
  // Handle successful Google authentication
  Future<void> _handleSuccessfulGoogleAuth(User user) async {
    try {
      final email = user.email;
      if (email == null) {
        // Handle case where Google user has no email
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not retrieve email from Google.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final name = user.userMetadata?['name'] ?? 'Google User';

      // Check if user already exists in your database
      final existing = await Supabase.instance.client
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (existing == null) {
        // Create new user record
        await Supabase.instance.client.from('users').insert({
          'email': email,
          'name': name,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google account linked successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to homepage
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving user data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Text(
                'Create Account',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign up to get started',
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 32),
              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Full Name', Icons.person),
                validator: (value) => value!.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Email', Icons.email),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter your email';
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDecorationWithToggle(
                  'Password',
                  Icons.lock,
                  () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  _obscurePassword,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters long';
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    return 'Password must contain an uppercase letter';
                  }
                  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                    return 'Password must contain a special character';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: _inputDecorationWithToggle(
                  'Confirm Password',
                  Icons.lock,
                  () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                  _obscureConfirmPassword,
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Sign Up Button
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: const Color(0xFF6B46C1),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign Up', style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 24),

              // Google Sign-In Button
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata, size: 24),
                label: const Text('Sign up with Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16), // Add some space
              // --- NEW: Phone Sign-Up Button ---
              OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        // Navigate to the first step of the phone signup flow
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PhoneSignUpPage(),
                          ),
                        );
                      },
                icon: const Icon(Icons.phone_android, size: 24),
                label: const Text('Sign up with Phone'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // --- END: Phone Sign-Up Button ---
              const SizedBox(height: 24),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xFF6B46C1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  InputDecoration _inputDecorationWithToggle(
    String label,
    IconData icon,
    VoidCallback toggle,
    bool isObscured,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: IconButton(
        icon: Icon(isObscured ? Icons.visibility : Icons.visibility_off),
        onPressed: toggle,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
