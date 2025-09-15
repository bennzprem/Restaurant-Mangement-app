import 'package:flutter/material.dart';

class SpecialDietarySection extends StatelessWidget {
  const SpecialDietarySection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Vegan', Icons.eco),
      ('Vegetarian', Icons.spa),
      ('Gluten Free', Icons.grain),
      ('Nuts Free', Icons.no_food),
      ('Keto', Icons.scale),
    ];
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final (label, icon) = items[index];
          return _DietCard(label: label, icon: icon);
        },
      ),
    );
  }
}

class _DietCard extends StatelessWidget {
  final String label;
  final IconData icon;
  const _DietCard({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}


