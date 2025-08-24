import 'package:flutter/material.dart';
import '../widgets/about_section.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: const Color(0xFFDAE952),
        foregroundColor: Colors.black,
      ),
      body: const SingleChildScrollView(
        child: AboutSection(),
      ),
    );
  }
}
