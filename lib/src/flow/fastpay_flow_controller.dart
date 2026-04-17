import 'package:flutter/foundation.dart';

import '../models/customer.dart';
import '../models/payment_result.dart';
import '../models/session.dart';
import '../models/transaction.dart';
import '../services/payment_service.dart';
import 'fastpay_flow_state.dart';

/// Orchestrates the end-to-end FastPay checkout flow.
class FastPayFlowController extends ChangeNotifier {
  /// Creates a [FastPayFlowController].
  FastPayFlowController({required PaymentService paymentService})
    : _paymentService = paymentService;

  final PaymentService _paymentService;
  FastPayFlowState _state = const FastPayFlowState.initial();

  /// Latest flow state snapshot.
  FastPayFlowState get state => _state;

  /// Starts a checkout by creating a new session.
  Future<void> startCheckout({
    required double amount,
    required String currency,
    required Customer customer,
    required String merchantOrderId,
    required String checkoutUrl,
    required String callbackUrl,
    Map<String, dynamic>? metadata,
    String? redirectUrl,
  }) async {
    _updateState(
      _state.copyWith(
        stage: FastPayFlowStage.creatingSession,
        clearErrorMessage: true,
        clearResult: true,
      ),
    );

    try {
      final Session session = await _paymentService.createSession(
        amount: amount,
        currency: currency,
        customer: customer,
        merchantOrderId: merchantOrderId,
        checkoutUrl: checkoutUrl,
        callbackUrl: callbackUrl,
        metadata: metadata,
        redirectUrl: redirectUrl,
      );

      _updateState(
        _state.copyWith(
          stage: FastPayFlowStage.ready,
          session: session,
          transaction: null,
          clearErrorMessage: true,
          clearResult: true,
        ),
      );
    } catch (error) {
      _fail(message: error.toString(), transaction: null);
      rethrow;
    }
  }

  /// Re-checks the latest payment status.
  Future<PaymentResult> checkStatus() async {
    final Transaction? transaction = _state.transaction;
    final Session? session = _state.session;
    final String? paymentId =
        transaction?.paymentId ?? session?.paymentId ?? session?.sessionId;

    if (paymentId == null || paymentId.isEmpty) {
      return _fail(
        message: 'FastPay status check requires a payment_id.',
        transaction: null,
      );
    }

    _updateState(
      _state.copyWith(
        stage: FastPayFlowStage.processing,
        clearErrorMessage: true,
      ),
    );

    try {
      final Transaction refreshed = await _paymentService.getPayment(
        paymentId: paymentId,
      );

      final PaymentResult result = _buildResult(
        transaction: refreshed,
        session: session,
      );

      _updateState(
        _state.copyWith(
          stage: _stageFromResult(result),
          transaction: refreshed,
          result: result,
          errorMessage: result.errorMessage,
        ),
      );

      return result;
    } catch (error) {
      return _fail(message: error.toString(), transaction: transaction);
    }
  }

  /// Returns the form to a retryable state.
  void prepareRetry() {
    _updateState(
      _state.copyWith(
        stage: FastPayFlowStage.ready,
        clearErrorMessage: true,
        clearResult: true,
      ),
    );
  }

  PaymentResult _buildResult({
    required Transaction transaction,
    required Session? session,
  }) {
    final String status = (transaction.status ?? 'failed').toLowerCase();

    if (_successStatuses.contains(status)) {
      return PaymentResult(
        outcome: PaymentOutcome.success,
        status: transaction.status,
        transaction: transaction,
        session: session,
        rawData: transaction.rawData,
      );
    }

    if (_pendingStatuses.contains(status)) {
      return PaymentResult(
        outcome: PaymentOutcome.pending,
        status: transaction.status,
        errorMessage: transaction.message,
        transaction: transaction,
        session: session,
        rawData: transaction.rawData,
      );
    }

    return PaymentResult(
      outcome: PaymentOutcome.failure,
      status: transaction.status,
      errorMessage: transaction.message ?? 'Payment failed.',
      transaction: transaction,
      session: session,
      rawData: transaction.rawData,
    );
  }

  FastPayFlowStage _stageFromResult(PaymentResult result) {
    switch (result.outcome) {
      case PaymentOutcome.success:
        return FastPayFlowStage.success;
      case PaymentOutcome.pending:
        return FastPayFlowStage.pending;
      case PaymentOutcome.failure:
        return FastPayFlowStage.failure;
    }
  }

  PaymentResult _fail({
    required String message,
    required Transaction? transaction,
  }) {
    final PaymentResult result = PaymentResult(
      outcome: PaymentOutcome.failure,
      status: transaction?.status ?? 'failed',
      errorMessage: message,
      transaction: transaction,
      session: _state.session,
      rawData: transaction?.rawData ?? const <String, dynamic>{},
    );

    _updateState(
      _state.copyWith(
        stage: FastPayFlowStage.failure,
        transaction: transaction,
        result: result,
        errorMessage: message,
      ),
    );

    return result;
  }

  void _updateState(FastPayFlowState value) {
    _state = value;
    notifyListeners();
  }
}

const Set<String> _successStatuses = <String>{
  'success',
  'succeeded',
  'successful',
  'paid',
  'completed',
  'approved',
  'authorized',
};

const Set<String> _pendingStatuses = <String>{
  'pending',
  'processing',
  'submitted',
  'created',
  'initiated',
  'requires_action',
};

const Set<String> _failureStatuses = <String>{
  'failed',
  'failure',
  'declined',
  'canceled',
  'cancelled',
  'rejected',
  'expired',
  'error',
};
