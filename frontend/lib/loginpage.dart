import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:html' as html;

import 'phone-login_page.dart';
import 'theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  // Animation Controllers
  late AnimationController _formAnimationController;
  late AnimationController _logoAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;
  late AnimationController _visualAnimationController;
  late Animation<double> _sunRiseAnimation;
  late Animation<double> _cloudDriftAnimation;

  @override
  void initState() {
    super.initState();

    // Form entrance animation
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Logo animation
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
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

    // Start animations
    _logoAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _formAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _formAnimationController.dispose();
    _logoAnimationController.dispose();
    _visualAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Core Authentication Logic (Unchanged)
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final response = await http.post(
          Uri.parse('http://localhost:5000/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text.trim(),
            'password': _passwordController.text.trim(),
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          await Supabase.instance.client.auth.setSession(data['refresh_token']);
          if (mounted) {
            // After login, route user to their role dashboard
            final client = Supabase.instance.client;
            final uid = client.auth.currentUser!.id;
            try {
              final profile = await client
                  .from('users')
                  .select('role')
                  .eq('id', uid)
                  .single();
              final role = profile['role'] ?? 'user';
              String route = '/';
              switch (role) {
                case 'admin':
                  route = '/admin_dashboard';
                  break;
                case 'manager':
                  route = '/manager_dashboard';
                  break;
                case 'kitchen':
                  route = '/kitchen_dashboard';
                  break;
                case 'delivery':
                  route = '/delivery_dashboard';
                  break;
                case 'employee':
                  route = '/employee_dashboard';
                  break;
                default:
                  route = '/';
              }
              Navigator.pushReplacementNamed(context, route);
            } catch (_) {
              Navigator.pushReplacementNamed(context, '/');
            }
          }
        } else {
          final errorData = json.decode(response.body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorData['error'] ?? 'Invalid Credentials'),
                backgroundColor: Colors.red.withOpacity(0.8),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
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
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: false),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF212529)),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF8F9FA), // Light white
                Color(0xFFE9ECEF), // Very light gray
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  // Desktop layout
                  return _buildDesktopLayout();
                } else {
                  // Mobile layout
                  return _buildMobileLayout();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
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
                    color: const Color(0xFFF7F8F9),
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
                    color: AppTheme.primaryColor, // Using mint lime theme color
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.restaurant,
                    size: MediaQuery.of(context).size.width < 600 ? 30 : 40,
                    color: Colors.white,
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
                  'Welcome back to your food journey',
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
            child: _buildLoginFormCard(),
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
            AppTheme.primaryColor,
            AppTheme.accentColor
          ], // Using mint lime theme colors
        ),
      ),
      child: Stack(
        children: [
          // Support text top-right
          Positioned(
            top: 24,
            right: 24,
            child: Row(
              children: const [
                Icon(Icons.headset_mic, color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Text('Support',
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
                        const Text('Reach food goals faster',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20)),
                        const SizedBox(height: 8),
                        Text(
                          'Order breakfast with no hassle. Save time and enjoy mouthwatering meals.',
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
                    'Introducing new features',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Discover smart ordering and faster checkouts to start your morning right.",
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

  Widget _buildLoginFormCard() {
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
        color: Colors.white,
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
              'Welcome Back',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF212529),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: gapSmall),
            Text(
              'Sign in to continue to your account',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: gapLarge),
            _buildFormFields(),
            SizedBox(height: gapMed),
            _buildLoginButton(),
            SizedBox(height: gapMed),
            _buildDivider(),
            SizedBox(height: gapMed),
            _buildSocialButtons(),
            SizedBox(height: compact || isMobile ? 16 : 32),
            _buildSignUpLink(),
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
            controller: _emailController,
            labelText: 'Email Address',
            hintText: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty || !value.contains('@')) {
                return 'Please enter a valid email address';
              }
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
              if (value == null || value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          SizedBox(height: MediaQuery.of(context).size.width < 600 ? 8 : 12),
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              const Text('Remember me',
                  style: TextStyle(
                      color: Color(0xFF495057), fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/forget_password_page'),
                child: const Text('Forgot Password?',
                    style: TextStyle(color: Color(0xFF495057))),
              ),
            ],
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
          obscureText: isPassword && !_isPasswordVisible,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF212529),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: Colors.grey[500],
              size: 22,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey[500],
                      size: 22,
                    ),
                    onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
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
                color: AppTheme.primaryColor, // Using mint lime theme color
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

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.width < 600 ? 48 : 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
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
                'Sign In',
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
          label: 'Sign in with Google',
          backgroundColor: Colors.white,
          textColor: const Color(0xFF212529),
          borderColor: Colors.grey[300]!,
        ),
        SizedBox(height: MediaQuery.of(context).size.width < 600 ? 12 : 16),
        _buildSocialButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PhoneLoginPage()),
            );
          },
          icon: Icons.phone_android_outlined,
          label: 'Login with Phone',
          backgroundColor: const Color(0xFFF8F9FA),
          textColor: const Color(0xFF212529),
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

  Widget _buildSignUpLink() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          children: <TextSpan>[
            const TextSpan(text: "Don't have an account? "),
            TextSpan(
              text: 'Sign Up',
              style: TextStyle(
                color: AppTheme.primaryColor, // Using mint lime theme color
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.pushNamed(context, '/signup');
                },
            ),
          ],
        ),
      ),
    );
  }
}
