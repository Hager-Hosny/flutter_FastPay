import 'package:flutter/foundation.dart';

import '../models/card_details.dart';
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
    Customer? customer,
    String? merchantOrderId,
    Map<String, dynamic>? metadata,
    String? redirectUrl,
    String? callbackUrl,
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
        metadata: metadata,
        redirectUrl: redirectUrl,
        callbackUrl: callbackUrl,
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

  /// Submits the card form and resolves a typed [PaymentResult].
  Future<PaymentResult> submitCard({
    required CardDetails cardDetails,
    Customer? customer,
    String? merchantOrderId,
    Map<String, dynamic>? metadata,
  }) async {
    final Session? session = _state.session;
    if (session?.sessionId == null || session!.sessionId!.isEmpty) {
      return _fail(
        message: 'FastPay checkout is missing a valid session.',
        transaction: _state.transaction,
      );
    }

    _updateState(
      _state.copyWith(
        stage: FastPayFlowStage.processing,
        clearErrorMessage: true,
        clearResult: true,
      ),
    );

    try {
      final bool retrying =
          _state.result?.isFailure == true &&
          (_state.transaction?.transactionId != null ||
              _state.transaction?.paymentId != null);

      final Transaction transaction = retrying
          ? await _paymentService.retryPayment(
              paymentId: _state.transaction?.paymentId ?? session.paymentId,
              transactionId: _state.transaction?.transactionId,
              sessionId: session.sessionId,
              cardDetails: cardDetails,
              metadata: metadata,
            )
          : await _paymentService.processTransaction(
              sessionId: session.sessionId!,
              cardDetails: cardDetails,
              amount: session.amount,
              currency: session.currency,
              customer: customer ?? session.customer,
              merchantOrderId: merchantOrderId ?? session.merchantOrderId,
              metadata: metadata,
            );

      final Transaction resolvedTransaction = await _resolveStatus(
        transaction,
        session: session,
      );
      final PaymentResult result = _buildResult(
        transaction: resolvedTransaction,
        session: session,
      );

      _updateState(
        _state.copyWith(
          stage: _stageFromResult(result),
          transaction: resolvedTransaction,
          result: result,
          errorMessage: result.errorMessage,
        ),
      );

      return result;
    } catch (error) {
      return _fail(message: error.toString(), transaction: _state.transaction);
    }
  }

  /// Re-checks the latest payment status.
  Future<PaymentResult> checkStatus() async {
    final Transaction? transaction = _state.transaction;
    final Session? session = _state.session;

    if (transaction == null && session == null) {
      return _fail(
        message: 'FastPay status check requires an active payment attempt.',
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
      final Transaction refreshed = await _paymentService.getTransactionStatus(
        paymentId: transaction?.paymentId ?? session?.paymentId,
        transactionId: transaction?.transactionId,
        sessionId: transaction?.sessionId ?? session?.sessionId,
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

  Future<Transaction> _resolveStatus(
    Transaction transaction, {
    required Session session,
  }) async {
    final String normalized = (transaction.status ?? '').toLowerCase();
    if (_successStatuses.contains(normalized) ||
        _failureStatuses.contains(normalized)) {
      return transaction;
    }

    try {
      return await _paymentService.getTransactionStatus(
        paymentId: transaction.paymentId ?? session.paymentId,
        transactionId: transaction.transactionId,
        sessionId: transaction.sessionId ?? session.sessionId,
      );
    } catch (_) {
      return transaction;
    }
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
