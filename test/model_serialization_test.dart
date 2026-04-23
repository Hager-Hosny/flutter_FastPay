import 'package:fastpay_sdk/fastpay_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('payment session model parses backend payload', () {
    final PaymentSession session = PaymentSession.fromJson(<String, dynamic>{
      'payment_id': 'pay_123',
      'reference': 'ref_123',
      'status': 'initiated',
      'checkout_url': 'https://merchant.example.com/checkout/pay_123',
    });

    expect(session.paymentId, 'pay_123');
    expect(session.reference, 'ref_123');
    expect(session.checkoutUrl, contains('pay_123'));
  });

  test('page result parses transaction list items', () {
    final PageResult<TransactionListItem> result =
        PageResult<TransactionListItem>.fromJson(<String, dynamic>{
          'content': <Map<String, dynamic>>[
            <String, dynamic>{
              'payment_id': 'pay_123',
              'status': 'completed',
              'amount': '150.00',
              'currency': 'EGP',
            },
          ],
          'page': 0,
          'size': 10,
          'total_elements': 1,
          'total_pages': 1,
        }, TransactionListItem.fromJson);

    expect(result.content, hasLength(1));
    expect(result.content.single.paymentId, 'pay_123');
    expect(result.totalElements, 1);
  });

  test('copyWith updates customer model values', () {
    const Customer customer = Customer(customerId: 'cust_123', name: 'Original');

    final Customer updated = customer.copyWith(
      name: 'Updated',
      metadata: const <String, dynamic>{'segment': 'vip'},
    );

    expect(updated.name, 'Updated');
    expect(updated.customerId, 'cust_123');
    expect(updated.metadata['segment'], 'vip');
  });
}
