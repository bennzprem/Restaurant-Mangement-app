import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final selectedCategory = args != null ? args['category'] as String? : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedCategory ?? 'Menu'),
        backgroundColor: const Color(0xFFDAE952),
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Text(
          selectedCategory != null
              ? 'Items for $selectedCategory'
              : 'All Menu Items',
          style: const TextStyle(fontSize: 22),
        ),
        // Replace above with your menu lists filtered for selectedCategory
      ),
    );
  }
}
