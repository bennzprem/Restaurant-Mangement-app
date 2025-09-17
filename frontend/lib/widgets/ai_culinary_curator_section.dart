import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../theme.dart'; // Make sure you have your AppTheme import

import 'dart:convert';
import 'package:http/http.dart' as http;

class AiCulinaryCuratorSection extends StatefulWidget {
  const AiCulinaryCuratorSection({super.key});

  @override
  State<AiCulinaryCuratorSection> createState() => _AiCulinaryCuratorSectionState();
}

class _AiCulinaryCuratorSectionState extends State<AiCulinaryCuratorSection> {
  // State for the recommendation loaded initially
  Map<String, dynamic>? _initialDish;
  String? _initialReason;
  bool _isLoadingInitial = true;

  // State for the user's custom search
  Map<String, dynamic>? _searchedDish;
  String? _searchedReason;
  bool _isSearching = false;
  String? _searchError;

  final TextEditingController _prefController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialRecommendation();
    });
  }

  Future<void> _fetchInitialRecommendation() async {
    // This is called once when the widget loads
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? "guest";

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:5000/recommendation/$userId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"taste_preference": null}), // No preference, so backend uses history/trending
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _initialDish = data["dish"];
          _initialReason = data["reason"];
        });
      } else {
        setState(() {
          _searchError = "Could not load a suggestion right now.";
        });
      }
    } catch (e) {
      setState(() {
        _searchError = "Server connection error.";
      });
    } finally {
      setState(() {
        _isLoadingInitial = false;
      });
    }
  }

  Future<void> _fetchCustomRecommendation() async {
    // This is called when the user clicks the button
    if (_prefController.text.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? "guest";

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:5000/recommendation/$userId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"taste_preference": _prefController.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _searchedDish = data["dish"];
          _searchedReason = data["reason"];
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _searchError = errorData['error'] ?? 'Could not find a match.';
          _searchedDish = null; // Clear previous search result on error
        });
      }
    } catch (e) {
      setState(() {
        _searchError = "Server error: $e";
        _searchedDish = null;
      });
    }

    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF1A1D21) : Colors.white;
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1D2A39);

    // Determine which dish and reason to display
    final Map<String, dynamic>? dishToDisplay = _searchedDish ?? _initialDish;
    final String? reasonToDisplay = _searchedReason ?? _initialReason;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      color: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Text(
                "AI Culinary Curator",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Get a personalized dish recommendation just for you.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 48),
              if (_isLoadingInitial)
                const Center(child: CircularProgressIndicator())
              else if (dishToDisplay != null)
                _buildRecommendationCard(
                  imageUrl: dishToDisplay['image_url'] ?? '',
                  dishName: dishToDisplay['name'] ?? 'No Name',
                  reason: reasonToDisplay ?? 'Our special pick.',
                  price: dishToDisplay['price']?.toDouble() ?? 0.0,
                )
              else if (_searchError != null)
                 Text(_searchError!, style: const TextStyle(color: Colors.red, fontSize: 16)),

              const SizedBox(height: 40),

              // Search Section
              Text(
                "Or, Find Your Own Craving",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: titleColor),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _prefController,
                      decoration: const InputDecoration(
                        labelText: "e.g., 'Something spicy but healthy'",
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _fetchCustomRecommendation(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isSearching ? null : _fetchCustomRecommendation,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Get Suggestion"),
                  ),
                ],
              ),
               if (_searchError != null && !_isLoadingInitial)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(_searchError!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard({
    required String imageUrl,
    required String dishName,
    required String reason,
    required double price,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D21) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: AspectRatio(
              aspectRatio: 1, // Makes the image container a square
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.primaryLight,
                    child: const Icon(Icons.restaurant_menu, size: 60, color: AppTheme.primaryColor),
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "OUR SUGGESTION",
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dishName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    reason,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '₹${price.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}