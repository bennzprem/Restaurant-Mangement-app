import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:restaurant_app/widgets/expanding_search_bar.dart';

//updated
class HeaderWidget extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<bool> onSearchExpansionChanged;
  final bool isSearchExpanded;

  const HeaderWidget({
    super.key,
    required this.searchController,
    required this.onSearchExpansionChanged,
    required this.isSearchExpanded,
  });

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
              Icon(Icons.restaurant_menu_rounded,
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
              Spacer(),
              ExpandingSearchBar(
                controller: searchController,
                onExpansionChanged: onSearchExpansionChanged,
              ),
              const SizedBox(width: 14),
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
