import 'package:flutter/material.dart';

//updated
class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationLinks = ['Menu', 'Products', 'About Us', 'Dish', 'Asian'];
    final genreLinks = ['Salad', 'Spicy', 'Bowl', 'Kitchen', 'Home'];
    final socialLinks = ['F', 'I', 'T', 'Y'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 16),
      color: Colors.white,
      child: Column(
        children: [
          // Main footer content
          LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 1024;

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCompanyInfo()),
                    Expanded(
                        child: _buildNavigationLinks(
                            navigationLinks, 'Navigation')),
                    Expanded(
                        child: _buildNavigationLinks(genreLinks, 'Genres')),
                    Expanded(child: _buildSocialLinks(socialLinks)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildCompanyInfo(),
                    const SizedBox(height: 48),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: _buildNavigationLinks(
                                navigationLinks, 'Navigation')),
                        Expanded(
                            child: _buildNavigationLinks(genreLinks, 'Genres')),
                      ],
                    ),
                    const SizedBox(height: 48),
                    _buildSocialLinks(socialLinks),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 64),

          // Bottom section
          Container(
            padding: const EdgeInsets.only(top: 32),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isDesktop = constraints.maxWidth > 768;

                if (isDesktop) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLogo(),
                      const Text(
                        '© 2024 ByteEat. All rights reserved.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 16),
                      const Text(
                        '© 2024 ByteEat. All rights reserved.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Managing restaurant menus and other information including location and opening hours. Managing the preparation of orders at a restaurant kitchen.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationLinks(List<String> links, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 24),
        Column(
          children: links
              .map(
                (link) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    link,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSocialLinks(List<String> socialLinks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Follow Us',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: socialLinks
              .map(
                (social) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDAE952),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      social,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'ByteEat',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
