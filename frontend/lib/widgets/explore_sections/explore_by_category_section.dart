// File: explore_by_category_section.dart

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../shared/card_carousel.dart';

class ExploreByCategorySection extends StatefulWidget {
  const ExploreByCategorySection({super.key});

  @override
  State<ExploreByCategorySection> createState() => _ExploreByCategorySectionState();
}

class _ExploreByCategorySectionState extends State<ExploreByCategorySection> {
  final ApiService _api = ApiService();
  late Future<List<String>> _futureNames;
  final ScrollController _scrollController = ScrollController();
  bool _isLeftHovered = false;
  bool _isRightHovered = false;

  @override
  void initState() {
    super.initState();
    _futureNames = _loadCategoryNames();
    _scrollController.addListener(() {
      // Trigger rebuild to update arrow visibility during scroll
      if (mounted) setState(() {});
    });
    // Ensure we recompute visibility after first layout so arrows show immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
    // Also add a delayed callback to ensure arrows show after scroll controller is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<String>> _loadCategoryNames() async {
    try {
      final cats = await _api.getCategories();
      final names = cats.map((c) => (c['name'] ?? c['category_name'] ?? '').toString()).where((n) => n.isNotEmpty).toList();
      if (names.isNotEmpty) return names;
    } catch (_) {}

    try {
      final menu = await _api.fetchMenu(vegOnly: false, veganOnly: false, glutenFreeOnly: false, nutsFree: false);
      final set = <String>{};
      for (final MenuCategory mc in menu) {
        set.add(mc.name);
      }
      return set.toList();
    } catch (_) {
      return <String>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: FutureBuilder<List<String>>(
        future: _futureNames,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No categories'));
          }
          
          final cardData = snapshot.data!.map<CarouselCardData>((name) {
            return CarouselCardData(
              title: name,
              onTap: () => Navigator.pushNamed(context, '/menu', arguments: {'initialCategory': name}),
            );
          }).toList();

          final bool hasClients = _scrollController.hasClients;
          final double maxExtent = hasClients ? _scrollController.position.maxScrollExtent : 0;
          final double offset = hasClients ? _scrollController.offset : 0;
          final bool atStart = !hasClients || offset <= 2;
          final bool atEnd = hasClients ? (maxExtent - offset) <= 2 : true;
          // Always show a hint arrow on the right before the controller attaches
          final bool hasMultipleCategories = cardData.length > 1;
          final bool showLeft = hasMultipleCategories && hasClients && !atStart;
          final bool showRight = hasMultipleCategories && (!hasClients || !atEnd);

          return Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 20),
                child: OverlappingCardCarousel(cardData: cardData),
              ),
              if (showLeft)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isLeftHovered = true),
                    onExit: (_) => setState(() => _isLeftHovered = false),
                    cursor: atStart ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: atStart
                          ? null
                          : () {
                              final double target = (_scrollController.offset - 300).clamp(0, maxExtent);
                              _scrollController.animateTo(
                                target,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOut,
                              );
                            },
                      child: _EdgeArrow(
                        isLeft: true, 
                        disabled: atStart,
                        isHovered: _isLeftHovered,
                      ),
                    ),
                  ),
                ),
              if (showRight)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isRightHovered = true),
                    onExit: (_) => setState(() => _isRightHovered = false),
                    cursor: atEnd ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: atEnd
                          ? null
                          : () {
                              final double target = (_scrollController.offset + 300).clamp(0, maxExtent);
                              _scrollController.animateTo(
                                target,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOut,
                              );
                            },
                      child: _EdgeArrow(
                        isLeft: false, 
                        disabled: atEnd,
                        isHovered: _isRightHovered,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EdgeArrow extends StatefulWidget {
  final bool isLeft;
  final bool disabled;
  final bool isHovered;
  const _EdgeArrow({required this.isLeft, this.disabled = false, this.isHovered = false});

  @override
  State<_EdgeArrow> createState() => _EdgeArrowState();
}

class _EdgeArrowState extends State<_EdgeArrow> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_EdgeArrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHovered && !oldWidget.isHovered) {
      _animationController.forward();
    } else if (!widget.isHovered && oldWidget.isHovered) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color base = isDark ? Colors.black : Colors.white;
    final Alignment begin = widget.isLeft ? Alignment.centerLeft : Alignment.centerRight;
    final Alignment end = widget.isLeft ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      width: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: [base.withOpacity(0.98), base.withOpacity(0.0)],
        ),
      ),
      alignment: widget.isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isHovered ? _scaleAnimation.value : 1.0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: base.withOpacity(
                    widget.disabled ? 0.55 : (widget.isHovered ? 0.95 : 0.9),
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isHovered 
                        ? (isDark ? Colors.white38 : Colors.black26)
                        : (isDark ? Colors.white24 : Colors.black12),
                    width: widget.isHovered ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        widget.disabled ? 0.05 : (widget.isHovered ? 0.25 : 0.18),
                      ),
                      blurRadius: widget.isHovered ? 12 : 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  widget.isLeft ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios,
                  size: 22,
                  color: widget.disabled
                      ? (isDark ? Colors.white54 : Colors.black45)
                      : (widget.isHovered 
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? Colors.white : Colors.black87)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}