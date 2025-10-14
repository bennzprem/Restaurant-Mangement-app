// lib/subscription_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'services/subscription_service.dart';
import 'subscription_models.dart';
import 'auth_provider.dart';

class SubscriptionDashboardPage extends StatefulWidget {
  const SubscriptionDashboardPage({super.key});

  @override
  State<SubscriptionDashboardPage> createState() =>
      _SubscriptionDashboardPageState();
}

class _SubscriptionDashboardPageState extends State<SubscriptionDashboardPage> {
  UserSubscription? _currentSubscription;
  List<CreditTransaction> _creditHistory = [];
  bool _isLoading = true;
  String? _error;
  final SubscriptionService _subscriptionService = SubscriptionService();

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null || authProvider.accessToken == null) {
        setState(() {
          _error = 'Please login to view subscription data';
          _isLoading = false;
        });
        return;
      }

      // Load current subscription
      try {
        _currentSubscription =
            await _subscriptionService.getCurrentSubscription(
          authProvider.user!.id,
          authProvider.accessToken!,
        );
      } catch (e) {
        // No active subscription found
        _currentSubscription = null;
      }

      // Load credit history if subscription exists
      if (_currentSubscription != null) {
        _creditHistory = await _subscriptionService.getCreditHistory(
          _currentSubscription!.id,
          authProvider.accessToken!,
        );
      }

      setState(() {
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
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: Text(
          'My Subscriptions',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadSubscriptionData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _currentSubscription == null
                  ? _buildNoSubscriptionState()
                  : _buildSubscriptionDashboard(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load subscription data',
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
            onPressed: _loadSubscriptionData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubscriptionState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_membership, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Active Subscription',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Subscribe to a meal plan to start saving on your orders',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/subscription-plans');
            },
            icon: const Icon(Icons.add),
            label: const Text('Browse Plans'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF689F38),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Subscription Card
          _buildCurrentSubscriptionCard(),
          const SizedBox(height: 24),

          // Credit Balance Card
          _buildCreditBalanceCard(),
          const SizedBox(height: 24),

          // Credit History
          _buildCreditHistorySection(),
        ],
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    final plan = _currentSubscription!.plan;
    final planColor = _getPlanColor(plan!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: planColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.card_membership,
                  color: planColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: planColor,
                      ),
                    ),
                    Text(
                      'Active Subscription',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentSubscription!.statusDisplayText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Start Date',
                  DateFormat('MMM d, yyyy')
                      .format(_currentSubscription!.startDate),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'End Date',
                  DateFormat('MMM d, yyyy')
                      .format(_currentSubscription!.endDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            'Days Remaining',
            '${_currentSubscription!.daysRemaining} days',
            isHighlight: _currentSubscription!.isExpiringSoon,
          ),
        ],
      ),
    );
  }

  Widget _buildCreditBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF689F38),
            const Color(0xFF8BC34A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Credit Balance',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${_currentSubscription!.remainingCredits}',
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'credits',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'of ${_currentSubscription!.totalCredits} total credits',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _currentSubscription!.creditUsagePercentage / 100,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildCreditHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Credit History',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        if (_creditHistory.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No credit transactions yet',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        else
          ..._creditHistory
              .map((transaction) => _buildCreditTransactionCard(transaction)),
      ],
    );
  }

  Widget _buildCreditTransactionCard(CreditTransaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getTransactionColor(transaction).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTransactionIcon(transaction),
              color: _getTransactionColor(transaction),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeDisplayText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                if (transaction.description != null)
                  Text(
                    transaction.description!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                Text(
                  DateFormat('MMM d, yyyy • hh:mm a')
                      .format(transaction.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${transaction.isCreditUsage ? '-' : '+'}${transaction.creditsUsed}',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getTransactionColor(transaction),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value,
      {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isHighlight ? Colors.orange[700] : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Color _getPlanColor(SubscriptionPlan plan) {
    if (plan.name.toLowerCase().contains('basic')) {
      return const Color(0xFF8BC34A);
    } else if (plan.name.toLowerCase().contains('premium')) {
      return const Color(0xFF689F38);
    } else if (plan.name.toLowerCase().contains('elite')) {
      return const Color(0xFF33691E);
    }
    return const Color(0xFF8BC34A);
  }

  Color _getTransactionColor(CreditTransaction transaction) {
    switch (transaction.type) {
      case CreditTransactionType.used:
        return Colors.red;
      case CreditTransactionType.refunded:
        return Colors.green;
      case CreditTransactionType.bonus:
        return Colors.blue;
      case CreditTransactionType.purchased:
        return Colors.purple;
    }
  }

  IconData _getTransactionIcon(CreditTransaction transaction) {
    switch (transaction.type) {
      case CreditTransactionType.used:
        return Icons.shopping_cart;
      case CreditTransactionType.refunded:
        return Icons.refresh;
      case CreditTransactionType.bonus:
        return Icons.card_giftcard;
      case CreditTransactionType.purchased:
        return Icons.payment;
    }
  }
}
