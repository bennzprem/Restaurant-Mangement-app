import 'package:flutter/material.dart';

//updated
class NewsletterSection extends StatelessWidget {
  const NewsletterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://api.builder.io/api/v1/image/assets/TEMP/ad33659c33381eac40061641b81f19d65a13ad9f',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Get our promo code to subscribe our page and channel of food',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 64),

              // Subscription Form
              Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isDesktop = constraints.maxWidth > 600;

                    if (isDesktop) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Type your email and get',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 18,
                                ),
                              ),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDAE952),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                                vertical: 20,
                              ),
                            ),
                            child: const Text(
                              'Subscribe',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Type your email and get',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 18,
                              ),
                            ),
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDAE952),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                              ),
                              child: const Text(
                                'Subscribe',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 48),

              // Decorative dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
