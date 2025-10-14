import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:html' as html;
import 'package:provider/provider.dart';

import 'phone-login_page.dart';
import 'theme.dart';
import 'widgets/header_widget.dart';
import 'signup-bg.dart';

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

/*
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
          
          // Manually refresh the AuthProvider to update the UI
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.refreshAuthState();
          
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
*/
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
            Navigator.pop(context, true); // Return true to indicate successful login
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Define background colors based on theme - making animations more visible
    final Color waveColor = isDark
        ? Theme.of(context).primaryColor.withOpacity(0.8)
        : Theme.of(context).primaryColor.withOpacity(0.6);
    final Color backgroundColor =
        isDark ? const Color(0xFF0F0F10) : const Color(0xFFF8F9FA);

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: false),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 0),
        body: Stack(
          children: [
            // Add the AnimatedBackground widget here, behind the main content.
            AnimatedBackground(
              particleColor: waveColor,
              backgroundColor: backgroundColor,
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    // Desktop layout
                    return Column(
                      children: [
                        HeaderWidget(
                          active: HeaderActive.login,
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
                          active: HeaderActive.login,
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
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 550),
        child: Material(
          elevation: 32,
          shadowColor: Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          color: Colors.transparent, // Make Material widget transparent
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              // Use a more opaque color for better glassmorphism effect.
              color:
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.88),
              child: _buildNoScrollFormSection(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height < 700 ? 8 : 16),
          _buildCompactLogoSection(),
          SizedBox(height: MediaQuery.of(context).size.height < 700 ? 12 : 20),
          Expanded(child: _buildNoScrollFormSection()),
          SizedBox(height: MediaQuery.of(context).size.height < 700 ? 8 : 16),
        ],
      ),
    );
  }

  Widget _buildCompactLogoSection() {
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
                  width: MediaQuery.of(context).size.width < 600 ? 50 : 60,
                  height: MediaQuery.of(context).size.width < 600 ? 50 : 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/logo/logoDP.png',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(
                    height: MediaQuery.of(context).size.width < 600 ? 8 : 12),
                Text(
                  'ByteEat',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 600 ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(
                    height: MediaQuery.of(context).size.width < 600 ? 4 : 6),
                Text(
                  'Welcome back to your food journey',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color ??
                        Colors.grey,
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

  Widget _buildNoScrollFormSection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to continue to your account',
                style: TextStyle(
                  fontSize: isMobile ? 13 : 15,
                  color: isDark
                      ? Colors.grey[300]
                      : Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),

              // Form fields (no scroll, fixed layout)
              Expanded(
                child: Column(
                  children: [
                    // Form fields
                    Expanded(
                      flex: 3,
                      child: _buildNoScrollFormFields(),
                    ),
                    const SizedBox(height: 8),

                    // Remember me and forgot password
                    _buildRememberMeRow(),
                    const SizedBox(height: 12),

                    // Login button
                    _buildLoginButton(),
                    const SizedBox(height: 8),

                    // Divider
                    _buildDivider(),
                    const SizedBox(height: 8),

                    // Social buttons
                    Expanded(
                      flex: 2,
                      child: _buildCompactSocialButtons(),
                    ),

                    // Sign up link
                    _buildSignUpLink(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoScrollFormFields() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildCompactInputField(
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
          const SizedBox(height: 12),
          _buildCompactInputField(
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
        ],
      ),
    );
  }

  Widget _buildRememberMeRow() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (v) => setState(() => _rememberMe = v ?? false),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          activeColor: Theme.of(context).primaryColor,
          checkColor: Colors.white,
          fillColor:
              WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return Theme.of(context).primaryColor;
            }
            return isDark ? Colors.grey[600]! : Colors.grey[300]!;
          }),
        ),
        Text(
          'Remember me',
          style: TextStyle(
            color: isDark
                ? Colors.grey[300]
                : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () =>
              Navigator.pushNamed(context, '/forget_password_page'),
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactInputField({
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.grey[300]
                : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? Colors.white
                : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: Theme.of(context).primaryColor,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[400],
              fontWeight: FontWeight.w400,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: Theme.of(context).primaryColor,
              size: 18,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 18,
                    ),
                    onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible),
                  )
                : null,
            filled: true,
            fillColor: isDark ? const Color(0xFF151515) : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[300]!, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[300]!, width: 2),
            ),
            errorStyle: TextStyle(color: Colors.red[400], fontSize: 11),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return SizedBox(
      width: double.infinity,
      height: isMobile ? 36 : 40,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
          shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Sign In',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
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

  Widget _buildCompactSocialButtons() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        _buildCompactSocialButton(
          onPressed: _isLoading ? null : _signInWithGoogle,
          icon: Icons.g_mobiledata_outlined,
          label: 'Sign in with Google',
          backgroundColor: isDark ? Colors.grey[800]! : Colors.white,
          textColor: isDark
              ? Colors.white
              : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          borderColor: isDark ? Colors.grey[600]! : Colors.grey[300]!,
        ),
        const SizedBox(height: 6),
        _buildCompactSocialButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PhoneLoginPage()),
            );
          },
          icon: Icons.phone_android_outlined,
          label: 'Login with Phone',
          backgroundColor: isDark ? Colors.grey[800]! : Colors.grey[50]!,
          textColor: isDark
              ? Colors.white
              : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          borderColor: isDark ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ],
    );
  }

  Widget _buildCompactSocialButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
  }) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return SizedBox(
      width: double.infinity,
      height: isMobile ? 32 : 36,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        icon: Icon(icon, color: textColor, size: isMobile ? 18 : 20),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: isMobile ? 13 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: isMobile ? 13 : 14,
            fontWeight: FontWeight.w500,
          ),
          children: <TextSpan>[
            const TextSpan(text: "Don't have an account? "),
            TextSpan(
              text: 'Sign Up',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
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
