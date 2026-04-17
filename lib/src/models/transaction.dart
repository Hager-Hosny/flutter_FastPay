import 'package:collection/collection.dart';

import '../utils/json_utils.dart';
import 'card_details.dart';
import 'customer.dart';

/// A payment transaction created from a FastPay session.
class Transaction {
  /// Creates a [Transaction] model.
  const Transaction({
    this.transactionId,
    this.sessionId,
    this.status,
    this.paymentId,
    this.externalReference,
    this.providerReference,
    this.originType,
    this.originId,
    this.paymentMethod,
    this.initiatedAt,
    this.completedAt,
    this.failedAt,
    this.message,
    this.amount,
    this.currency,
    this.customer,
    this.cardDetails,
    this.metadata = const <String, dynamic>{},
    this.rawData = const <String, dynamic>{},
  });

  /// Transaction identifier returned by the backend.
  final String? transactionId;

  /// Parent session identifier for this transaction.
  final String? sessionId;

  /// Current transaction status.
  ///
  /// TODO(Postman): confirm all transaction lifecycle values.
  final String? status;

  /// Linked payment identifier when available.
  final String? paymentId;

  /// External merchant-facing payment reference.
  final String? externalReference;

  /// Provider-facing payment reference.
  final String? providerReference;

  /// Original entity type that initiated the payment.
  final String? originType;

  /// Original entity id that initiated the payment.
  final String? originId;

  /// Payment method used by the payment.
  final String? paymentMethod;

  /// Payment creation timestamp.
  final String? initiatedAt;

  /// Payment completion timestamp.
  final String? completedAt;

  /// Payment failure timestamp.
  final String? failedAt;

  /// Human-readable gateway or backend message.
  final String? message;

  /// Transaction amount.
  final double? amount;

  /// ISO currency code.
  final String? currency;

  /// Customer snapshot associated with the transaction.
  final Customer? customer;

  /// Safe card metadata associated with the transaction.
  final CardDetails? cardDetails;

  /// Extensible backend-specific metadata.
  final Map<String, dynamic> metadata;

  /// Raw typed response payload for fields not modeled yet.
  final Map<String, dynamic> rawData;

  /// Builds a [Transaction] instance from a JSON map.
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionId: asString(json['transaction_id'] ?? json['id']),
      sessionId: asString(json['session_id']),
      status: asString(json['status']),
      paymentId: asString(json['payment_id'] ?? json['paymentId']),
      externalReference: asString(
        json['external_reference'] ?? json['externalReference'],
      ),
      providerReference: asString(
        json['provider_reference'] ?? json['providerReference'],
      ),
      originType: asString(json['origin_type'] ?? json['originType']),
      originId: asString(json['origin_id'] ?? json['originId']),
      paymentMethod: asString(
        json['payment_method'] ?? json['paymentMethod'],
      ),
      initiatedAt: asString(json['initiated_at'] ?? json['initiatedAt']),
      completedAt: asString(json['completed_at'] ?? json['completedAt']),
      failedAt: asString(json['failed_at'] ?? json['failedAt']),
      message: asString(json['message'] ?? json['description']),
      amount: asDouble(json['amount']),
      currency: asString(json['currency']),
      customer: json['customer'] is Map<String, dynamic>
          ? Customer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      cardDetails: json['card_details'] is Map<String, dynamic>
          ? CardDetails.fromJson(json['card_details'] as Map<String, dynamic>)
          : null,
      metadata: asJsonMap(json['metadata']) ?? const <String, dynamic>{},
      rawData: json,
    );
  }

  /// Converts this model into a JSON-ready map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'transaction_id': transactionId,
      'session_id': sessionId,
      'status': status,
      'payment_id': paymentId,
      'external_reference': externalReference,
      'provider_reference': providerReference,
      'origin_type': originType,
      'origin_id': originId,
      'payment_method': paymentMethod,
      'initiated_at': initiatedAt,
      'completed_at': completedAt,
      'failed_at': failedAt,
      'message': message,
      'amount': amount,
      'currency': currency,
      'customer': customer?.toJson(),
      'card_details': cardDetails?.toSafeJson(),
      'metadata': metadata.isEmpty ? null : metadata,
    };
  }

  /// Returns a copy of this model with the provided overrides.
  Transaction copyWith({
    String? transactionId,
    String? sessionId,
    String? status,
    String? paymentId,
    String? externalReference,
    String? providerReference,
    String? originType,
    String? originId,
    String? paymentMethod,
    String? initiatedAt,
    String? completedAt,
    String? failedAt,
    String? message,
    double? amount,
    String? currency,
    Customer? customer,
    CardDetails? cardDetails,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? rawData,
  }) {
    return Transaction(
      transactionId: transactionId ?? this.transactionId,
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      paymentId: paymentId ?? this.paymentId,
      externalReference: externalReference ?? this.externalReference,
      providerReference: providerReference ?? this.providerReference,
      originType: originType ?? this.originType,
      originId: originId ?? this.originId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      initiatedAt: initiatedAt ?? this.initiatedAt,
      completedAt: completedAt ?? this.completedAt,
      failedAt: failedAt ?? this.failedAt,
      message: message ?? this.message,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      customer: customer ?? this.customer,
      cardDetails: cardDetails ?? this.cardDetails,
      metadata: metadata ?? this.metadata,
      rawData: rawData ?? this.rawData,
    );
  }

  @override
  bool operator ==(Object other) {
    const DeepCollectionEquality deepEquality = DeepCollectionEquality();
    return identical(this, other) ||
        other is Transaction &&
            other.transactionId == transactionId &&
            other.sessionId == sessionId &&
            other.status == status &&
            other.paymentId == paymentId &&
            other.externalReference == externalReference &&
            other.providerReference == providerReference &&
            other.originType == originType &&
            other.originId == originId &&
            other.paymentMethod == paymentMethod &&
            other.initiatedAt == initiatedAt &&
            other.completedAt == completedAt &&
            other.failedAt == failedAt &&
            other.message == message &&
            other.amount == amount &&
            other.currency == currency &&
            other.customer == customer &&
            other.cardDetails == cardDetails &&
            deepEquality.equals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    const DeepCollectionEquality deepEquality = DeepCollectionEquality();
    return Object.hash(
      transactionId,
      sessionId,
      status,
      paymentId,
      externalReference,
      providerReference,
      originType,
      originId,
      paymentMethod,
      initiatedAt,
      completedAt,
      failedAt,
      message,
      amount,
      currency,
      customer,
      cardDetails,
      deepEquality.hash(metadata),
    );
  }
}
