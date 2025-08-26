import 'package:flutter/material.dart';

//updated
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 16),
      color: Colors.white,
      child: Column(
        children: [
          // Main about content
          LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 1024;

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildContent(context)),
                    const SizedBox(width: 64),
                    Expanded(child: _buildImage()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildContent(context),
                    const SizedBox(height: 48),
                    _buildImage(),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 80),

          // Chef section
          Column(
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Food, substance consisting essentially of protein, carbohydrate, fat, and other nutrients used in the body of an organism to sustain growth and vital processes and to furnish energy. The absorption and utilization of food by the body is fundamental to nutrition and is facilitated by digestion.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
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

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 40,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(text: 'Welcome to our '),
              TextSpan(
                text: 'ByteEat',
                style: TextStyle(color: Color(0xFFDAE952)),
              ),
              TextSpan(text: ' Restaurant'),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Food, substance consisting essentially of protein, carbohydrate, fat, and other nutrients used in the body of an organism to sustain growth and vital processes and to furnish energy. The absorption and utilization of food by the body is fundamental to nutrition and is facilitated by digestion.',
          style: TextStyle(
            fontSize: 20,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDAE952),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 20,
            ),
          ),
          child: const Text(
            'Find More',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    return Stack(
      children: [
        Container(
          height: 600,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              'https://api.builder.io/api/v1/image/assets/TEMP/ad33659c33381eac40061641b81f19d65a13ad9f',
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
