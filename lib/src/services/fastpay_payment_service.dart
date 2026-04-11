import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/card_details.dart';
import '../models/customer.dart';
import '../models/session.dart';
import '../models/transaction.dart';
import '../utils/json_utils.dart';
import 'payment_service.dart';

/// API-backed implementation of [PaymentService].
class FastPayPaymentService implements PaymentService {
  /// Creates a [FastPayPaymentService].
  FastPayPaymentService({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Session> createSession({
    required double amount,
    required String currency,
    Customer? customer,
    String? merchantOrderId,
    Map<String, dynamic>? metadata,
    String? redirectUrl,
    String? callbackUrl,
    String source = 'sdk',
  }) async {
    final Map<String, dynamic> response = await _apiClient.post(
      _apiClient.config.endpoints.createSession,
      body: <String, dynamic>{
        'amount': amount,
        'currency': currency,
        'merchant_order_id': merchantOrderId,
        'customer': customer?.toJson(),
        'metadata': metadata,
        'redirect_url': redirectUrl,
        'callback_url': callbackUrl,
        'source': source,
      }..removeWhere((String _, dynamic value) => value == null),
    );

    final Session session = Session.fromJson(_extractPayload(response));
    if (session.sessionId == null || session.sessionId!.isEmpty) {
      throw ApiException.parsing(
        'FastPay createSession response did not include session_id.',
        details: response,
      );
    }

    return session;
  }

  @override
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
  }) async {
    final Map<String, dynamic> response = await _apiClient.post(
      _apiClient.config.endpoints.processTransaction,
      body: <String, dynamic>{
        'session_id': sessionId,
        'payment_method': paymentMethod,
        'merchant_order_id': merchantOrderId,
        'amount': amount,
        'currency': currency,
        'customer': customer?.toJson(),
        'save_card': saveCard,
        'metadata': metadata,
        'card_details': <String, dynamic>{
          'number': cardDetails.number,
          'expiry_month': cardDetails.expiryMonth,
          'expiry_year': cardDetails.expiryYear,
          'cvv': cardDetails.cvv,
          'cardholder_name': cardDetails.cardholderName,
          'token': cardDetails.token,
        }..removeWhere((String _, dynamic value) => value == null),
      }..removeWhere((String _, dynamic value) => value == null),
    );

    return _parseTransaction(response);
  }

  @override
  Future<Transaction> getTransactionStatus({
    String? paymentId,
    String? transactionId,
    String? sessionId,
  }) async {
    if (paymentId != null && paymentId.isNotEmpty) {
      final String path = _apiClient.config.endpoints.paymentDetailsTemplate
          .replaceFirst('{payment_id}', paymentId);
      final Map<String, dynamic> response = await _apiClient.get(path);
      return _parseTransaction(response);
    }

    final Map<String, dynamic> response = await _apiClient.post(
      _apiClient.config.endpoints.getTransactionStatus,
      body: <String, dynamic>{
        'transaction_id': transactionId,
        'session_id': sessionId,
      }..removeWhere((String _, dynamic value) => value == null),
    );

    return _parseTransaction(response);
  }

  @override
  Future<Transaction> retryPayment({
    String? paymentId,
    String? transactionId,
    String? sessionId,
    CardDetails? cardDetails,
    String paymentMethod = 'card',
    Map<String, dynamic>? metadata,
  }) async {
    final Map<String, dynamic> requestBody = <String, dynamic>{
      'transaction_id': transactionId,
      'session_id': sessionId,
      'payment_method': paymentMethod,
      'card_details': cardDetails == null
          ? null
          : <String, dynamic>{
              'number': cardDetails.number,
              'expiry_month': cardDetails.expiryMonth,
              'expiry_year': cardDetails.expiryYear,
              'cvv': cardDetails.cvv,
              'cardholder_name': cardDetails.cardholderName,
              'token': cardDetails.token,
            },
      'metadata': metadata,
    }..removeWhere((String _, dynamic value) => value == null);

    final Map<String, dynamic> response;
    if (paymentId != null && paymentId.isNotEmpty) {
      final String path = _apiClient.config.endpoints.retryPaymentTemplate
          .replaceFirst('{payment_id}', paymentId);
      response = await _apiClient.post(path, body: requestBody);
    } else {
      response = await _apiClient.post(
        _apiClient.config.endpoints.retryPayment,
        body: requestBody,
      );
    }

    return _parseTransaction(response);
  }

  Transaction _parseTransaction(Map<String, dynamic> response) {
    final Map<String, dynamic> payload = _extractPayload(response);
    final String? envelopeMessage = asString(response['message']);
    final Map<String, dynamic> mergedPayload = <String, dynamic>{
      ...payload,
      if (!payload.containsKey('message') && envelopeMessage != null)
        'message': envelopeMessage,
    };

    final Transaction transaction = Transaction.fromJson(mergedPayload);
    if ((transaction.transactionId == null ||
            transaction.transactionId!.isEmpty) &&
        (transaction.paymentId == null || transaction.paymentId!.isEmpty) &&
        (transaction.sessionId == null || transaction.sessionId!.isEmpty)) {
      throw ApiException.parsing(
        'FastPay transaction response did not include any stable identifier.',
        details: response,
      );
    }

    return transaction;
  }

  Map<String, dynamic> _extractPayload(Map<String, dynamic> response) {
    final Map<String, dynamic>? data = asJsonMap(response['data']);
    if (data != null) {
      return data;
    }

    return response;
  }
}
