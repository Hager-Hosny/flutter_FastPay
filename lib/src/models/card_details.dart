import 'package:collection/collection.dart';

import '../utils/json_utils.dart';

/// Card information collected for a payment attempt or returned as safe metadata.
class CardDetails {
  /// Creates a [CardDetails] model.
  const CardDetails({
    this.number,
    this.expiryMonth,
    this.expiryYear,
    this.cvv,
    this.cardholderName,
    this.last4,
    this.brand,
    this.token,
    this.metadata = const <String, dynamic>{},
  });

  /// Full card number.
  ///
  /// This is intended only for in-memory request construction and must not be
  /// persisted by merchants.
  final String? number;

  /// Expiration month as a two-digit or numeric month value.
  final int? expiryMonth;

  /// Four-digit expiration year.
  final int? expiryYear;

  /// Card verification value.
  ///
  /// This is intended only for in-memory request construction and must not be
  /// persisted by merchants.
  final String? cvv;

  /// Cardholder name.
  final String? cardholderName;

  /// Last four digits returned by the backend when available.
  final String? last4;

  /// Card brand such as Visa or Mastercard.
  final String? brand;

  /// Optional tokenized card reference when the backend supports vaulting.
  final String? token;

  /// Extensible metadata for backend-specific card attributes.
  final Map<String, dynamic> metadata;

  /// Builds a [CardDetails] from JSON.
  factory CardDetails.fromJson(Map<String, dynamic> json) {
    return CardDetails(
      number: asString(json['number']),
      expiryMonth: asInt(json['expiry_month'] ?? json['expiryMonth']),
      expiryYear: asInt(json['expiry_year'] ?? json['expiryYear']),
      cvv: asString(json['cvv']),
      cardholderName: asString(
        json['cardholder_name'] ?? json['cardholderName'],
      ),
      last4: asString(json['last4'] ?? json['masked_pan_suffix']),
      brand: asString(json['brand'] ?? json['card_brand']),
      token: asString(json['token'] ?? json['card_token']),
      metadata: asJsonMap(json['metadata']) ?? const <String, dynamic>{},
    );
  }

  /// Converts this model into JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'number': number,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'cvv': cvv,
      'cardholder_name': cardholderName,
      'last4': last4,
      'brand': brand,
      'token': token,
      'metadata': metadata.isEmpty ? null : metadata,
    };
  }

  /// Safe JSON payload that excludes sensitive values.
  Map<String, dynamic> toSafeJson() {
    return <String, dynamic>{
      'cardholder_name': cardholderName,
      'last4': last4,
      'brand': brand,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'token': token,
      'metadata': metadata.isEmpty ? null : metadata,
    };
  }

  /// Returns a copy with the provided overrides.
  CardDetails copyWith({
    String? number,
    int? expiryMonth,
    int? expiryYear,
    String? cvv,
    String? cardholderName,
    String? last4,
    String? brand,
    String? token,
    Map<String, dynamic>? metadata,
  }) {
    return CardDetails(
      number: number ?? this.number,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cvv: cvv ?? this.cvv,
      cardholderName: cardholderName ?? this.cardholderName,
      last4: last4 ?? this.last4,
      brand: brand ?? this.brand,
      token: token ?? this.token,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    const DeepCollectionEquality deepEquality = DeepCollectionEquality();
    return identical(this, other) ||
        other is CardDetails &&
            other.number == number &&
            other.expiryMonth == expiryMonth &&
            other.expiryYear == expiryYear &&
            other.cvv == cvv &&
            other.cardholderName == cardholderName &&
            other.last4 == last4 &&
            other.brand == brand &&
            other.token == token &&
            deepEquality.equals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    const DeepCollectionEquality deepEquality = DeepCollectionEquality();
    return Object.hash(
      number,
      expiryMonth,
      expiryYear,
      cvv,
      cardholderName,
      last4,
      brand,
      token,
      deepEquality.hash(metadata),
    );
  }
}
