import '../models/customer.dart';
import '../models/session.dart';
import '../models/transaction.dart';

/// Contract used by the SDK flow controller to manage payment API calls.
abstract class PaymentService {
  /// Creates a payment session.
  Future<Session> createSession({
    required double amount,
    required String currency,
    required Customer customer,
    required String merchantOrderId,
    required String checkoutUrl,
    required String callbackUrl,
    Map<String, dynamic>? metadata,
    String? redirectUrl,
  });

  /// Fetches the latest payment snapshot.
  Future<Transaction> getPayment({required String paymentId});

  /// Retries a payment after a failed attempt.
  Future<Transaction> retryPayment({
    required String paymentId,
    String? redirectUrl,
    String? callbackUrl,
  });

  /// Cancels an existing payment.
  Future<Transaction> cancelPayment({required String paymentId});
}
