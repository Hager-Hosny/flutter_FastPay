import '../models/card_details.dart';
import '../models/customer.dart';
import '../models/session.dart';
import '../models/transaction.dart';

/// Contract used by the SDK flow controller to manage payment API calls.
abstract class PaymentService {
  /// Creates a payment session.
  Future<Session> createSession({
    required double amount,
    required String currency,
    Customer? customer,
    String? merchantOrderId,
    Map<String, dynamic>? metadata,
    String? redirectUrl,
    String? callbackUrl,
    String source = 'sdk',
  });

  /// Processes a payment transaction for an existing session.
  Future<Transaction> processTransaction({
    required String sessionId,
    required CardDetails cardDetails,
    double? amount,
    String? currency,
    Customer? customer,
    String paymentMethod = 'card',
    bool? saveCard,
    String? merchantOrderId,
    Map<String, dynamic>? metadata,
  });

  /// Fetches the latest transaction status.
  Future<Transaction> getTransactionStatus({
    String? paymentId,
    String? transactionId,
    String? sessionId,
  });

  /// Retries a payment after a failed attempt.
  Future<Transaction> retryPayment({
    String? paymentId,
    String? transactionId,
    String? sessionId,
    CardDetails? cardDetails,
    String paymentMethod = 'card',
    Map<String, dynamic>? metadata,
  });
}
