import '../utils/json_utils.dart';

class RefundResult {
  const RefundResult({
    this.refundId,
    this.transactionId,
    this.merchantId,
    this.paymentId,
    this.providerReference,
    this.amount,
    this.currency,
    this.status,
    this.reason,
    this.metadata = const <String, dynamic>{},
    this.requestedAt,
    this.completedAt,
    this.rawData = const <String, dynamic>{},
  });

  final int? refundId;
  final int? transactionId;
  final int? merchantId;
  final String? paymentId;
  final String? providerReference;
  final String? amount;
  final String? currency;
  final String? status;
  final String? reason;
  final Map<String, dynamic> metadata;
  final String? requestedAt;
  final String? completedAt;
  final Map<String, dynamic> rawData;

  factory RefundResult.fromJson(Map<String, dynamic> json) {
    return RefundResult(
      refundId: asInt(json['refund_id']),
      transactionId: asInt(json['transaction_id']),
      merchantId: asInt(json['merchant_id']),
      paymentId: asString(json['payment_id']),
      providerReference: asString(json['provider_reference']),
      amount: asString(json['amount']),
      currency: asString(json['currency']),
      status: asString(json['status']),
      reason: asString(json['reason']),
      metadata: asJsonMap(json['metadata']) ?? const <String, dynamic>{},
      requestedAt: asString(json['requested_at']),
      completedAt: asString(json['completed_at']),
      rawData: json,
    );
  }
}
