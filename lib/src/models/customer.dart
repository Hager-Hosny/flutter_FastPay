import 'package:collection/collection.dart';

import '../utils/json_utils.dart';

/// Customer information used by the FastPay SDK.
class Customer {
  /// Creates a [Customer] model.
  const Customer({
    this.customerId,
    this.name,
    this.email,
    this.phone,
    this.metadata = const <String, dynamic>{},
  });

  /// Merchant or gateway customer identifier.
  ///
  /// TODO(Postman): confirm whether the API uses `customer_id`, `id`, or both.
  final String? customerId;

  /// Customer full name.
  final String? name;

  /// Customer email address.
  final String? email;

  /// Customer phone number.
  ///
  /// TODO(Postman): confirm the exact formatting rules returned by the backend.
  final String? phone;

  /// Extensible backend-specific customer metadata.
  final Map<String, dynamic> metadata;

  /// Builds a [Customer] instance from a JSON map.
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: asString(json['customer_id'] ?? json['id']),
      name: asString(json['name']),
      email: asString(json['email']),
      phone: asString(json['phone']),
      metadata: asJsonMap(json['metadata']) ?? const <String, dynamic>{},
    );
  }

  /// Converts this model into a JSON-ready map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'customer_id': customerId,
      'name': name,
      'email': email,
      'phone': phone,
      'metadata': metadata.isEmpty ? null : metadata,
    };
  }

  /// Returns a copy of this model with the provided overrides.
  Customer copyWith({
    String? customerId,
    String? name,
    String? email,
    String? phone,
    Map<String, dynamic>? metadata,
  }) {
    return Customer(
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    const DeepCollectionEquality deepEquality = DeepCollectionEquality();
    return identical(this, other) ||
        other is Customer &&
            other.customerId == customerId &&
            other.name == name &&
            other.email == email &&
            other.phone == phone &&
            deepEquality.equals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    const DeepCollectionEquality deepEquality = DeepCollectionEquality();
    return Object.hash(
      customerId,
      name,
      email,
      phone,
      deepEquality.hash(metadata),
    );
  }
}
