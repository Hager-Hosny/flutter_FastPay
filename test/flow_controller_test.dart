import 'package:fastpay_sdk/src/flow/fastpay_flow_controller.dart';
import 'package:fastpay_sdk/src/flow/fastpay_flow_state.dart';
import 'package:fastpay_sdk/src/models/card_details.dart';
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
      customer: const Customer(name: 'Elmira'),
    );

    expect(controller.state.stage, FastPayFlowStage.ready);
    expect(controller.state.session?.sessionId, 'sess_123');

    final result = await controller.submitCard(
      cardDetails: const CardDetails(
        number: '4242424242424242',
        expiryMonth: 12,
        expiryYear: 2030,
        cvv: '123',
        cardholderName: 'Elmira',
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(controller.state.stage, FastPayFlowStage.success);
    expect(controller.state.transaction?.transactionId, 'txn_123');
  });

  test('controller exposes failure state when processing throws', () async {
    final FakePaymentService paymentService = FakePaymentService(
      throwOnProcess: true,
    );
    final FastPayFlowController controller = FastPayFlowController(
      paymentService: paymentService,
    );

    await controller.startCheckout(amount: 150, currency: 'EGP');
    final result = await controller.submitCard(
      cardDetails: const CardDetails(
        number: '4000000000000002',
        expiryMonth: 12,
        expiryYear: 2030,
        cvv: '123',
        cardholderName: 'Failure Case',
      ),
    );

    expect(result.isFailure, isTrue);
    expect(controller.state.stage, FastPayFlowStage.failure);
  });
}

class FakePaymentService implements PaymentService {
  FakePaymentService({this.throwOnProcess = false});

  final bool throwOnProcess;

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
    return Transaction(
      transactionId: transactionId ?? 'txn_123',
      sessionId: sessionId ?? 'sess_123',
      paymentId: paymentId,
      status: 'authorized',
      amount: 150,
      currency: 'EGP',
    );
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
    if (throwOnProcess) {
      throw StateError('Payment declined');
    }

    return const Transaction(
      transactionId: 'txn_123',
      sessionId: 'sess_123',
      status: 'authorized',
      amount: 150,
      currency: 'EGP',
    );
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
    return Transaction(
      transactionId: transactionId ?? 'txn_retry',
      sessionId: sessionId ?? 'sess_123',
      paymentId: paymentId,
      status: 'authorized',
      amount: 150,
      currency: 'EGP',
    );
  }
}
