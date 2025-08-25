import 'package:flutter/material.dart';

void main() => runApp(RestaurantTemplateApp());

class RestaurantTemplateApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TakeawayPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TakeawayPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Color accentColor = Color(0xFFEFF440); // Yellow-green accent

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Right accent circle + color background
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.65,
              color: accentColor,
              child: Align(
                alignment: Alignment.center,
                child: CircleAvatar(
                  radius: 160,
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage(
                      'assets/salad.jpg'), // Place food plate image in assets and update this path
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 38),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Logo and restaurant name
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: accentColor,
                          radius: 18,
                          child: Icon(Icons.bubble_chart, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Dhabi Restaurant',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 40),
                    // Nav Links
                    Text('Product', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 20),
                    Text('Receipe', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 20),
                    Text('About', style: TextStyle(fontSize: 13)),
                    Spacer(),
                    // Special offer button
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Special Offer',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(width: 10),
                    // Phone
                    Icon(Icons.phone, size: 18),
                    SizedBox(width: 5),
                    Text('+923351263561',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14)),
                    SizedBox(width: 16),
                    // User icons
                    Icon(Icons.person, size: 24),
                    SizedBox(width: 8),
                    Icon(Icons.shopping_bag, size: 24),
                  ],
                ),
                SizedBox(height: 55),
                // Content Left
                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Taglines
                      Text('All Delicious',
                          style: TextStyle(
                              fontSize: 44, fontWeight: FontWeight.normal)),
                      Row(
                        children: [
                          Text('Asian',
                              style: TextStyle(
                                  fontSize: 48, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('Eggs, Salad, fruits, pasta',
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 28),
                      // Find for more button
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: StadiumBorder(),
                          padding: EdgeInsets.symmetric(
                              horizontal: 30, vertical: 18),
                          elevation: 0,
                        ),
                        child: Text(
                          'Find for more',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

