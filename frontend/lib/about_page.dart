import 'package:flutter/material.dart';
import 'widgets/header_widget.dart';
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
                const SizedBox(height: 80),

                // Our Story
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
                  child: Container
                      (
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Our Story',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                )),
                        const SizedBox(height: 12),
                        Text(
                          'ByteEat started with a simple idea: making dining smarter, quicker, and more personal. We combine great taste with thoughtful technology — from ByteBot, your friendly AI dining assistant, to our digital-first ordering experience.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),

                // Mission & Vision
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Our Mission',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      )),
                              const SizedBox(height: 8),
                              Text(
                                'To bring technology and taste together for a seamless dining experience — fast, intuitive, and delightful every time.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Our Vision',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      )),
                              const SizedBox(height: 8),
                              Text(
                                'A world where your meal knows you — preferences, pace, and mood — and your restaurant feels like a personal kitchen.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Team Introduction
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Meet the Team',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                )),
                        const SizedBox(height: 16),
                        LayoutBuilder(builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 800;
                          return Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            children: [
                              _TeamCard(
                                name: 'Aarav Gupta',
                                role: 'Founder & CEO',
                                imageUrl:
                                    'https://images.unsplash.com/photo-1502685104226-ee32379fefbe?w=400',
                              ),
                              _TeamCard(
                                name: 'Chef Nisha',
                                role: 'Head Chef',
                                imageUrl:
                                    'https://images.unsplash.com/photo-1521577352947-9bb58764b69a?w=400',
                              ),
                              _TeamCard(
                                name: 'Rohit Mehta',
                                role: 'Tech Lead (ByteBot)',
                                imageUrl:
                                    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
                              ),
                              _TeamCard(
                                name: 'Priya Sharma',
                                role: 'Guest Experience',
                                imageUrl:
                                    'https://images.unsplash.com/photo-1547425260-76bcadfb4f2c?w=400',
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Ambience / Experience gallery
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ambience & Experience',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                )),
                        const SizedBox(height: 16),
                        LayoutBuilder(builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 900
                              ? 4
                              : constraints.maxWidth > 650
                                  ? 3
                                  : 2;
                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: const [
                              _GalleryTile('https://images.unsplash.com/photo-1541542684-4a00436f9f6b?w=800'),
                              _GalleryTile('https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800'),
                              _GalleryTile('https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800'),
                              _GalleryTile('https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800'),
                              _GalleryTile('https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=800'),
                              _GalleryTile('https://images.unsplash.com/photo-1544148103-0773bf10d330?w=800'),
                            ],
                          );
                        })
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Sustainability / Local sourcing
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sustainability & Local Sourcing',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                )),
                        const SizedBox(height: 12),
                        Text(
                          'We believe in fresh, local ingredients and responsible sourcing. Wherever possible, we partner with neighborhood farms and suppliers to reduce miles and increase flavor.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),

                // Reuse the AboutSection for detailed content
                //const AboutSection(),

                // Extra section with image and values
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 16),
                  color: Theme.of(context).cardColor,
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
                              children: [
                                Text('Our Values',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 16),
                                Text(
                                  'We believe great food starts with honest ingredients and ends with happy guests. From our kitchen to your table, we focus on taste, hygiene, and warmth in every interaction.',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Sourcing locally, cooking seasonally, and serving with care are the pillars that guide our team every day.',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                                ),
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWidget(
              active: HeaderActive.about,
              showBack: true,
              onBack: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              },
            ),
          ),
          // Navbar is part of scrollable content on About page, so it's not fixed
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final String name;
  final String role;
  final String imageUrl;

  const _TeamCard({required this.name, required this.role, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(imageUrl, width: 220, height: 160, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          Text(name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(role, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final String url;
  const _GalleryTile(this.url);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(url, fit: BoxFit.cover),
    );
  }
}


