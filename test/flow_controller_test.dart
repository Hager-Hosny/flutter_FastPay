import 'package:fastpay_sdk/src/flow/fastpay_flow_controller.dart';
import 'package:fastpay_sdk/src/flow/fastpay_flow_state.dart';
import 'package:fastpay_sdk/src/models/customer.dart';
import 'package:fastpay_sdk/src/models/session.dart';
import 'package:fastpay_sdk/src/models/transaction.dart';
import 'package:fastpay_sdk/src/services/payment_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('controller transitions from session creation to success', () async {
    final FakePaymentService paymentService = FakePaymentService();
    final FastPayFlowController controller = FastPayFlowController(
      paymentService: paymentService,
    );

    await controller.startCheckout(
      amount: 150,
      currency: 'EGP',
      customer: const Customer(name: 'Elmira', email: 'elmira@example.com'),
      merchantOrderId: 'ORD-10001',
      checkoutUrl: 'https://merchant.example.com/checkout',
      callbackUrl: 'https://merchant.example.com/api/fastpay/callback',
    );

    expect(controller.state.stage, FastPayFlowStage.ready);
    expect(controller.state.session?.paymentId, 'pay_123');

    final result = await controller.checkStatus();

    expect(result.isSuccess, isTrue);
    expect(controller.state.stage, FastPayFlowStage.success);
    expect(controller.state.transaction?.paymentId, 'pay_123');
  });

  test('controller exposes failure state when status lookup throws', () async {
    final FakePaymentService paymentService = FakePaymentService(
      throwOnGetPayment: true,
    );
    final FastPayFlowController controller = FastPayFlowController(
      paymentService: paymentService,
    );

    await controller.startCheckout(
      amount: 150,
      currency: 'EGP',
      customer: const Customer(name: 'Failure Case', email: 'failure@test.dev'),
      merchantOrderId: 'ORD-10002',
      checkoutUrl: 'https://merchant.example.com/checkout',
      callbackUrl: 'https://merchant.example.com/api/fastpay/callback',
    );
    final result = await controller.checkStatus();

    expect(result.isFailure, isTrue);
    expect(controller.state.stage, FastPayFlowStage.failure);
  });
}

class FakePaymentService implements PaymentService {
  FakePaymentService({this.throwOnGetPayment = false});

  final bool throwOnGetPayment;

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
      reference: 'ref_123',
      checkoutUrl: '$checkoutUrl/pay_123',
      status: 'created',
      amount: amount,
      currency: currency,
      customer: customer,
    );
  }

  @override
  Future<Transaction> getPayment({required String paymentId}) async {
    if (throwOnGetPayment) {
      throw StateError('Payment lookup failed');
    }

    return Transaction(
      transactionId: '11',
      paymentId: paymentId,
      externalReference: paymentId,
      status: 'completed',
      amount: 150,
      currency: 'EGP',
    );
  }

  @override
  Future<Transaction> retryPayment({
    required String paymentId,
    String? redirectUrl,
    String? callbackUrl,
  }) async {
    return Transaction(
      transactionId: '12',
      paymentId: paymentId,
      status: 'pending',
      amount: 150,
      currency: 'EGP',
    );
  }

  @override
  Future<Transaction> cancelPayment({required String paymentId}) async {
    return Transaction(
      transactionId: '13',
      paymentId: paymentId,
      status: 'cancelled',
      amount: 150,
      currency: 'EGP',
    );
  }
}
