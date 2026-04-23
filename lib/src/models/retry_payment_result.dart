import '../utils/json_utils.dart';

class RetryPaymentResult {
  const RetryPaymentResult({
    this.paymentId,
    this.status,
    this.checkoutUrl,
    this.retriedAt,
    this.rawData = const <String, dynamic>{},
  });

  final String? paymentId;
  final String? status;
  final String? checkoutUrl;
  final String? retriedAt;
  final Map<String, dynamic> rawData;

  factory RetryPaymentResult.fromJson(Map<String, dynamic> json) {
    return RetryPaymentResult(
      paymentId: asString(json['payment_id']),
      status: asString(json['status']),
      checkoutUrl: asString(json['checkout_url']),
      retriedAt: asString(json['retried_at']),
      rawData: json,
    );
  }
}
