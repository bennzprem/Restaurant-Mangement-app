import 'package:flutter/material.dart';
import 'widgets/header_widget.dart';
import 'widgets/about_section.dart';
import 'widgets/navbar_widget.dart';
import 'widgets/footer_widget.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                const NavbarWidget(),
                const SizedBox(height: 12),

                // Hero banner
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFFF7FBE1), Theme.of(context).scaffoldBackgroundColor],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: const [
                      Text(
                        'About ByteEat',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Crafting delightful dining experiences with fresh ingredients and thoughtful service.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.black87, height: 1.5),
                      ),
                    ],
                  ),
                ),

                // Reuse the AboutSection for detailed content
                //const AboutSection(),

                // Extra section with image and values
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 16),
                  color: Colors.white,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      return Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.network(
                                'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=1470&auto=format&fit=crop',
                                height: 420,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: isWide ? 48 : 0, height: isWide ? 0 : 32),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Our Values', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                SizedBox(height: 16),
                                Text('We believe great food starts with honest ingredients and ends with happy guests. From our kitchen to your table, we focus on taste, hygiene, and warmth in every interaction.',
                                  style: TextStyle(fontSize: 18, height: 1.6, color: Colors.black87),),
                                SizedBox(height: 24),
                                Text('Sourcing locally, cooking seasonally, and serving with care are the pillars that guide our team every day.',
                                  style: TextStyle(fontSize: 18, height: 1.6, color: Colors.black87),),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Footer
                const FooterWidget(),
              ],
            ),
          ),

          // Fixed header like on the homepage
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWidget(),
          ),
          // Navbar is part of scrollable content on About page, so it's not fixed
        ],
      ),
    );
  }
}


