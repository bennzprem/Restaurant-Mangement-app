import 'package:flutter/material.dart';

class SubscriptionComboSection extends StatelessWidget {
  const SubscriptionComboSection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Weekly Combo', Icons.calendar_view_week),
      ('Monthly Combo', Icons.calendar_month),
      ('Family Pack', Icons.family_restroom),
      ('Office Lunch', Icons.business_center),
    ];
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final (label, icon) = items[index];
          return _ComboCard(label: label, icon: icon);
        },
      ),
    );
  }
}

class _ComboCard extends StatelessWidget {
  final String label;
  final IconData icon;
  const _ComboCard({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}


