// lib/subscription_models.dart

class SubscriptionPlan {
  final int id;
  final String name;
  final String description;
  final double price;
  final int credits;
  final double maxMealPrice;
  final int discountPercentage;
  final int durationDays;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.credits,
    required this.maxMealPrice,
    required this.discountPercentage,
    required this.durationDays,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      credits: json['credits'],
      maxMealPrice: (json['max_meal_price'] as num).toDouble(),
      discountPercentage: json['discount_percentage'] ?? 0,
      durationDays: json['duration_days'] ?? 30,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'credits': credits,
      'max_meal_price': maxMealPrice,
      'discount_percentage': discountPercentage,
      'duration_days': durationDays,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  double get pricePerCredit => price / credits;
  bool get hasDiscount => discountPercentage > 0;
  String get formattedPrice => '₹${price.toStringAsFixed(0)}';
  String get formattedMaxMealPrice => '₹${maxMealPrice.toStringAsFixed(0)}';
}

class UserSubscription {
  final int id;
  final String userId;
  final int planId;
  final DateTime startDate;
  final DateTime endDate;
  final SubscriptionStatus status;
  final int remainingCredits;
  final int totalCredits;
  final bool autoRenew;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SubscriptionPlan? plan; // Optional plan details

  UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.remainingCredits,
    required this.totalCredits,
    required this.autoRenew,
    required this.createdAt,
    required this.updatedAt,
    this.plan,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'],
      userId: json['user_id'],
      planId: json['plan_id'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: SubscriptionStatus.fromString(json['status']),
      remainingCredits: json['remaining_credits'],
      totalCredits: json['total_credits'],
      autoRenew: json['auto_renew'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      plan: json['subscription_plans'] != null
          ? SubscriptionPlan.fromJson(json['subscription_plans'])
          : (json['plan'] != null
              ? SubscriptionPlan.fromJson(json['plan'])
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_id': planId,
      'start_date':
          startDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'end_date': endDate.toIso8601String().split('T')[0],
      'status': status.value,
      'remaining_credits': remainingCredits,
      'total_credits': totalCredits,
      'auto_renew': autoRenew,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isActive => status == SubscriptionStatus.active;
  bool get isExpired => status == SubscriptionStatus.expired;
  bool get isCancelled => status == SubscriptionStatus.cancelled;
  bool get isPaused => status == SubscriptionStatus.paused;

  int get usedCredits => totalCredits - remainingCredits;
  double get creditUsagePercentage => (usedCredits / totalCredits) * 100;

  int get daysRemaining {
    final now = DateTime.now();
    if (endDate.isBefore(now)) return 0;
    return endDate.difference(now).inDays;
  }

  bool get isExpiringSoon => daysRemaining <= 7 && daysRemaining > 0;

  String get statusDisplayText {
    switch (status) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.paused:
        return 'Paused';
    }
  }
}

enum SubscriptionStatus {
  active,
  expired,
  cancelled,
  paused;

  String get value {
    switch (this) {
      case SubscriptionStatus.active:
        return 'active';
      case SubscriptionStatus.expired:
        return 'expired';
      case SubscriptionStatus.cancelled:
        return 'cancelled';
      case SubscriptionStatus.paused:
        return 'paused';
    }
  }

  static SubscriptionStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'paused':
        return SubscriptionStatus.paused;
      default:
        return SubscriptionStatus.expired;
    }
  }
}

class CreditTransaction {
  final int id;
  final int subscriptionId;
  final int? orderId;
  final int creditsUsed;
  final CreditTransactionType type;
  final String? description;
  final DateTime createdAt;

  CreditTransaction({
    required this.id,
    required this.subscriptionId,
    this.orderId,
    required this.creditsUsed,
    required this.type,
    this.description,
    required this.createdAt,
  });

  factory CreditTransaction.fromJson(Map<String, dynamic> json) {
    return CreditTransaction(
      id: json['id'],
      subscriptionId: json['subscription_id'],
      orderId: json['order_id'],
      creditsUsed: json['credits_used'],
      type: CreditTransactionType.fromString(json['transaction_type']),
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subscription_id': subscriptionId,
      'order_id': orderId,
      'credits_used': creditsUsed,
      'transaction_type': type.value,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isCreditUsage => type == CreditTransactionType.used;
  bool get isRefund => type == CreditTransactionType.refunded;
  bool get isBonus => type == CreditTransactionType.bonus;
  bool get isPurchase => type == CreditTransactionType.purchased;

  String get typeDisplayText {
    switch (type) {
      case CreditTransactionType.used:
        return 'Used for Order';
      case CreditTransactionType.refunded:
        return 'Refunded';
      case CreditTransactionType.bonus:
        return 'Bonus Credits';
      case CreditTransactionType.purchased:
        return 'Subscription Purchase';
    }
  }
}

enum CreditTransactionType {
  used,
  refunded,
  bonus,
  purchased;

  String get value {
    switch (this) {
      case CreditTransactionType.used:
        return 'used';
      case CreditTransactionType.refunded:
        return 'refunded';
      case CreditTransactionType.bonus:
        return 'bonus';
      case CreditTransactionType.purchased:
        return 'purchased';
    }
  }

  static CreditTransactionType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'used':
        return CreditTransactionType.used;
      case 'refunded':
        return CreditTransactionType.refunded;
      case 'bonus':
        return CreditTransactionType.bonus;
      case 'purchased':
        return CreditTransactionType.purchased;
      default:
        return CreditTransactionType.used;
    }
  }
}

class SubscriptionPayment {
  final int id;
  final int subscriptionId;
  final double amount;
  final String? paymentMethod;
  final PaymentStatus status;
  final String? razorpayPaymentId;
  final String? razorpayOrderId;
  final DateTime createdAt;

  SubscriptionPayment({
    required this.id,
    required this.subscriptionId,
    required this.amount,
    this.paymentMethod,
    required this.status,
    this.razorpayPaymentId,
    this.razorpayOrderId,
    required this.createdAt,
  });

  factory SubscriptionPayment.fromJson(Map<String, dynamic> json) {
    return SubscriptionPayment(
      id: json['id'],
      subscriptionId: json['subscription_id'],
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'],
      status: PaymentStatus.fromString(json['payment_status']),
      razorpayPaymentId: json['razorpay_payment_id'],
      razorpayOrderId: json['razorpay_order_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subscription_id': subscriptionId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_status': status.value,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_order_id': razorpayOrderId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isCompleted => status == PaymentStatus.completed;
  bool get isPending => status == PaymentStatus.pending;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isRefunded => status == PaymentStatus.refunded;

  String get formattedAmount => '₹${amount.toStringAsFixed(0)}';
  String get statusDisplayText {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded;

  String get value {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.completed:
        return 'completed';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.refunded:
        return 'refunded';
    }
  }

  static PaymentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }
}
