import '../models/cancel_payment_result.dart';
import '../models/customer.dart';
import '../models/payment_details.dart';
import '../models/payment_method.dart';
import '../models/payment_session.dart';
import '../models/retry_payment_result.dart';

abstract class PaymentService {
  Future<List<PaymentMethod>> listMethods();

  Future<PaymentSession> createSession({
    required double amount,
    required String currency,
    required Customer customer,
    required String merchantOrderId,
    required String callbackUrl,
    Map<String, dynamic>? metadata,
    String? redirectUrl,
  });

  Future<PaymentDetails> getPayment({required String paymentId});

  Future<RetryPaymentResult> retryPayment({
    required String paymentId,
    String? paymentMethod,
    String? redirectUrl,
    String? callbackUrl,
  });

  Future<CancelPaymentResult> cancelPayment({required String paymentId});
}
