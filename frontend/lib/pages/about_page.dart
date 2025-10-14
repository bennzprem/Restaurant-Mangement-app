import 'package:flutter/material.dart';
import '../widgets/header_widget.dart';
import '../widgets/footer_widget.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  int _currentSlide = 0;
  final PageController _pageController = PageController();

  final List<Map<String, String>> _slides = [
    {
      'title': 'Welcome to',
      'highlight': 'ByteEat Restaurant',
      'subtitle': 'Experience Excellence',
    },
    {
      'title': 'Culinary',
      'highlight': 'Mastery & Innovation',
      'subtitle': 'Crafting Memories',
    },
    {
      'title': 'Fresh',
      'highlight': 'Ingredients & Passion',
      'subtitle': 'Every Bite Counts',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeroSection(),
                _buildServicesSection(),
                const FooterWidget(),
              ],
            ),
          ),
          // Fixed header
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
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      margin: const EdgeInsets.only(top: 80), // Account for fixed header
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?ixlib=rb-4.0.3&auto=format&fit=crop&w=2070&q=80',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          children: [
            // Navigation arrows
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavArrow(Icons.chevron_left, () {
                    if (_currentSlide > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }),
                  _buildNavArrow(Icons.chevron_right, () {
                    if (_currentSlide < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }),
                ],
              ),
            ),

            // Main content
            Expanded(
              flex: 3,
              child: Center(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentSlide = index;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return _buildSlideContent(slide);
                  },
                ),
              ),
            ),

            // Pagination dots
            _buildPaginationDots(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNavArrow(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlideContent(Map<String, String> slide) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          slide['title']!,
          style: const TextStyle(
            fontSize: 32,
            color: Colors.white,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 48,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
            children: [
              TextSpan(text: slide['highlight']!.split(' ').first),
              const TextSpan(text: ' '),
              TextSpan(
                text: slide['highlight']!.split(' ').skip(1).join(' '),
                style: const TextStyle(color: Color(0xFFFFD700)), // Gold color
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          slide['subtitle']!,
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white70,
            fontWeight: FontWeight.w400,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _slides.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentSlide == index ? 12 : 8,
          height: _currentSlide == index ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentSlide == index
                ? const Color(0xFFFFD700)
                : Colors.white.withOpacity(0.5),
            border: _currentSlide == index
                ? null
                : Border.all(color: Colors.white, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      color: Colors.white,
      child: Column(
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD700), width: 2),
            ),
            child: const Text(
              '[WHAT WE OFFER]',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Description
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'At ByteEat Restaurant, we pride ourselves on delivering exceptional culinary experiences through our comprehensive range of services. From farm-fresh ingredients to innovative cooking techniques, we ensure every dish tells a story of passion and excellence. Our commitment to quality extends beyond the kitchen, offering a complete dining ecosystem that caters to every need and preference.',
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
                height: 1.6,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Additional content
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Whether you\'re looking for a romantic dinner, a quick takeaway, or a special celebration, we have the perfect solution for you. Our team of expert chefs, friendly staff, and cutting-edge technology work together to create memorable experiences that keep you coming back for more.',
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black45,
                height: 1.5,
                letterSpacing: 0.3,
              ),
            ),
          ),

          const SizedBox(height: 60),

          // Services grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1400
                  ? 3
                  : constraints.maxWidth > 900
                      ? 2
                      : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 0.85,
                ),
                itemCount: _services.length,
                itemBuilder: (context, index) {
                  return _buildServiceCard(_services[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700),
              shape: BoxShape.circle,
            ),
            child: Icon(
              service['icon'],
              size: 40,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            service['title'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            service['description'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.5,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> _services = [
    {
      'icon': Icons.restaurant,
      'title': 'FINE DINING',
      'description':
          'Experience our exquisite fine dining menu featuring carefully crafted dishes made with premium ingredients and innovative culinary techniques.',
    },
    {
      'icon': Icons.local_dining,
      'title': 'TAKEAWAY SERVICE',
      'description':
          'Enjoy our delicious meals in the comfort of your home with our efficient takeaway service, ensuring fresh and hot food delivery.',
    },
    {
      'icon': Icons.event_seat,
      'title': 'TABLE RESERVATION',
      'description':
          'Book your perfect dining experience with our easy table reservation system, ensuring you have the best seat in the house.',
    },
    {
      'icon': Icons.smart_toy,
      'title': 'AI ASSISTANT',
      'description':
          'Meet ByteBot, our friendly AI dining assistant that helps you discover new flavors and provides personalized recommendations.',
    },
    {
      'icon': Icons.celebration,
      'title': 'EVENT CATERING',
      'description':
          'Make your special occasions memorable with our professional catering services for weddings, corporate events, and celebrations.',
    },
    {
      'icon': Icons.subscriptions,
      'title': 'MEAL SUBSCRIPTIONS',
      'description':
          'Subscribe to our meal plans for regular, healthy, and delicious meals delivered to your doorstep with flexible options.',
    },
  ];
}
