import '../utils/json_utils.dart';
import 'session.dart';
import 'transaction.dart';

/// High-level payment outcome returned by the SDK.
enum PaymentOutcome { success, failure, pending }

/// A summarized payment outcome returned by the SDK layer.
class PaymentResult {
  /// Creates a [PaymentResult] model.
  const PaymentResult({
    required this.outcome,
    this.status,
    this.errorMessage,
    this.transaction,
    this.session,
    this.rawData = const <String, dynamic>{},
  });

  /// Outcome determined by the SDK flow.
  final PaymentOutcome outcome;

  /// Backend payment status.
  final String? status;

  /// Optional human-readable failure or pending detail.
  final String? errorMessage;

  /// Transaction details associated with the payment result.
  final Transaction? transaction;

  /// Session associated with the payment flow.
  final Session? session;

  /// Extensible raw payload for backend fields not modeled yet.
  final Map<String, dynamic> rawData;

  /// Whether the result is successful.
  bool get isSuccess => outcome == PaymentOutcome.success;

  /// Whether the result is pending.
  bool get isPending => outcome == PaymentOutcome.pending;

  /// Whether the result is a failure.
  bool get isFailure => outcome == PaymentOutcome.failure;

  /// Builds a [PaymentResult] instance from a JSON map.
  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    final String status = asString(json['status']) ?? 'unknown';
    return PaymentResult(
      outcome: _outcomeFromStatus(status, successFlag: asBool(json['success'])),
      status: status,
      errorMessage: asString(json['message'] ?? json['description']),
      transaction: json['transaction'] is Map<String, dynamic>
          ? Transaction.fromJson(json['transaction'] as Map<String, dynamic>)
          : null,
      session: json['session'] is Map<String, dynamic>
          ? Session.fromJson(json['session'] as Map<String, dynamic>)
          : null,
      rawData: json,
    );
  }

  /// Converts this model into a JSON-ready map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'success': isSuccess,
      'outcome': outcome.name,
      'status': status,
      'message': errorMessage,
      'transaction': transaction?.toJson(),
      'session': session?.toJson(),
    };
  }

  /// Returns a copy of this model with the provided overrides.
  PaymentResult copyWith({
    PaymentOutcome? outcome,
    String? status,
    String? errorMessage,
    Transaction? transaction,
    Session? session,
    Map<String, dynamic>? rawData,
  }) {
    return PaymentResult(
      outcome: outcome ?? this.outcome,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      transaction: transaction ?? this.transaction,
      session: session ?? this.session,
      rawData: rawData ?? this.rawData,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PaymentResult &&
            other.outcome == outcome &&
            other.status == status &&
            other.errorMessage == errorMessage &&
            other.transaction == transaction &&
            other.session == session;
  }

  @override
  int get hashCode =>
      Object.hash(outcome, status, errorMessage, transaction, session);
}

PaymentOutcome _outcomeFromStatus(String status, {bool? successFlag}) {
  if (successFlag == true) {
    return PaymentOutcome.success;
  }

  final String normalized = status.toLowerCase();

  if (_successStatuses.contains(normalized)) {
    return PaymentOutcome.success;
  }

  if (_pendingStatuses.contains(normalized)) {
    return PaymentOutcome.pending;
  }

  return PaymentOutcome.failure;
}

const Set<String> _successStatuses = <String>{
  'success',
  'succeeded',
  'successful',
  'paid',
  'completed',
  'authorized',
  'approved',
};

const Set<String> _pendingStatuses = <String>{
  'pending',
  'processing',
  'submitted',
  'created',
  'initiated',
  'requires_action',
};
