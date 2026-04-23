import 'package:fastpay_sdk/src/flow/fastpay_flow_controller.dart';
import 'package:fastpay_sdk/src/flow/fastpay_flow_state.dart';
import 'package:fastpay_sdk/src/models/cancel_payment_result.dart';
import 'package:fastpay_sdk/src/models/customer.dart';
import 'package:fastpay_sdk/src/models/payment_details.dart';
import 'package:fastpay_sdk/src/models/payment_method.dart';
import 'package:fastpay_sdk/src/models/payment_session.dart';
import 'package:fastpay_sdk/src/models/retry_payment_result.dart';
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
      customer: const Customer(
        name: 'Elmira',
        email: 'elmira@example.com',
        phone: '+201000000000',
      ),
      merchantOrderId: 'ORD-10001',
      callbackUrl: 'https://merchant.example.com/api/fastpay/callback',
    );

    expect(controller.state.stage, FastPayFlowStage.ready);
    expect(controller.state.session?.paymentId, 'pay_123');

    final result = await controller.checkStatus();

    expect(result.isSuccess, isTrue);
    expect(controller.state.stage, FastPayFlowStage.success);
    expect(controller.state.payment?.paymentId, 'pay_123');
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
      customer: const Customer(
        name: 'Failure Case',
        email: 'failure@test.dev',
        phone: '+201000000000',
      ),
      merchantOrderId: 'ORD-10002',
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
      reference: 'ref_123',
      checkoutUrl: 'https://merchant.example.com/checkout/pay_123',
      status: 'initiated',
    );
  }

  @override
  Future<PaymentDetails> getPayment({required String paymentId}) async {
    if (throwOnGetPayment) {
      throw StateError('Payment lookup failed');
    }

    return PaymentDetails(
      paymentId: paymentId,
      id: 11,
      externalReference: paymentId,
      status: 'completed',
      amount: '150.00',
      currency: 'EGP',
    );
  }

  @override
  Future<RetryPaymentResult> retryPayment({
    required String paymentId,
    String? paymentMethod,
    String? redirectUrl,
    String? callbackUrl,
  }) async {
    return RetryPaymentResult(paymentId: paymentId, status: 'initiated');
  }

  @override
  Future<CancelPaymentResult> cancelPayment({required String paymentId}) async {
    return CancelPaymentResult(paymentId: paymentId, status: 'cancelled');
  }
}
