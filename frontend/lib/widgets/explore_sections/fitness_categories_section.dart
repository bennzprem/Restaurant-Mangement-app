import 'package:flutter/material.dart';

class FitnessCategoriesSection extends StatelessWidget {
  const FitnessCategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('High Protein', Icons.fitness_center),
      ('Low Carb', Icons.directions_run),
      ('Balanced', Icons.self_improvement),
      ('Bulk Up', Icons.sports_mma),
    ];
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final (label, icon) = items[index];
          return _FitnessCard(label: label, icon: icon);
        },
      ),
    );
  }
}

class _FitnessCard extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FitnessCard({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const Spacer(),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


