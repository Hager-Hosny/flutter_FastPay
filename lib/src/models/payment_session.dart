import '../utils/json_utils.dart';

class PaymentSession {
  const PaymentSession({
    this.paymentId,
    this.reference,
    this.status,
    this.checkoutUrl,
    this.rawData = const <String, dynamic>{},
  });

  final String? paymentId;
  final String? reference;
  final String? status;
  final String? checkoutUrl;
  final Map<String, dynamic> rawData;

  factory PaymentSession.fromJson(Map<String, dynamic> json) {
    return PaymentSession(
      paymentId: asString(json['payment_id']),
      reference: asString(json['reference']),
      status: asString(json['status']),
      checkoutUrl: asString(json['checkout_url']),
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'payment_id': paymentId,
      'reference': reference,
      'status': status,
      'checkout_url': checkoutUrl,
    }..removeWhere((String _, dynamic value) => value == null);
  }
}
