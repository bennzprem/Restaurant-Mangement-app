import 'package:flutter/material.dart';

class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool enabled;

  const QuantityStepper({
    super.key,
    required this.quantity,
    this.onIncrement,
    this.onDecrement,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: enabled ? onDecrement : null,
          icon: Icon(
            Icons.remove,
            color: enabled
                ? (isDark ? Colors.white70 : Colors.grey[700])
                : Colors.grey[400],
            size: 18,
          ),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          padding: EdgeInsets.zero,
        ),
        Container(
          width: 40,
          height: 32,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              '$quantity',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: enabled ? onIncrement : null,
          icon: Icon(
            Icons.add,
            color: enabled
                ? (isDark ? Colors.white70 : Colors.grey[700])
                : Colors.grey[400],
            size: 18,
          ),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
