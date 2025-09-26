/*import 'package:flutter/material.dart';

class FitnessCategoriesSection extends StatelessWidget {
  const FitnessCategoriesSection({super.key});

  final List<Map<String, dynamic>> items = const [
    {
      "title": "Muscle Fuel",
      "icon": Icons.fitness_center,
      "subtitle": "High-protein picks to build strength"
    },
    {
      "title": "Light & Lean",
      "icon": Icons.directions_run,
      "subtitle": "Low-cal choices for active days"
    },
    {
      "title": "Daily Balance",
      "icon": Icons.self_improvement,
      "subtitle": "Nutritious staples for every day"
    },
    {
      "title": "Power Gain",
      "icon": Icons.sports_mma,
      "subtitle": "Energy-dense meals for training"
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _HoverableCard(
            width: 240,
            onTap: () => Navigator.pushNamed(context, '/explore/fitness', arguments: {'initialCategory': item['title']}),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item['icon'], color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['title'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['subtitle'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HoverableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double width;
  const _HoverableCard({required this.child, required this.onTap, this.width = 240});

  @override
  State<_HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<_HoverableCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        padding: const EdgeInsets.all(14),
        transform: _hovered ? (Matrix4.identity()..scale(1.02)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _hovered ? Theme.of(context).primaryColor : (isDark ? Colors.white12 : Colors.black12)),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: Theme.of(context).primaryColor.withOpacity(0.15),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
*/
// File: fitness_categories_section.dart

import 'package:flutter/material.dart';
import '../shared/card_carousel.dart'; // Import the new widget

class FitnessCategoriesSection extends StatefulWidget {
  const FitnessCategoriesSection({super.key});

  @override
  State<FitnessCategoriesSection> createState() => _FitnessCategoriesSectionState();
}

class _FitnessCategoriesSectionState extends State<FitnessCategoriesSection> {
  final ScrollController _scrollController = ScrollController();
  bool _isLeftHovered = false;
  bool _isRightHovered = false;

  // Original hardcoded data
  final List<Map<String, dynamic>> items = const [
    {"title": "Muscle Fuel"},
    {"title": "Light & Lean"},
    {"title": "Daily Balance"},
    {"title": "Power Gain"},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
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

  @override
  Widget build(BuildContext context) {
    // Map the hardcoded data to the card data model
    final cardData = items.map<CarouselCardData>((item) {
      return CarouselCardData(
        title: item['title']!,
        onTap: () => Navigator.pushNamed(context, '/explore/fitness', arguments: {'initialCategory': item['title']}),
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

    return SizedBox(
      height: 230,
      child: Stack(
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
