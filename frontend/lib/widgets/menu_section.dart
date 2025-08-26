import 'package:flutter/material.dart';

class MenuSection extends StatelessWidget {
  const MenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      MenuItem(
        name: 'Special Salad',
        price: '\$12',
        image: 'https://api.builder.io/api/v1/image/assets/TEMP/ad33659c33381eac40061641b81f19d65a13ad9f',
        description: 'Food is any substance consumed by an organism for nutritional support.',
      ),
      MenuItem(
        name: 'Russian Salad',
        price: '\$12',
        image: 'https://api.builder.io/api/v1/image/assets/TEMP/ad33659c33381eac40061641b81f19d65a13ad9f',
        description: 'Food is any substance consumed by an organism for nutritional support.',
      ),
      MenuItem(
        name: 'Asian Salad',
        price: '\$12',
        image: 'https://api.builder.io/api/v1/image/assets/TEMP/ad33659c33381eac40061641b81f19d65a13ad9f',
        description: 'Food is any substance consumed by an organism for nutritional support.',
      ),
      MenuItem(
        name: 'American Salad',
        price: '\$12',
        image: 'https://api.builder.io/api/v1/image/assets/TEMP/ad33659c33381eac40061641b81f19d65a13ad9f',
        description: 'Food is any substance consumed by an organism for nutritional support.',
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
                  ),
                  children: [
                    TextSpan(
                      text: 'Our Delicious and Special Salad ',
                      style: TextStyle(fontWeight: FontWeight.w400),
                    ),
                    TextSpan(
                      text: 'Asian',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDAE952),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Food is any substance consumed by an organism for nutritional support.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 64),
          
          // Menu Grid
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 1200 ? 4 : 
                                 constraints.maxWidth > 800 ? 2 : 1;
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 32,
                  mainAxisSpacing: 32,
                  childAspectRatio: 0.6,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  return MenuItemCard(item: menuItems[index]);
                },
              );
            },
          ),
          
          const SizedBox(height: 64),
          
          // Star ratings
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => 
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MenuItem {
  final String name;
  final String price;
  final String image;
  final String description;

  MenuItem({
    required this.name,
    required this.price,
    required this.image,
    required this.description,
  });
}

class MenuItemCard extends StatelessWidget {
  final MenuItem item;

  const MenuItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Card
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(48),
              topRight: Radius.circular(48),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Price tag
              Positioned(
                top: 24,
                left: 24,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      item.price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Image
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 256,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(48),
                      topRight: Radius.circular(48),
                    ),
                    child: Image.network(
                      item.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              
              // Title
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Description
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            item.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
