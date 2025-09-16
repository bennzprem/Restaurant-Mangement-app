import 'package:flutter/material.dart';

class FitnessCategoriesSection extends StatelessWidget {
  const FitnessCategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Muscle Fuel', Icons.fitness_center, 'High-protein picks to build strength'),
      ('Light & Lean', Icons.directions_run, 'Low-cal choices for active days'),
      ('Daily Balance', Icons.self_improvement, 'Nutritious staples for every day'),
      ('Power Gain', Icons.sports_mma, 'Energy-dense meals for training'),
    ];
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final (title, icon, subtitle) = items[index];
          return _FitnessCard(title: title, icon: icon, subtitle: subtitle);
        },
      ),
    );
  }
}

class _FitnessCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _FitnessCard({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _HoverableCard(
      width: 240,
      onTap: () => Navigator.pushNamed(context, '/menu', arguments: {'initialCategory': title}),
      child: Row(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
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


