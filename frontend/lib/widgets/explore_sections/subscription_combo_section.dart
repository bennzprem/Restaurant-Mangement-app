import 'package:flutter/material.dart';

class SubscriptionComboSection extends StatelessWidget {
  const SubscriptionComboSection({super.key});

  final List<Map<String, dynamic>> items = const [
    {
      "title": "Smart Saver",
      "icon": Icons.calendar_view_week,
      "subtitle": "Save more with weekly smart plans"
    },
    {
      "title": "Hassle-Free Month",
      "icon": Icons.calendar_month,
      "subtitle": "One-click meals for the whole month"
    },
    {
      "title": "Family Feast",
      "icon": Icons.family_restroom,
      "subtitle": "Big portions made for sharing"
    },
    {
      "title": "Workday Fuel",
      "icon": Icons.business_center,
      "subtitle": "Quick combos to power busy days"
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
            onTap: () => Navigator.pushNamed(context, '/explore/subscription-combo', arguments: {'initialCategory': item['title']}),
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