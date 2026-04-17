import 'package:fastpay_sdk/fastpay_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session model serializes nested customer and metadata', () {
    const Session session = Session(
      sessionId: 'pay_123',
      status: 'pending',
      amount: 150.0,
      currency: 'EGP',
      merchantOrderId: 'ORD-10001',
      paymentId: 'pay_123',
      reference: 'ref_123',
      customer: Customer(
        customerId: 'cust_123',
        name: 'FastPay User',
        email: 'user@example.com',
        phone: '+201000000000',
      ),
      metadata: <String, dynamic>{'channel': 'mobile'},
    );

    expect(session.toJson()['session_id'], 'pay_123');
    expect(session.toJson()['reference'], 'ref_123');
    expect(session.toJson()['merchant_order_id'], 'ORD-10001');
    expect(session.toJson()['customer'], isA<Map<String, dynamic>>());
  });

  test('transaction and payment result support fromJson and equality', () {
    final PaymentResult result = PaymentResult.fromJson(<String, dynamic>{
      'status': 'authorized',
      'message': 'Approved',
      'transaction': <String, dynamic>{
        'transaction_id': 'txn_123',
        'session_id': 'sess_123',
        'status': 'authorized',
        'amount': 150,
        'currency': 'EGP',
        'card_details': <String, dynamic>{
          'cardholder_name': 'FastPay User',
          'last4': '4242',
          'expiry_month': 12,
          'expiry_year': 2030,
          'brand': 'visa',
        },
      },
    });

    expect(
      result,
      equals(
        PaymentResult(
          outcome: PaymentOutcome.success,
          status: 'authorized',
          errorMessage: 'Approved',
          transaction: const Transaction(
            transactionId: 'txn_123',
            sessionId: 'pay_123',
            paymentId: 'pay_123',
            status: 'authorized',
            amount: 150,
            currency: 'EGP',
            cardDetails: CardDetails(
              cardholderName: 'FastPay User',
              last4: '4242',
              expiryMonth: 12,
              expiryYear: 2030,
              brand: 'visa',
            ),
          ),
        ),
      ),
    );
  });

  test('copyWith updates model values', () {
    const Customer customer = Customer(
      customerId: 'cust_123',
      name: 'Original',
    );

    final Customer updated = customer.copyWith(
      name: 'Updated',
      metadata: const <String, dynamic>{'segment': 'vip'},
    );

    expect(updated.name, 'Updated');
    expect(updated.customerId, 'cust_123');
    expect(updated.metadata['segment'], 'vip');
  });
}
