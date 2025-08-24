import 'package:flutter/material.dart';
import 'dart:ui';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 80, // or whatever looks good
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
              24), // Rounded nav bar, tweak if not desired
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18), // semi-transparent white
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2), // optional outline
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Byte Eat',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    // Navigation (Desktop)
                    // Navigation (Desktop)
                    if (MediaQuery.of(context).size.width > 768)
                      Row(
                        children: [
                          _buildNavButton(context, 'Home', '/'),
                          _buildNavButton(context, 'Menu', '/menu'),
                          _buildNavButton(context, 'About', '/about'),
                          _buildNavButton(context, 'Contact', '/contact'),
                        ],
                      ),

                    // Sign Up (Desktop)
                    if (MediaQuery.of(context).size.width > 1024)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, '/signup'); // Adjust route as needed
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),

                    // Mobile Menu
                    if (MediaQuery.of(context).size.width <= 768)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.menu, color: Colors.black),
                        onSelected: (value) {
                          Navigator.pushNamed(context, value);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: '/', child: Text('Home')),
                          const PopupMenuItem(
                              value: '/menu', child: Text('Menu')),
                          const PopupMenuItem(
                              value: '/about', child: Text('About')),
                          const PopupMenuItem(
                              value: '/contact', child: Text('Contact')),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildNavItem(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, String text, String routeName) {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, routeName);
      },
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }
}
