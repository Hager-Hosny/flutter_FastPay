import '../models/payment_result.dart';
import '../models/session.dart';
import '../models/transaction.dart';

/// Internal checkout stages used by the SDK UI.
enum FastPayFlowStage {
  initial,
  creatingSession,
  ready,
  processing,
  success,
  failure,
  pending,
}

/// Immutable state snapshot for the payment flow controller.
class FastPayFlowState {
  /// Creates a [FastPayFlowState].
  const FastPayFlowState({
    required this.stage,
    this.session,
    this.transaction,
    this.result,
    this.errorMessage,
  });

  /// Initial empty flow state.
  const FastPayFlowState.initial()
    : stage = FastPayFlowStage.initial,
      session = null,
      transaction = null,
      result = null,
      errorMessage = null;

  /// Current stage.
  final FastPayFlowStage stage;

  /// Current payment session.
  final Session? session;

  /// Latest transaction snapshot.
  final Transaction? transaction;

  /// Final or latest payment result.
  final PaymentResult? result;

  /// Latest error message.
  final String? errorMessage;

  /// Whether the flow is busy with a network-bound task.
  bool get isBusy =>
      stage == FastPayFlowStage.creatingSession ||
      stage == FastPayFlowStage.processing;

  /// Whether the hosted-checkout state is ready for user interaction.
  bool get canSubmitCard => stage == FastPayFlowStage.ready;

  /// Returns a copy with the provided overrides.
  FastPayFlowState copyWith({
    FastPayFlowStage? stage,
    Object? session = _sentinel,
    Object? transaction = _sentinel,
    Object? result = _sentinel,
    Object? errorMessage = _sentinel,
    bool clearErrorMessage = false,
    bool clearResult = false,
  }) {
    return FastPayFlowState(
      stage: stage ?? this.stage,
      session: identical(session, _sentinel)
          ? this.session
          : session as Session?,
      transaction: identical(transaction, _sentinel)
          ? this.transaction
          : transaction as Transaction?,
      result: clearResult
          ? null
          : identical(result, _sentinel)
          ? this.result
          : result as PaymentResult?,
      errorMessage: clearErrorMessage
          ? null
          : identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();
