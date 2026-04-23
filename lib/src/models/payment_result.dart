import 'payment_details.dart';
import 'payment_session.dart';

enum PaymentOutcome { success, failure, pending }

class PaymentResult {
  const PaymentResult({
    required this.outcome,
    this.status,
    this.errorMessage,
    this.payment,
    this.session,
    this.rawData = const <String, dynamic>{},
  });

  final PaymentOutcome outcome;
  final String? status;
  final String? errorMessage;
  final PaymentDetails? payment;
  final PaymentSession? session;
  final Map<String, dynamic> rawData;

  bool get isSuccess => outcome == PaymentOutcome.success;

  bool get isPending => outcome == PaymentOutcome.pending;

  bool get isFailure => outcome == PaymentOutcome.failure;
}
