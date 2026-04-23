import '../utils/json_utils.dart';

class PayoutResult {
  const PayoutResult({
    this.id,
    this.merchantId,
    this.amount,
    this.currency,
    this.status,
    this.rawData = const <String, dynamic>{},
  });

  final int? id;
  final int? merchantId;
  final String? amount;
  final String? currency;
  final String? status;
  final Map<String, dynamic> rawData;

  factory PayoutResult.fromJson(Map<String, dynamic> json) {
    return PayoutResult(
      id: asInt(json['id']),
      merchantId: asInt(json['merchant_id']),
      amount: asString(json['amount']),
      currency: asString(json['currency']),
      status: asString(json['status']),
      rawData: json,
    );
  }
}
