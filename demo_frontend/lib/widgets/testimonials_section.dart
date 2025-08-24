import 'package:flutter/material.dart';

class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final testimonials = [
      Testimonial(
        name: 'Abdullah Iqbal',
        review: 'A customer is a person or business that buys goods or services from another business. Customers are crucial because they generate revenue. Without them, businesses would go out of business.',
        image: 'https://api.builder.io/api/v1/image/assets/TEMP/ad33659c33381eac40061641b81f19d65a13ad9f',
      ),
      Testimonial(
        name: 'Henry John',
        review: 'A customer is a person or business that buys goods or services from another business. Customers are crucial because they generate revenue. Without them, businesses would go out of business.',
        image: 'https://api.builder.io/api/v1/image/assets/TEMP/ad33659c33381eac40061641b81f19d65a13ad9f',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 16),
      color: const Color(0xFFDAE952).withOpacity(0.2),
      child: Column(
        children: [
          // Header
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
                      text: 'Dhabi',
                      style: TextStyle(color: Color(0xFFDAE952)),
                    ),
                    TextSpan(text: ' Restaurant Happy Customers'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'A customer is a person or business that buys goods or services from another business. Customers are crucial because they generate revenue. Without them, businesses would go out of business.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 64),
          
          // Testimonials Grid
          LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 768;
              
              if (isDesktop) {
                return Row(
                  children: testimonials.map((testimonial) => 
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: TestimonialCard(testimonial: testimonial),
                      ),
                    ),
                  ).toList(),
                );
              } else {
                return Column(
                  children: testimonials.map((testimonial) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 48),
                      child: TestimonialCard(testimonial: testimonial),
                    ),
                  ).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class Testimonial {
  final String name;
  final String review;
  final String image;

  Testimonial({
    required this.name,
    required this.review,
    required this.image,
  });
}

class TestimonialCard extends StatelessWidget {
  final Testimonial testimonial;

  const TestimonialCard({super.key, required this.testimonial});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(64),
          topRight: Radius.circular(64),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Customer Image
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(48),
                child: Image.network(
                  testimonial.image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Review
            Expanded(
              child: Text(
                testimonial.review,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  height: 1.5,
                  fontSize: 16,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Customer Name
            Text(
              testimonial.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => 
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}