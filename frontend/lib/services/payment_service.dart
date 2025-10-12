import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:js' as js;
import '../theme.dart';
import '../config/razorpay_config.dart';

class PaymentService {
  static Razorpay? _razorpay;

  // Using Razorpay key from config

  static Completer<bool>? _paymentCompleter;

  static void initialize() {
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  static VoidCallback? _onSuccessCallback;

  static void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('Payment Success: ${response.paymentId}');
    try {
      _onSuccessCallback?.call();
    } catch (e) {
      print('onSuccess callback threw: $e');
    }
    _paymentCompleter?.complete(true);
    _paymentCompleter = null;
    _onSuccessCallback = null;
  }

  static void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment Error: ${response.code} - ${response.message}');
    _paymentCompleter?.complete(false);
    _paymentCompleter = null;
    _onSuccessCallback = null;
  }

  static void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
    _paymentCompleter?.complete(true);
    _paymentCompleter = null;
    _onSuccessCallback = null;
  }

  static Future<bool> processPayment({
    required BuildContext context,
    required int amount,
    required String orderId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    VoidCallback? onSuccess,
  }) async {
    try {
      print('Starting payment process for order $orderId, amount: $amount');
      _paymentCompleter = Completer<bool>();
      _onSuccessCallback = onSuccess;

      // Ensure Razorpay is initialized for mobile
      if (!kIsWeb && _razorpay == null) {
        print('Initializing Razorpay for mobile');
        _razorpay = Razorpay();
        _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
        _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
        _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      }

      final options = {
        'key': RazorpayConfig.keyId,
        'amount': amount * 100, // Convert to paise
        'name': RazorpayConfig.merchantName,
        'description':
            '${RazorpayConfig.merchantDescription} - Order #$orderId',
        'order_id': '', // You can generate this from your backend
        'prefill': {
          'contact': customerPhone,
          'email': customerEmail,
          'name': customerName,
        },
        'theme': {
          'color':
              '#${Theme.of(context).primaryColor.value.toRadixString(16).substring(2)}',
        }
      };

      if (kIsWeb) {
        // Web implementation (similar to your cart_screen.dart)
        print('Opening Razorpay for web');
        _openRazorpayWeb(options);
      } else {
        // Mobile implementation
        print('Opening Razorpay for mobile with options: $options');
        _razorpay!.open(options);
      }

      // Wait for payment result
      final result = await _paymentCompleter!.future;

      if (!result && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment was cancelled or failed'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return result;
    } catch (e) {
      print('Payment error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  static void _openRazorpayWeb(Map<String, dynamic> options) {
    try {
      print('Opening Razorpay web with options: $options');

      // Add handler for payment success
      final webOptions = Map<String, dynamic>.from(options);
      webOptions['handler'] = js.allowInterop((response) {
        print('Payment success response: $response');
        _handlePaymentSuccess(PaymentSuccessResponse(
          response['razorpay_payment_id'] ?? '',
          response['razorpay_order_id'] ?? '',
          response['razorpay_signature'] ?? '',
          null,
        ));
      });

      // Add modal dismiss handler
      webOptions['modal'] = {
        'ondismiss': js.allowInterop(() {
          print('Payment modal dismissed');
          _paymentCompleter?.complete(false);
          _paymentCompleter = null;
        })
      };

      // Create Razorpay instance and open
      final ctor = js.context['Razorpay'];
      if (ctor == null) {
        print('Razorpay constructor not found');
        _paymentCompleter?.complete(false);
        _paymentCompleter = null;
        return;
      }

      final instance = js.JsObject(ctor, [js.JsObject.jsify(webOptions)]);
      instance.callMethod('open');
    } catch (e) {
      print('Error opening Razorpay web: $e');
      _paymentCompleter?.complete(false);
      _paymentCompleter = null;
    }
  }

  static void dispose() {
    if (!kIsWeb) {
      _razorpay?.clear();
    }
  }
}
