import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'otp_verification_page.dart'; // We will create this next

class PhoneSignUpPage extends StatefulWidget {
  const PhoneSignUpPage({super.key});

  @override
  State<PhoneSignUpPage> createState() => _PhoneSignUpPageState();
}

class _PhoneSignUpPageState extends State<PhoneSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendVerificationCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // IMPORTANT: Replace with your actual backend URL
      final response = await http.post(
        Uri.parse('http://localhost:5000/verify/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': _phoneController.text.trim()}),
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        if (response.statusCode == 200) {
          // Navigate to the OTP verification page on success
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OtpVerificationPage(
                phoneNumber: _phoneController.text.trim(),
              ),
            ),
          );
        } else {
          // Show an error message if something went wrong
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Failed to send code.'),
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
            content: Text('An error occurred: $e'),
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
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // --- UI BUILD METHODS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the same light beige background as the main sign-up page
      backgroundColor: const Color(0xFFF8F9FA),
      // Add a simple AppBar for navigation
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _buildPhoneSignUpFormCard(),
        ),
      ),
    );
  }

  // This is the main card widget, styled like the signup page
  Widget _buildPhoneSignUpFormCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sign Up with Phone',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We will send you a verification code.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),
          _buildFormFields(),
          const SizedBox(height: 24),
          _buildSendCodeButton(),
        ],
      ),
    );
  }

  // The form with the styled phone number field
  Widget _buildFormFields() {
    return Form(
      key: _formKey,
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        // Use the modern input decoration from the signup page
        decoration: _modernInputDecoration(
          labelText: 'Phone Number',
          hintText: '+919876543210',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your phone number';
          }
          if (!value.startsWith('+')) {
            return 'Please include the country code (e.g., +91)';
          }
          return null;
        },
      ),
    );
  }

  // Helper method for styling text fields, copied from the signup page
  InputDecoration _modernInputDecoration({
    required String labelText,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: TextStyle(color: Colors.grey[700]),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(
          color: Color(0xFFB8C96C), // Accent color
          width: 2,
        ),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 1.2),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  // The main action button, styled like the signup page
  Widget _buildSendCodeButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _sendVerificationCode,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4E49C), // Lime green accent
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
          shadowColor: const Color(0xFFD4E49C).withOpacity(0.5),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                ),
              )
            : const Text(
                'Send Code',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}