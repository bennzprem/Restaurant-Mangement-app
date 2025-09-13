import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:restaurant_app/theme.dart';

// The models are now updated with `fromJson` factories to parse the live data from your backend.
class Dish {
  final String name;
  final String description;
  final String imageUrl;
  final double? price; // Price can be null if not provided by the API
  final List<String> tags;

  Dish({
    required this.name,
    required this.description,
    required this.imageUrl,
    this.price,
    required this.tags,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    final tagsList = json['tags'];
    return Dish(
      name: json['name'] ?? 'Unnamed Dish',
      description: json['description'] ?? 'No description available.',
      imageUrl: json['image_url'] ?? 'https://placehold.co/600x400/EEE/31343C?text=Image+Not+Found',
      price: (json['price'] as num?)?.toDouble(),
      tags: tagsList is List ? List<String>.from(tagsList) : [],
    );
  }
}

class AiRecommendation {
  final Dish dish;
  final String reason;

  AiRecommendation({required this.dish, required this.reason});

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    return AiRecommendation(
      dish: Dish.fromJson(json['dish']),
      reason: json['reason'] ?? "Our chef highly recommends this delightful dish for you today!",
    );
  }
}

// This new service class handles the live network call to your Python backend.
class ByteBotService {
  // IMPORTANT: Replace with your actual backend IP address or deployed URL.
  // For local development, this is typically correct.
  final String _baseUrl = "http://127.0.0.1:5000"; 

  Future<AiRecommendation> getRecommendation() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/bytebot-recommendation'));

      if (response.statusCode == 200) {
        return AiRecommendation.fromJson(json.decode(response.body));
      } else {
        final errorBody = json.decode(response.body);
        throw Exception('Failed to load recommendation: ${errorBody['error']}');
      }
    } catch (e) {
      throw Exception('Could not connect to ByteBot. Please try again later.');
    }
  }
}

class AiCulinaryCuratorSection extends StatefulWidget {
  const AiCulinaryCuratorSection({super.key});

  @override
  _AiCulinaryCuratorSectionState createState() => _AiCulinaryCuratorSectionState();
}

class _AiCulinaryCuratorSectionState extends State<AiCulinaryCuratorSection> {
  // We use a Future to handle the state of the network request.
  late Future<AiRecommendation> _recommendationFuture;

  @override
  void initState() {
    super.initState();
    // When the widget is created, we immediately call the service to get the AI recommendation.
    _recommendationFuture = ByteBotService().getRecommendation();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF14181C) : const Color(0xFFF8FAFF);
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1D2A39);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      color: bgColor,
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: titleColor),
              children: [
                const TextSpan(text: "Today's "),
                TextSpan(
                  text: "ByteBot Recommendation",
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          
          // The FutureBuilder widget is key. It rebuilds the UI based on the Future's state.
          FutureBuilder<AiRecommendation>(
            future: _recommendationFuture,
            builder: (context, snapshot) {
              // STATE 1: While waiting for the AI's response, show a loading spinner.
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 350,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              // STATE 2: If there was an error, display an informative message.
              if (snapshot.hasError) {
                return SizedBox(
                  height: 350,
                  child: Center(
                    child: Text(
                      '${snapshot.error}',
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              // STATE 3: If the data has arrived successfully, build the UI.
              if (snapshot.hasData) {
                final recommendation = snapshot.data!;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return _buildDesktopLayout(recommendation);
                    } else {
                      return _buildMobileLayout(recommendation);
                    }
                  },
                );
              }
              // Fallback case (should ideally not be reached)
              return const Center(child: Text("Something went wrong loading the recommendation."));
            },
          ),
        ],
      ),
    );
  }
  
  // The UI build methods are now guaranteed to receive valid data from the FutureBuilder.
  Widget _buildDesktopLayout(AiRecommendation recommendation) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBgColor = isDark ? const Color(0xFF1A1D21) : Colors.white;
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1D2A39);
    final Color textColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              child: Image.network(
                recommendation.dish.imageUrl,
                height: 350,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.dish.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2))
                    ),
                    child: Text(
                      recommendation.reason,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/menu');
                        },
                        icon: const Icon(Icons.remove_red_eye_outlined),
                        label: const Text('View Dish'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(AiRecommendation recommendation) {
     final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBgColor = isDark ? const Color(0xFF1A1D21) : Colors.white;
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1D2A39);
    final Color textColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: Image.network(
              recommendation.dish.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                    recommendation.dish.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      recommendation.reason,
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/menu');
                      },
                      child: const Text('View Dish Details'),
                       style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.black,
                         shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

