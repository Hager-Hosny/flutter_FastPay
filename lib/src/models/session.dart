import 'package:collection/collection.dart';

import '../utils/json_utils.dart';
import 'customer.dart';

/// A payment session created before transaction processing begins.
class Session {
  /// Creates a [Session] model.
  const Session({
    this.sessionId,
    this.reference,
    this.status,
    this.amount,
    this.currency,
    this.merchantOrderId,
    this.paymentId,
    this.checkoutUrl,
    this.redirectUrl,
    this.callbackUrl,
    this.customer,
    this.metadata = const <String, dynamic>{},
    this.rawData = const <String, dynamic>{},
  });

  /// Payment session identifier returned by the backend.
  ///
  /// The current FastPay backend returns `payment_id` rather than a dedicated
  /// `session_id`. This field is kept as a compatibility alias.
  final String? sessionId;

  /// Merchant-visible reference associated with the payment session.
  final String? reference;

  /// Current session status.
  ///
  /// TODO(Postman): confirm the full status enum.
  final String? status;

  /// Requested amount for the session.
  final double? amount;

  /// ISO currency code.
  final String? currency;

  /// Merchant order reference.
  final String? merchantOrderId;

  /// Linked backend payment identifier.
  ///
  /// TODO(Postman): confirm whether the create-session response returns a
  /// dedicated `payment_id` field.
  final String? paymentId;

  /// Hosted checkout or redirect URL when provided by the backend.
  final String? checkoutUrl;

  /// Merchant redirect URL associated with this session.
  final String? redirectUrl;

  /// Merchant callback URL associated with this session.
  final String? callbackUrl;

  /// Customer associated with the session.
  final Customer? customer;

  /// Extensible metadata returned by the backend.
  final Map<String, dynamic> metadata;

  /// Raw typed response payload for fields not modeled yet.
  final Map<String, dynamic> rawData;

  /// Builds a [Session] instance from a JSON map.
  factory Session.fromJson(Map<String, dynamic> json) {
    final String? paymentId = asString(json['payment_id'] ?? json['id']);
    return Session(
      sessionId: asString(json['session_id']) ?? paymentId,
      reference: asString(json['reference']),
      status: asString(json['status']),
      amount: asDouble(json['amount']),
      currency: asString(json['currency']),
      merchantOrderId: asString(
        json['merchant_order_id'] ?? json['merchantOrderId'],
      ),
      paymentId: paymentId,
      checkoutUrl: asString(
        json['checkout_url'] ?? json['hosted_url'] ?? json['redirect_url'],
      ),
      redirectUrl: asString(json['redirect_url']),
      callbackUrl: asString(json['callback_url']),
      customer: json['customer'] is Map<String, dynamic>
          ? Customer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      metadata: asJsonMap(json['metadata']) ?? const <String, dynamic>{},
      rawData: json,
    );
  }

  /// Converts this model into a JSON-ready map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'session_id': sessionId,
      'reference': reference,
      'status': status,
      'amount': amount,
      'currency': currency,
      'merchant_order_id': merchantOrderId,
      'payment_id': paymentId,
      'checkout_url': checkoutUrl,
      'redirect_url': redirectUrl,
      'callback_url': callbackUrl,
      'customer': customer?.toJson(),
      'metadata': metadata.isEmpty ? null : metadata,
    };
  }

  /// Returns a copy of this model with the provided overrides.
  Session copyWith({
    String? sessionId,
    String? reference,
    String? status,
    double? amount,
    String? currency,
    String? merchantOrderId,
    String? paymentId,
    String? checkoutUrl,
    String? redirectUrl,
    String? callbackUrl,
    Customer? customer,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? rawData,
  }) {
    return Session(
      sessionId: sessionId ?? this.sessionId,
      reference: reference ?? this.reference,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      merchantOrderId: merchantOrderId ?? this.merchantOrderId,
      paymentId: paymentId ?? this.paymentId,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      callbackUrl: callbackUrl ?? this.callbackUrl,
      customer: customer ?? this.customer,
      metadata: metadata ?? this.metadata,
      rawData: rawData ?? this.rawData,
    );
  }

  @override
  bool operator ==(Object other) {
    const DeepCollectionEquality deepEquality = DeepCollectionEquality();
    return identical(this, other) ||
        other is Session &&
            other.sessionId == sessionId &&
            other.reference == reference &&
            other.status == status &&
            other.amount == amount &&
            other.currency == currency &&
            other.merchantOrderId == merchantOrderId &&
            other.paymentId == paymentId &&
            other.checkoutUrl == checkoutUrl &&
            other.redirectUrl == redirectUrl &&
            other.callbackUrl == callbackUrl &&
            other.customer == customer &&
            deepEquality.equals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    const DeepCollectionEquality deepEquality = DeepCollectionEquality();
    return Object.hash(
      sessionId,
      reference,
      status,
      amount,
      currency,
      merchantOrderId,
      paymentId,
      checkoutUrl,
      redirectUrl,
      callbackUrl,
      customer,
      deepEquality.hash(metadata),
    );
  }
}
