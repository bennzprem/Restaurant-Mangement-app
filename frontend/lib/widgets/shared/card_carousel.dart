// File: widgets/shared/card_carousel.dart

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

// Shared sizing so sections can match the card height
const double kCarouselCardWidth = 200.0;
const double kCarouselCardHeight = 230.0; // reduced from 280 for better fold

// A simple data model for each card
class CarouselCardData {
  final String title;
  final VoidCallback? onTap; // <-- ADD this onTap field

  // UPDATE the constructor to accept the onTap callback
  const CarouselCardData({required this.title, this.onTap});
}

class OverlappingCardCarousel extends StatefulWidget {
  final List<CarouselCardData> cardData;
  const OverlappingCardCarousel({super.key, required this.cardData});

  @override
  State<OverlappingCardCarousel> createState() => _OverlappingCardCarouselState();
}

class _OverlappingCardCarouselState extends State<OverlappingCardCarousel> {
  int? _hoveredIndex;

  static const double cardWidth = kCarouselCardWidth;
  static const double cardHeight = kCarouselCardHeight;
  static const double overlap = 50.0;
  static const double adjacentCardShiftX = 50.0;

  @override
  Widget build(BuildContext context) {
    final double totalWidth = cardWidth + (widget.cardData.length - 1) * (cardWidth - overlap) + adjacentCardShiftX;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double viewportWidth = MediaQuery.of(context).size.width;
        // Account for section horizontal padding (16 outer + 16 inner)
        final double estimatedContentWidth = viewportWidth - 64;
        final double containerWidth = constraints.maxWidth.isFinite
            ? math.max(totalWidth, constraints.maxWidth)
            : math.max(totalWidth, estimatedContentWidth);
        final double startLeft = (containerWidth - totalWidth) / 2;

        return SizedBox(
          height: cardHeight,
          width: containerWidth,
          child: MouseRegion(
            onExit: (_) => setState(() => _hoveredIndex = null),
            child: Stack(
              clipBehavior: Clip.none,
              children: List.generate(widget.cardData.length, (index) {
                final bool isHovered = _hoveredIndex == index;
                double left = startLeft + index * (cardWidth - overlap);
                double top = isHovered ? -20.0 : 0.0;

                if (_hoveredIndex != null && index > _hoveredIndex!) {
                  left += adjacentCardShiftX;
                }

                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  top: top,
                  left: left,
                  child: GestureDetector(
                    onTap: widget.cardData[index].onTap,
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _hoveredIndex = index),
                      cursor: SystemMouseCursors.click,
                      child: _CardContent(
                        data: widget.cardData[index],
                        isHovered: isHovered,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

// The rest of the file (_CardContent, _CircleStrokePainter) does not need changes.
class _CardContent extends StatelessWidget {
  final CarouselCardData data;
  final bool isHovered;

  const _CardContent({required this.data, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark
        ? Colors.black.withOpacity(0.45)
        : Colors.white.withOpacity(0.55);
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.35);
    final Color titleColor = isDark ? Colors.white : Colors.black87;
    final Color trackColor = isDark ? Colors.white24 : Colors.black12;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: kCarouselCardWidth,
          height: kCarouselCardHeight,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.35)
                    : Colors.black.withOpacity(0.08),
                offset: const Offset(0, 10),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
        children: [
          Positioned(
            top: 15,
            left: 20,
            child: Text(
              data.title,
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ),
          // Removed the colored progress line for a cleaner card
          Positioned(
            top: 60,
            left: (kCarouselCardWidth - 140) / 2,
            child: SizedBox(
              width: 140,
              height: 120,
              child: _RandomCategoryImage(
                categoryName: data.title,
                isHovered: isHovered,
                isDark: isDark,
              ),
            ),
          ),
        ],
        ),
      ),
    ),
  );
  }
}

class _RandomCategoryImage extends StatefulWidget {
  final String categoryName;
  final bool isHovered;
  final bool isDark;

  const _RandomCategoryImage({required this.categoryName, required this.isHovered, required this.isDark});

  @override
  State<_RandomCategoryImage> createState() => _RandomCategoryImageState();
}

class _RandomCategoryImageState extends State<_RandomCategoryImage> {
  static final Map<String, String?> _cache = {};
  late Future<String?> _futureUrl;

  @override
  void initState() {
    super.initState();
    _futureUrl = _load();
  }

  Future<String?> _load() async {
    if (_cache.containsKey(widget.categoryName)) return _cache[widget.categoryName];

    try {
      final api = ApiService();
      final List<MenuCategory> categories = await api.fetchMenu(
        vegOnly: false,
        veganOnly: false,
        glutenFreeOnly: false,
        nutsFree: false,
      );
      // Try exact category match
      MenuCategory? match = categories.firstWhere(
        (c) => c.name.toLowerCase() == widget.categoryName.toLowerCase(),
        orElse: () => MenuCategory(id: -1, name: '', items: const []),
      );

      // If not found, try partial match (contains)
      if (match.items.isEmpty) {
        final partial = categories.where(
          (c) => c.name.toLowerCase().contains(widget.categoryName.toLowerCase()),
        );
        if (partial.isNotEmpty) {
          match = partial.first;
        }
      }

      final rnd = math.Random();
      String? url;

      if (match.items.isNotEmpty) {
        url = match.items[rnd.nextInt(match.items.length)].imageUrl;
      } else {
        // Fallback: choose a random item from the entire menu so we still show an image
        final allItems = categories.expand((c) => c.items).toList();
        if (allItems.isNotEmpty) {
          url = allItems[rnd.nextInt(allItems.length)].imageUrl;
        }
      }

      _cache[widget.categoryName] = url;
      _cache[widget.categoryName] = url;
      return url;
    } catch (_) {
      _cache[widget.categoryName] = null;
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _futureUrl,
      builder: (context, snapshot) {
        final hasUrl = snapshot.connectionState == ConnectionState.done && (snapshot.data?.isNotEmpty ?? false);
        final child = hasUrl
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  snapshot.data!,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: widget.isDark ? Colors.white10 : Colors.black12,
                ),
              );

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.95, end: widget.isHovered ? 1.0 : 0.95),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, scale, _) {
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: widget.isHovered ? 1.0 : 0.85,
              child: Transform.scale(scale: scale, child: child),
            );
          },
        );
      },
    );
  }
}