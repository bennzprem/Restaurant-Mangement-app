import 'package:flutter/material.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 1024;
    final bool isTablet = width >= 700 && width < 1024;
    final double verticalPad = isDesktop ? 80 : (isTablet ? 64 : 40);
    final double horizontalPad = isDesktop ? 32 : (isTablet ? 24 : 16);

    return Container(
      padding:
          EdgeInsets.symmetric(vertical: verticalPad, horizontal: horizontalPad),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Main about content
          LayoutBuilder(builder: (context, constraints) {
            final double maxW = constraints.maxWidth;
            final bool wide = maxW >= 1024;
            final double gap = wide ? 64 : 32;
            final double imageHeight = wide
                ? 520
                : (isTablet
                    ? 380
                    : 240); // tune image height for smaller screens

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _buildContent(context, isDesktop: true)),
                  SizedBox(width: gap),
                  Expanded(child: _buildImage(context, height: imageHeight)),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildContent(context, isDesktop: false),
                  SizedBox(height: gap),
                  _buildImage(context, height: imageHeight),
                ],
              );
            }
          }),

          const SizedBox(height: 80),

          // Chef section
          Column(
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: isDesktop ? 40 : (isTablet ? 34 : 26),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  children: const [
                    TextSpan(text: 'Our '),
                    TextSpan(
                      text: 'ByteEat',
                      style: TextStyle(color: Color(0xFFDAE952)),
                    ),
                    TextSpan(text: ' Restaurant Expert Chef'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Food, substance consisting essentially of protein, carbohydrate, fat, and other nutrients used in the body of an organism to sustain growth and vital processes and to furnish energy. The absorption and utilization of food by the body is fundamental to nutrition and is facilitated by digestion.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isDesktop ? 20 : (isTablet ? 18 : 15),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, {required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: isDesktop ? 40 : 28,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              fontWeight: FontWeight.bold,
            ),
            children: const [
              TextSpan(text: 'Welcome to our '),
              TextSpan(
                text: 'ByteEat',
                style: TextStyle(color: Color(0xFFDAE952)),
              ),
              TextSpan(text: ' Restaurant'),
            ],
          ),
        ),
        SizedBox(height: isDesktop ? 32 : 20),
        Text(
          'Food, substance consisting essentially of protein, carbohydrate, fat, and other nutrients used in the body of an organism to sustain growth and vital processes and to furnish energy. The absorption and utilization of food by the body is fundamental to nutrition and is facilitated by digestion.',
          style: TextStyle(
            fontSize: isDesktop ? 20 : 16,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black87,
            height: 1.5,
          ),
        ),
        SizedBox(height: isDesktop ? 32 : 20),
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/about');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDAE952),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
          ),
          child: const Text(
            'Find More',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(BuildContext context, {required double height}) {
    return Stack(
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black)
                    .withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              'https://images.pexels.com/photos/1581384/pexels-photo-1581384.jpeg',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ),

        // Decorative elements
        Positioned(
          top: -16,
          left: -16,
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 32,
              height: 32,
              color: const Color(0xFFDAE952),
            ),
          ),
        ),
        Positioned(
          top: 64,
          right: -32,
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 24,
              height: 24,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
