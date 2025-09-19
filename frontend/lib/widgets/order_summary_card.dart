import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../cart_provider.dart';
import 'quantity_stepper.dart';

class OrderSummaryCard extends StatelessWidget {
  final VoidCallback? onProceedToPay;
  final bool isTableMode;

  const OrderSummaryCard({
    super.key,
    this.onProceedToPay,
    this.isTableMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '₹');
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (cart.items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Your cart is empty',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53E3E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ByteEat Restaurant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        'Maruti Nagar',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cart Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: cart.items.values.map((cartItem) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Item Image
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(cartItem.menuItem.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Item Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cartItem.menuItem.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Vegetarian',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Customize >',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF4CAF50),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quantity and Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          QuantityStepper(
                            quantity: cartItem.quantity,
                            onIncrement: () => cart.addItem(cartItem.menuItem),
                            onDecrement: () =>
                                cart.removeSingleItem(cartItem.menuItem.id),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(cartItem.menuItem.price),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Suggestions
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.format_quote,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Any suggestions? We will pass it on...',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // No-contact Delivery
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CheckboxListTile(
              value: false,
              onChanged: (value) {},
              title: Text(
                'Opt in for No-contact Delivery',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Unwell, or avoiding contact? Please select no-contact delivery. Partner will safely place the order outside your door (not for COD)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFF4CAF50),
            ),
          ),

          const SizedBox(height: 16),

          // Bill Details
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Bill Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),

                // Item Total
                _buildBillRow(
                  'Item Total',
                  currencyFormat.format(cart.totalAmount),
                  isDark,
                ),

                // Delivery Fee
                _buildBillRow(
                  'Delivery Fee | 2.7 kms',
                  '₹41',
                  isDark,
                  trailing: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),

                // GST & Other Charges
                _buildBillRow(
                  'GST & Other Charges',
                  '₹74.69',
                  isDark,
                  trailing: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),

                const Divider(height: 20),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TO PAY',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      currencyFormat.format(cart.totalAmount + 41 + 74.69),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Review Text
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Review your order and address details to avoid cancellations',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String amount, bool isDark,
      {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing,
              ],
            ],
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
