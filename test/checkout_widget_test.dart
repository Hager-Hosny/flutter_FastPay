import 'package:fastpay_sdk/src/models/customer.dart';
import 'package:fastpay_sdk/src/models/session.dart';
import 'package:fastpay_sdk/src/models/transaction.dart';
import 'package:fastpay_sdk/src/models/card_details.dart';
import 'package:fastpay_sdk/src/services/payment_service.dart';
import 'package:fastpay_sdk/src/ui/fastpay_checkout_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('checkout page shows form after session creation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FastPayCheckoutPage(
          amount: 150,
          currency: 'EGP',
          paymentService: ImmediatePaymentService(),
        ),
      ),
    );

    expect(find.text('Creating secure session'), findsOneWidget);

    await tester.pump();
    await tester.pump();

    expect(find.text('Card details'), findsOneWidget);
    expect(find.text('Pay now'), findsOneWidget);
  });
}

class ImmediatePaymentService implements PaymentService {
  @override
  Future<Session> createSession({
    required double amount,
    required String currency,
    Customer? customer,
    String? merchantOrderId,
    Map<String, dynamic>? metadata,
    String? redirectUrl,
    String? callbackUrl,
    String source = 'sdk',
  }) async {
    return Session(
      sessionId: 'sess_123',
      status: 'created',
      amount: amount,
      currency: currency,
      customer: customer,
    );
  }

  @override
  Future<Transaction> getTransactionStatus({
    String? paymentId,
    String? transactionId,
    String? sessionId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Transaction> processTransaction({
    required String sessionId,
    required CardDetails cardDetails,
    double? amount,
    String? currency,
    Customer? customer,
    String paymentMethod = 'card',
    bool? saveCard,
    String? merchantOrderId,
    Map<String, dynamic>? metadata,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Transaction> retryPayment({
    String? paymentId,
    String? transactionId,
    String? sessionId,
    CardDetails? cardDetails,
    String paymentMethod = 'card',
    Map<String, dynamic>? metadata,
  }) async {
    throw UnimplementedError();
  }
}
