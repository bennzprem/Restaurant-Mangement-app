import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../theme_provider.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22), // glassmorphism
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Container(
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode 
                    ? Colors.grey.shade900.withOpacity(0.68)
                    : Colors.white.withOpacity(0.68),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.isDarkMode 
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  )
                ],
                border: Border(
                  bottom: BorderSide(
                    color: themeProvider.isDarkMode 
                        ? Colors.grey.shade700.withOpacity(0.3)
                        : Colors.white.withOpacity(0.13),
                    width: 1.0,
                  ),
                ),
              ),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          child: Row(
            children: [
              // Logo
              Icon(Icons.restaurant_menu_rounded,
                  color: Color(0xFFDAE952), size: 28),
              const SizedBox(width: 14),
              Text(
                'Byte Eat',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.85,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              Spacer(),
              // Theme Toggle Button
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode 
                          ? Colors.grey.shade800 
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFDAE952),
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        themeProvider.toggleTheme();
                      },
                      icon: Icon(
                        themeProvider.isDarkMode 
                            ? Icons.light_mode 
                            : Icons.dark_mode,
                        color: const Color(0xFFDAE952),
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  );
                },
              ),
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
        );
          },
        ),
      ),
    );
  }
}
