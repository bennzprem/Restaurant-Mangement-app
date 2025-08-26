import 'package:flutter/material.dart';
import 'dart:ui';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22), // glassmorphism
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.68),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              )
            ],
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.13),
                width: 1.0,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          child: Row(
            children: [
              // Logo
              const Icon(Icons.restaurant_menu_rounded,
                  color: Color(0xFFDAE952), size: 28),
              const SizedBox(width: 14),
              const Text(
                'Byte Eat',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.85,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Container(
                width: 300, // Adjust width as needed
                height: 48, // Adjust height to match button
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
              const SizedBox(
                  width: 14), // Space between search bar and signup button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDAE952),
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
