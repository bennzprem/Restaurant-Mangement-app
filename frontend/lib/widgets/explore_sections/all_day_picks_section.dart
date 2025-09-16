import 'package:flutter/material.dart';

class AllDayPicksSection extends StatelessWidget {
  const AllDayPicksSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Time-Based Menus (Breakfast, Lunch, Snacks, Dinner)
    final items = [
      ('Breakfast Delights', Icons.free_breakfast, 'Wholesome starts for fresh mornings'),
      ('Lunch Favorites', Icons.lunch_dining, 'Hearty plates to power your day'),
      ('Evening Snacks', Icons.emoji_food_beverage, 'Crunchy, chatpata pick-me-ups'),
      ('Dinner Specials', Icons.restaurant, 'Slow-cooked comfort for cosy nights'),
    ];

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final (title, icon, subtitle) = items[index];
          return _TimeMenuCard(title: title, subtitle: subtitle, icon: icon);
        },
      ),
    );
  }
}

class _TimeMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _TimeMenuCard({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _HoverableCard(
      onTap: () => Navigator.pushNamed(context, '/menu', arguments: {'initialCategory': title}),
      borderRadius: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _HoverableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;
  const _HoverableCard({required this.child, required this.onTap, this.borderRadius = 12});

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
        width: 220,
        padding: const EdgeInsets.all(14),
        transform: _hovered ? (Matrix4.identity()..scale(1.02)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white,
          borderRadius: BorderRadius.circular(widget.borderRadius),
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
            borderRadius: BorderRadius.circular(widget.borderRadius),
            splashColor: Theme.of(context).primaryColor.withOpacity(0.15),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}


