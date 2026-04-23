import '../utils/json_utils.dart';

class CancelPaymentResult {
  const CancelPaymentResult({
    this.paymentId,
    this.status,
    this.cancelledAt,
    this.rawData = const <String, dynamic>{},
  });

  final String? paymentId;
  final String? status;
  final String? cancelledAt;
  final Map<String, dynamic> rawData;

  factory CancelPaymentResult.fromJson(Map<String, dynamic> json) {
    return CancelPaymentResult(
      paymentId: asString(json['payment_id']),
      status: asString(json['status']),
      cancelledAt: asString(json['cancelled_at']),
      rawData: json,
    );
  }
}
