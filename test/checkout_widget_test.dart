import 'package:fastpay_sdk/src/models/cancel_payment_result.dart';
import 'package:fastpay_sdk/src/models/customer.dart';
import 'package:fastpay_sdk/src/models/payment_details.dart';
import 'package:fastpay_sdk/src/models/payment_method.dart';
import 'package:fastpay_sdk/src/models/payment_session.dart';
import 'package:fastpay_sdk/src/models/retry_payment_result.dart';
import 'package:fastpay_sdk/src/services/payment_service.dart';
import 'package:fastpay_sdk/src/ui/fastpay_checkout_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'checkout page shows hosted checkout details after session creation',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FastPayCheckoutPage(
            amount: 150,
            currency: 'EGP',
            customer: const Customer(
              name: 'Elmira',
              email: 'elmira@example.com',
              phone: '+201000000000',
            ),
            merchantOrderId: 'ORD-10001',
            callbackUrl: 'https://merchant.example.com/api/fastpay/callback',
            paymentService: ImmediatePaymentService(),
          ),
        ),
      );

      expect(find.text('Creating secure session'), findsOneWidget);

      await tester.pump();
      await tester.pump();

      expect(find.text('Hosted checkout'), findsOneWidget);
      expect(find.text('Check payment status'), findsOneWidget);
      expect(find.textContaining('pay_123'), findsWidgets);
    },
  );
}

class ImmediatePaymentService implements PaymentService {
  @override
  Future<List<PaymentMethod>> listMethods() async => const <PaymentMethod>[];

  @override
  Future<PaymentSession> createSession({
    required double amount,
    required String currency,
    required Customer customer,
    required String merchantOrderId,
    required String callbackUrl,
    Map<String, dynamic>? metadata,
    String? redirectUrl,
  }) async {
    return const PaymentSession(
      paymentId: 'pay_123',
      status: 'initiated',
      checkoutUrl: 'https://merchant.example.com/checkout/pay_123',
    );
  }

  @override
  Future<PaymentDetails> getPayment({required String paymentId}) async {
    throw UnimplementedError();
  }

  @override
  Future<RetryPaymentResult> retryPayment({
    required String paymentId,
    String? paymentMethod,
    String? redirectUrl,
    String? callbackUrl,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CancelPaymentResult> cancelPayment({required String paymentId}) async {
    throw UnimplementedError();
  }
}
