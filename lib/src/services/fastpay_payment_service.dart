import '../core/api_client.dart';
import '../core/api_exception.dart';
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
    required Customer customer,
    required String merchantOrderId,
    required String checkoutUrl,
    required String callbackUrl,
    Map<String, dynamic>? metadata,
    String? redirectUrl,
  }) async {
    final Map<String, dynamic> response = await _apiClient.post(
      _apiClient.config.endpoints.createSession,
      body: <String, dynamic>{
        'amount': amount,
        'currency': currency,
        'merchant_order_id': merchantOrderId,
        'customer': customer.toJson(),
        'metadata': metadata == null ? null : <Map<String, dynamic>>[metadata],
        'checkout_url': checkoutUrl,
        'redirect_url': redirectUrl,
        'callback_url': callbackUrl,
      }..removeWhere((String _, dynamic value) => value == null),
    );

    final Session session = Session.fromJson(_extractPayload(response));
    if (session.paymentId == null || session.paymentId!.isEmpty) {
      throw ApiException.parsing(
        'FastPay createSession response did not include payment_id.',
        details: response,
      );
    }

    return session;
  }

  @override
  Future<Transaction> getPayment({required String paymentId}) async {
    final String path = _apiClient.config.endpoints.paymentDetailsTemplate
        .replaceFirst('{payment_id}', paymentId);
    final Map<String, dynamic> response = await _apiClient.get(path);
    return _parsePayment(response, paymentId: paymentId);
  }

  @override
  Future<Transaction> retryPayment({
    required String paymentId,
    String? redirectUrl,
    String? callbackUrl,
  }) async {
    final String path = _apiClient.config.endpoints.retryPaymentTemplate
        .replaceFirst('{payment_id}', paymentId);
    final Map<String, dynamic> response = await _apiClient.post(
      path,
      body: <String, dynamic>{
        'redirect_url': redirectUrl,
        'callback_url': callbackUrl,
      }..removeWhere((String _, dynamic value) => value == null),
    );
    return _parsePayment(response, paymentId: paymentId);
  }

  @override
  Future<Transaction> cancelPayment({required String paymentId}) async {
    final String path = _apiClient.config.endpoints.cancelPaymentTemplate
        .replaceFirst('{payment_id}', paymentId);
    final Map<String, dynamic> response = await _apiClient.post(path);
    return _parsePayment(response, paymentId: paymentId);
  }

  Transaction _parsePayment(
    Map<String, dynamic> response, {
    required String paymentId,
  }) {
    final Map<String, dynamic> payload = _extractPayload(response);
    final String? envelopeMessage = asString(response['message']);
    final Map<String, dynamic> mergedPayload = <String, dynamic>{
      ...payload,
      if (!payload.containsKey('payment_id')) 'payment_id': paymentId,
      if (!payload.containsKey('message') && envelopeMessage != null)
        'message': envelopeMessage,
    };

    final Transaction transaction = Transaction.fromJson(mergedPayload);
    if (transaction.paymentId == null || transaction.paymentId!.isEmpty) {
      throw ApiException.parsing(
        'FastPay payment response did not include payment_id.',
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
