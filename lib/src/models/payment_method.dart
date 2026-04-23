import '../utils/json_utils.dart';

class PaymentMethod {
  const PaymentMethod({this.code, this.name});

  final String? code;
  final String? name;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      code: asString(json['code']),
      name: asString(json['name']),
    );
  }
}
