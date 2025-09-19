import 'package:flutter/material.dart';

class CheckoutStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? content;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onTap;

  const CheckoutStep({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.content,
    this.isActive = false,
    this.isCompleted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive || isCompleted
                    ? const Color(0xFF4CAF50)
                    : (isDark ? Colors.grey[700] : Colors.grey[300]),
                borderRadius: BorderRadius.circular(8),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            // Step Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isActive || isCompleted
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                  if (content != null && isActive) ...[
                    const SizedBox(height: 12),
                    content!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckoutStepsList extends StatelessWidget {
  final List<CheckoutStep> steps;

  const CheckoutStepsList({
    super.key,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Checkout',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;

            return Column(
              children: [
                step,
                if (index < steps.length - 1)
                  Container(
                    margin: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                    height: 20,
                    child: VerticalDivider(
                      color: isDark ? Colors.grey[600] : Colors.grey[300],
                      thickness: 2,
                      width: 2,
                    ),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
