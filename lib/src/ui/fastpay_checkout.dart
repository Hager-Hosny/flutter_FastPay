import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/payment_result.dart';
import 'fastpay_checkout_page.dart';

/// Entry point used to present the built-in FastPay checkout UI.
class FastPayCheckout {
  FastPayCheckout._();

  /// Opens the FastPay checkout flow and returns a typed [PaymentResult].
  static Future<PaymentResult> show(
    BuildContext context, {
    required double amount,
    required String currency,
    Customer? customer,
    String? merchantOrderId,
    Map<String, dynamic>? metadata,
    String? redirectUrl,
    String? callbackUrl,
  }) async {
    final PaymentResult? result = await Navigator.of(context)
        .push<PaymentResult>(
          MaterialPageRoute<PaymentResult>(
            fullscreenDialog: true,
            builder: (_) => FastPayCheckoutPage(
              amount: amount,
              currency: currency,
              customer: customer,
              merchantOrderId: merchantOrderId,
              metadata: metadata,
              redirectUrl: redirectUrl,
              callbackUrl: callbackUrl,
            ),
          ),
        );

    return result ??
        const PaymentResult(
          outcome: PaymentOutcome.failure,
          status: 'cancelled',
          errorMessage: 'Checkout was dismissed before completion.',
        );
  }
}
