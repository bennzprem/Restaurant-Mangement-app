// lib/subscription_plans_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/subscription_service.dart';
import 'services/payment_service.dart';
import 'subscription_models.dart';
import 'auth_provider.dart';

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  List<SubscriptionPlan> _subscriptionPlans = [];
  bool _isLoading = true;
  String? _error;
  final SubscriptionService _subscriptionService = SubscriptionService();

  // Define constant colors from the design
  static const Color backgroundColor = Color(0xFFDBECE9);
  static const Color cardColor = Color(0xFFEAF2F1);
  static const Color primaryTextColor = Color(0xFF2D2D2D);
  static const Color secondaryTextColor = Color(0xFF6E828A);
  static const Color basicPlanColor = Color(0xFF8BC34A);
  static const Color premiumPlanColor = Color(0xFF689F38);
  static const Color elitePlanColor = Color(0xFF33691E);

  @override
  void initState() {
    super.initState();
    _loadSubscriptionPlans();
  }

  Future<void> _loadSubscriptionPlans() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final plans = await _subscriptionService.getSubscriptionPlans();
      setState(() {
        _subscriptionPlans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Meal Subscription Plans',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF689F38),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 60.0, horizontal: 24.0),
            // Constrain the width for larger screens for better readability
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                // Top "Pricing" chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    'Pricing',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Main heading
                const Text(
                  'Meal Plans for\nevery appetite',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 20),
                // Sub-heading
                const Text(
                  'Get going and enjoy delicious meals with our flexible subscription plans.',
                  style: TextStyle(
                    fontSize: 18,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 50),

                // Plans Grid
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load subscription plans',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.red[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadSubscriptionPlans,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else
                  // Use a Wrap widget for responsiveness
                  Wrap(
                    spacing: 24, // Horizontal space between cards
                    runSpacing:
                        24, // Vertical space between cards when they wrap
                    alignment: WrapAlignment.center,
                    children: _subscriptionPlans.asMap().entries.map((entry) {
                      final index = entry.key;
                      final plan = entry.value;
                      final isFeatured =
                          index == 1; // Make Premium plan featured
                      final isPremium = index == 2; // Make Elite plan premium

                      return MealSubscriptionCard(
                        plan: plan,
                        isFeatured: isFeatured,
                        isPremium: isPremium,
                        onTap: () {
                          // Handle plan selection if needed
                        },
                        onSubscribe: () => _subscribeToPlan(plan),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _subscribeToPlan(SubscriptionPlan plan) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.user == null) {
        _showErrorDialog('Please login to subscribe to a plan');
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Process payment
      final success = await PaymentService.processPayment(
        context: context,
        amount: plan.price.toInt(),
        orderId:
            'SUBSCRIPTION_${plan.id}_${DateTime.now().millisecondsSinceEpoch}',
        customerName: authProvider.user!.name,
        customerEmail: authProvider.user!.email ?? '',
        customerPhone: '9999999999', // Default phone number
        onSuccess: () => _createSubscription(plan),
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        _showSuccessDialog(plan);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      _showErrorDialog('Payment failed: $e');
    }
  }

  Future<void> _createSubscription(SubscriptionPlan plan) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Create subscription in backend
      final subscription = await _subscriptionService.createSubscription(
        userId: authProvider.user!.id,
        planId: plan.id,
        token: authProvider.accessToken ?? '',
        paymentId:
            'temp_payment_id', // This will be updated by the payment service
        paymentOrderId:
            'temp_order_id', // This will be updated by the payment service
      );

      print('Subscription created successfully: ${subscription.id}');
    } catch (e) {
      print('Error creating subscription: $e');
      throw e;
    }
  }

  void _showSuccessDialog(SubscriptionPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Text('Subscription Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You have successfully subscribed to ${plan.name}!'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your subscription includes:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('• ${plan.credits} meal credits'),
                  Text('• Valid for ${plan.durationDays} days'),
                  Text('• Max meal price: ${plan.formattedMaxMealPrice}'),
                  if (plan.hasDiscount)
                    Text(
                        '• ${plan.discountPercentage}% discount on additional orders'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to dashboard
            },
            child: const Text('Go to Dashboard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to dashboard
              Navigator.pushNamed(context, '/subscription-dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('View My Subscriptions'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Text('Subscription Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// A reusable widget for the meal subscription cards
class MealSubscriptionCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isFeatured;
  final bool isPremium;
  final VoidCallback onTap;
  final VoidCallback onSubscribe;

  const MealSubscriptionCard({
    super.key,
    required this.plan,
    required this.isFeatured,
    required this.isPremium,
    required this.onTap,
    required this.onSubscribe,
  });

  Color _getPlanColor() {
    if (plan.name.toLowerCase().contains('basic')) {
      return _SubscriptionPlansPageState.basicPlanColor;
    } else if (plan.name.toLowerCase().contains('premium')) {
      return _SubscriptionPlansPageState.premiumPlanColor;
    } else if (plan.name.toLowerCase().contains('elite')) {
      return _SubscriptionPlansPageState.elitePlanColor;
    }
    return _SubscriptionPlansPageState.basicPlanColor;
  }

  List<String> _getPlanFeatures() {
    List<String> features = [
      '${plan.credits} meal credits',
      'Valid for ${plan.durationDays} days',
      'Any menu item up to ${plan.formattedMaxMealPrice}',
    ];

    if (plan.hasDiscount) {
      features.add('${plan.discountPercentage}% discount on additional orders');
    }

    // Add tier-specific features
    if (plan.name.toLowerCase().contains('premium')) {
      features.add('Priority support');
    } else if (plan.name.toLowerCase().contains('elite')) {
      features.add('Priority delivery');
      features.add('VIP support');
    } else {
      features.add('Email support');
    }

    return features;
  }

  @override
  Widget build(BuildContext context) {
    final planColor = _getPlanColor();
    final features = _getPlanFeatures();

    // Determine styles based on the card type
    Color buttonColor = isFeatured
        ? _SubscriptionPlansPageState.premiumPlanColor
        : (isPremium
            ? _SubscriptionPlansPageState.elitePlanColor
            : Colors.white);
    Color buttonTextColor = isFeatured || isPremium
        ? Colors.white
        : _SubscriptionPlansPageState.primaryTextColor;
    Border? buttonBorder = isFeatured || isPremium
        ? null
        : Border.all(color: Colors.grey.shade300);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _SubscriptionPlansPageState.cardColor,
          borderRadius: BorderRadius.circular(16),
          // Add a border if it's the featured plan
          border: isFeatured
              ? Border.all(
                  color: _SubscriptionPlansPageState.premiumPlanColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _SubscriptionPlansPageState.primaryTextColor,
              ),
            ),
            const SizedBox(height: 20),
            // Price text row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  plan.formattedPrice,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _SubscriptionPlansPageState.primaryTextColor,
                  ),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'per Month',
                    style: TextStyle(
                      fontSize: 16,
                      color: _SubscriptionPlansPageState.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Features list
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: planColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            fontSize: 16,
                            color: _SubscriptionPlansPageState.primaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 15),
            // Subscribe button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onSubscribe,
                style: TextButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: buttonBorder != null
                      ? BorderSide(color: Colors.grey.shade300)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Subscribe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: buttonTextColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: buttonTextColor, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
