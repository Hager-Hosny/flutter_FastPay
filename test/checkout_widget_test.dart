import 'package:fastpay_sdk/src/models/customer.dart';
import 'package:fastpay_sdk/src/models/session.dart';
import 'package:fastpay_sdk/src/models/transaction.dart';
import 'package:fastpay_sdk/src/services/payment_service.dart';
import 'package:fastpay_sdk/src/ui/fastpay_checkout_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('checkout page shows hosted checkout details after session creation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FastPayCheckoutPage(
          amount: 150,
          currency: 'EGP',
          customer: const Customer(
            name: 'Elmira',
            email: 'elmira@example.com',
          ),
          merchantOrderId: 'ORD-10001',
          checkoutUrl: 'https://merchant.example.com/checkout',
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
  });
}

class ImmediatePaymentService implements PaymentService {
  @override
  Future<Session> createSession({
    required double amount,
    required String currency,
    required Customer customer,
    required String merchantOrderId,
    required String checkoutUrl,
    required String callbackUrl,
    Map<String, dynamic>? metadata,
    String? redirectUrl,
  }) async {
    return Session(
      sessionId: 'pay_123',
      paymentId: 'pay_123',
      status: 'created',
      amount: amount,
      currency: currency,
      customer: customer,
      checkoutUrl: '$checkoutUrl/pay_123',
    );
  }

  @override
  Future<Transaction> getPayment({required String paymentId}) async {
    throw UnimplementedError();
  }

  @override
  Future<Transaction> retryPayment({
    required String paymentId,
    String? redirectUrl,
    String? callbackUrl,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Transaction> cancelPayment({required String paymentId}) async {
    throw UnimplementedError();
  }
}
