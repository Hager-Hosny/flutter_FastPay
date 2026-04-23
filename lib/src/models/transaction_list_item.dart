import '../utils/json_utils.dart';
import 'customer.dart';

class TransactionListItem {
  const TransactionListItem({
    this.paymentId,
    this.id,
    this.externalReference,
    this.providerReference,
    this.originType,
    this.originId,
    this.customer,
    this.amount,
    this.currency,
    this.status,
    this.paymentMethod,
    this.metadata = const <String, dynamic>{},
    this.initiatedAt,
    this.completedAt,
    this.failedAt,
    this.paymentMethodFailed,
    this.redirectUrl,
    this.callbackUrl,
    this.rawData = const <String, dynamic>{},
  });

  final String? paymentId;
  final int? id;
  final String? externalReference;
  final String? providerReference;
  final String? originType;
  final String? originId;
  final Customer? customer;
  final String? amount;
  final String? currency;
  final String? status;
  final String? paymentMethod;
  final Map<String, dynamic> metadata;
  final String? initiatedAt;
  final String? completedAt;
  final String? failedAt;
  final String? paymentMethodFailed;
  final String? redirectUrl;
  final String? callbackUrl;
  final Map<String, dynamic> rawData;

  factory TransactionListItem.fromJson(Map<String, dynamic> json) {
    return TransactionListItem(
      paymentId: asString(json['payment_id']),
      id: asInt(json['id']),
      externalReference: asString(json['external_reference']),
      providerReference: asString(json['provider_reference']),
      originType: asString(json['origin_type']),
      originId: asString(json['origin_id']),
      customer: json['customer'] is Map<String, dynamic>
          ? Customer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      amount: asString(json['amount']),
      currency: asString(json['currency']),
      status: asString(json['status']),
      paymentMethod: asString(json['payment_method']),
      metadata: asJsonMap(json['metadata']) ?? const <String, dynamic>{},
      initiatedAt: asString(json['initiated_at']),
      completedAt: asString(json['completed_at']),
      failedAt: asString(json['failed_at']),
      paymentMethodFailed: asString(json['payment_method_failed']),
      redirectUrl: asString(json['redirect_url']),
      callbackUrl: asString(json['callback_url']),
      rawData: json,
    );
  }
}
