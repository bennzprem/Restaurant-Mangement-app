//import 'package:byte_eat/phone_signup-page.dart';
import 'package:flutter/gestures.dart';

import 'phone_signup-page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'theme.dart';
import 'widgets/header_widget.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  double _passwordStrength = 0.0;
  String _passwordStrengthLabel = '';

  // Animations to match login page
  late AnimationController _formAnimationController;
  late AnimationController _logoAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;
  late AnimationController _visualAnimationController;
  late Animation<double> _sunRiseAnimation;
  late Animation<double> _cloudDriftAnimation;

  final Uri baseUrl = Uri.parse('http://localhost:5000');

  @override
  void initState() {
    super.initState();
    _checkAuthState();

    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Visual (sun + clouds) animation
    _visualAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    _sunRiseAnimation = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(
          parent: _visualAnimationController, curve: Curves.easeInOutSine),
    );
    _cloudDriftAnimation = Tween<double>(begin: -40, end: 40).animate(
      CurvedAnimation(parent: _visualAnimationController, curve: Curves.linear),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _logoRotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _logoAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _formAnimationController.forward();
    });

    _passwordController.addListener(() {
      _evaluatePassword(_passwordController.text);
    });
  }

  void _checkAuthState() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final userProfile = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (userProfile == null && user.email != null) {
        await Supabase.instance.client.from('users').insert({
          'id': user.id,
          'email': user.email,
          'name': user.userMetadata?['full_name'] ?? 'New User',
        });
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  @override
  void dispose() {
    _formAnimationController.dispose();
    _logoAnimationController.dispose();
    _visualAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _evaluatePassword(String value) {
    int score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[a-z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) score++;

    setState(() {
      _passwordStrength = (score / 5).clamp(0, 1).toDouble();
      if (_passwordStrength <= 0.2) {
        _passwordStrengthLabel = 'Very weak';
      } else if (_passwordStrength <= 0.4) {
        _passwordStrengthLabel = 'Weak';
      } else if (_passwordStrength <= 0.6) {
        _passwordStrengthLabel = 'Fair';
      } else if (_passwordStrength <= 0.8) {
        _passwordStrengthLabel = 'Good';
      } else {
        _passwordStrengthLabel = 'Strong';
      }
    });
  }

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please log in.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Sign up failed'),
              backgroundColor: Colors.red.withOpacity(0.8),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e'),
            backgroundColor: Colors.red.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final redirectUrl =
          kIsWeb ? html.window.location.origin : 'io.supabase.flutter://login';

      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: $e'),
            backgroundColor: Colors.red.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: false),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 0),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF000000), Color(0xFF0F0F10)]
                  : const [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  // Desktop layout
                  return Column(
                    children: [
                      HeaderWidget(
                        active: HeaderActive.signup,
                        showBack: true,
                        onBack: () =>
                            Navigator.pushReplacementNamed(context, '/'),
                      ),
                      Expanded(child: _buildDesktopLayout()),
                    ],
                  );
                } else {
                  // Mobile layout
                  return Column(
                    children: [
                      HeaderWidget(
                        active: HeaderActive.signup,
                        showBack: true,
                        onBack: () =>
                            Navigator.pushReplacementNamed(context, '/'),
                      ),
                      Expanded(child: _buildMobileLayout()),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 640),
        child: Material(
          elevation: 24,
          shadowColor: Colors.black12,
          borderRadius: BorderRadius.circular(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Row(
              children: [
                // Left side - Form on light background
                Expanded(
                  flex: 1,
                  child: Container(
                    color: isDark
                        ? const Color(0xFF0F0F10)
                        : const Color(0xFFF7F8F9),
                    child: _buildFormSection(),
                  ),
                ),
                // Right side - Visual
                Expanded(
                  flex: 1,
                  child: _buildVisualSection(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height < 700 ? 5 : 20),
            _buildLogoSection(),
            SizedBox(
                height: MediaQuery.of(context).size.height < 700 ? 10 : 20),
            _buildFormSection(),
            SizedBox(height: MediaQuery.of(context).size.height < 700 ? 5 : 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _logoAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Transform.rotate(
            angle: _logoRotateAnimation.value,
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width < 600 ? 60 : 80,
                  height: MediaQuery.of(context).size.width < 600 ? 60 : 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor, // Using theme color
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/logo/logo.gif',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(
                    height: MediaQuery.of(context).size.width < 600 ? 12 : 16),
                Text(
                  'ByteEat',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 600 ? 24 : 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkTextColor, // Using theme color
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(
                    height: MediaQuery.of(context).size.width < 600 ? 6 : 8),
                Text(
                  'Create your account',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
                    color: AppTheme.lightTextColor, // Using theme color
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormSection() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.width < 600
              ? (MediaQuery.of(context).size.height < 700 ? 12.0 : 16.0)
              : 32.0,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildSignUpFormCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentColor,
            AppTheme.darkTextColor
          ], // Using theme colors
        ),
      ),
      child: Stack(
        children: [
          // Support text top-right
          Positioned(
            top: 24,
            right: 24,
            child: Row(
              children: [
                Icon(Icons.headset_mic, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                const Text('Support',
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // Rising sun
          AnimatedBuilder(
            animation: _visualAnimationController,
            builder: (context, _) {
              return Positioned(
                top: 80 + _sunRiseAnimation.value,
                left: 80,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                        colors: [Color(0xFFFFF59D), Color(0x00FFF59D)]),
                  ),
                ),
              );
            },
          ),
          // Floating clouds
          AnimatedBuilder(
            animation: _visualAnimationController,
            builder: (context, _) {
              return Stack(children: [
                _cloud(x: 120 + _cloudDriftAnimation.value, y: 140, scale: 1.0),
                _cloud(x: 260 - _cloudDriftAnimation.value, y: 90, scale: 0.8),
              ]);
            },
          ),
          // Food card mock
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 40),
              width: 420,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16)),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/food_background.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Join ByteEat today',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20)),
                        const SizedBox(height: 8),
                        Text(
                          'Create an account to start exploring delicious food options.',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.9)),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 36,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                            ),
                            child: const Text('Learn more'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Section title bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Join our community',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Create an account to start your food journey with ByteEat.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpFormCard() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool compact = MediaQuery.of(context).size.height < 700;
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double cardPadding =
        compact || isMobile ? (isMobile ? 16.0 : 20.0) : 40.0;
    final double titleSize = compact || isMobile ? 24.0 : 32.0;
    final double gapLarge =
        compact || isMobile ? (isMobile ? 16.0 : 20.0) : 40.0;
    final double gapMed = compact || isMobile ? (isMobile ? 12.0 : 16.0) : 24.0;
    final double gapSmall = compact || isMobile ? (isMobile ? 4.0 : 6.0) : 12.0;

    return Container(
      constraints: BoxConstraints(
        maxWidth: isMobile ? double.infinity : 450,
        maxHeight: isMobile
            ? MediaQuery.of(context).size.height * 0.7
            : double.infinity,
      ),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create Account',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Colors.white
                    : AppTheme.darkTextColor, // Using theme color
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: gapSmall),
            Text(
              'Sign up to get started with ByteEat',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: isDark
                    ? Colors.grey[300]
                    : AppTheme.lightTextColor, // Using theme color
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: gapLarge),
            _buildFormFields(),
            SizedBox(height: gapMed),
            _buildPasswordStrength(),
            SizedBox(height: gapMed),
            _buildTermsRow(),
            SizedBox(height: gapMed),
            _buildSignUpButton(),
            SizedBox(height: gapMed),
            _buildDivider(),
            SizedBox(height: gapMed),
            _buildSocialButtons(),
            SizedBox(height: compact || isMobile ? 16 : 32),
            _buildLoginLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildInputField(
            controller: _nameController,
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: Icons.person_outline,
            validator: (value) =>
                value!.isEmpty ? 'Please enter your name' : null,
          ),
          SizedBox(height: MediaQuery.of(context).size.width < 600 ? 20 : 24),
          _buildInputField(
            controller: _emailController,
            labelText: 'Email Address',
            hintText: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Please enter an email address';
              // Allow common providers or any well-formed email
              final emailRegex = RegExp(r'^[\w\.-]+@([\w\-]+\.)+[A-Za-z]{2,}$');
              final allowedProviders = RegExp(
                  r'@(gmail\.com|yahoo\.com|hotmail\.com)$',
                  caseSensitive: false);
              if (!emailRegex.hasMatch(v)) return 'Enter a valid email address';
              if (!allowedProviders.hasMatch(v))
                return 'Use a common provider (gmail, yahoo, hotmail)';
              return null;
            },
          ),
          SizedBox(height: MediaQuery.of(context).size.width < 600 ? 20 : 24),
          _buildInputField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: (value) {
              final v = value ?? '';
              if (v.length < 8) return 'At least 8 characters required';
              if (!RegExp(r'[A-Z]').hasMatch(v))
                return 'Include at least one uppercase letter';
              if (!RegExp(r'[0-9]').hasMatch(v))
                return 'Include at least one number';
              if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(v))
                return 'Include at least one special character';
              return null;
            },
          ),
          SizedBox(height: MediaQuery.of(context).size.width < 600 ? 20 : 24),
          _buildInputField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            hintText: 'Confirm your password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF495057),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.width < 600 ? 6 : 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword
              ? (controller == _confirmPasswordController
                  ? _obscureConfirmPassword
                  : _obscurePassword)
              : false,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : const Color(0xFF212529),
            fontWeight: FontWeight.w500,
          ),
          cursorColor: AppTheme.primaryColor,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[400],
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              size: 22,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      (controller == _confirmPasswordController
                              ? _obscureConfirmPassword
                              : _obscurePassword)
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                      size: 22,
                    ),
                    onPressed: () => setState(() {
                      if (controller == _confirmPasswordController) {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      } else {
                        _obscurePassword = !_obscurePassword;
                      }
                    }),
                  )
                : null,
            filled: true,
            fillColor:
                isDark ? const Color(0xFF151515) : const Color(0xFFF8F9FA),
            contentPadding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.width < 600 ? 16.0 : 18.0,
              horizontal: 20.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: AppTheme.primaryColor, // Using theme color
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Colors.red[300]!,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Colors.red[300]!,
                width: 2,
              ),
            ),
            errorStyle: TextStyle(
              color: Colors.red[400],
              fontSize: 13,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.width < 600 ? 48 : 56,
      child: ElevatedButton(
        onPressed: _isLoading || !_acceptTerms ? null : _signUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor, // Using mint lime theme color
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: AppTheme.primaryColor.withOpacity(0.3),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        _buildSocialButton(
          onPressed: _isLoading ? null : _signInWithGoogle,
          icon: Icons.g_mobiledata_outlined,
          label: 'Sign up with Google',
          backgroundColor: Colors.white,
          textColor: AppTheme.darkTextColor, // Using theme color
          borderColor: Colors.grey[300]!,
        ),
        SizedBox(height: MediaQuery.of(context).size.width < 600 ? 12 : 16),
        _buildSocialButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PhoneSignUpPage()),
            );
          },
          icon: Icons.phone_android_outlined,
          label: 'Sign up with Phone',
          backgroundColor: const Color(0xFFF8F9FA),
          textColor: AppTheme.darkTextColor, // Using theme color
          borderColor: Colors.grey[300]!,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.width < 600 ? 48 : 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        icon: Icon(icon, color: textColor, size: 24),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Simple cloud painter
  Widget _cloud({required double x, required double y, required double scale}) {
    return Positioned(
      left: x,
      top: y,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: 0.85,
          child: Row(
            children: [
              _cloudCircle(34),
              const SizedBox(width: 6),
              _cloudCircle(26),
              const SizedBox(width: 6),
              _cloudCircle(20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cloudCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            color: AppTheme.lightTextColor, // Using theme color
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          children: <TextSpan>[
            const TextSpan(text: "Already have an account? "),
            TextSpan(
              text: 'Login',
              style: TextStyle(
                color: AppTheme.primaryColor, // Using theme color
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.pushNamed(context, '/login');
                },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrength() {
    final Color barColor = _passwordStrength <= 0.4
        ? Colors.redAccent
        : _passwordStrength <= 0.7
            ? Colors.orange
            : const Color(0xFF4CAF50);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 8,
            decoration: BoxDecoration(color: Colors.grey[200]),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _passwordStrength,
              child: Container(color: barColor),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _passwordStrengthLabel.isEmpty
              ? 'Use 8+ chars with a mix of letters, numbers, and symbols'
              : 'Password strength: $_passwordStrengthLabel',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTermsRow() {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (v) => setState(() => _acceptTerms = v ?? false),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: AppTheme.primaryColor, // Using theme color
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: AppTheme.primaryColor, // Using theme color
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
