import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/validators.dart';
import '../models/cancel_payment_result.dart';
import '../models/customer.dart';
import '../models/payment_details.dart';
import '../models/payment_method.dart';
import '../models/payment_session.dart';
import '../models/retry_payment_result.dart';
import '../utils/json_utils.dart';
import 'payment_service.dart';

class FastPayPaymentService implements PaymentService {
  FastPayPaymentService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<PaymentMethod>> listMethods() async {
    final ApiEnvelope envelope = await _apiClient.get(
      _apiClient.config.endpoints.paymentMethods,
    );
    final Object? data = envelope.data;
    if (data is! List) {
      throw ParsingApiException(
        message: 'FastPay payment methods response did not contain a list.',
        rawPayload: envelope.rawPayload,
      );
    }

    return data
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) => PaymentMethod.fromJson(
            item.map(
              (dynamic key, dynamic value) => MapEntry(key.toString(), value),
            ),
          ),
        )
        .toList();
  }

  @override
  Future<PaymentSession> createSession({
    required double amount,
    required String currency,
    required Customer customer,
    required String merchantOrderId,
    required String callbackUrl,
    Map<String, dynamic>? metadata,
    String? redirectUrl,
  }) async {
    Validators.requirePositiveAmount(amount);
    Validators.requireCurrency(currency);
    Validators.requireNotBlank(merchantOrderId, 'merchantOrderId');
    Validators.requireNotBlank(callbackUrl, 'callbackUrl');
    Validators.requireNotBlank(customer.name ?? '', 'customer.name');
    Validators.requireNotBlank(customer.email ?? '', 'customer.email');
    Validators.requireNotBlank(customer.phone ?? '', 'customer.phone');

    final ApiEnvelope envelope = await _apiClient.post(
      _apiClient.config.endpoints.createSession,
      body: <String, dynamic>{
        'amount': amount,
        'currency': currency.trim().toUpperCase(),
        'merchant_order_id': merchantOrderId.trim(),
        'customer': customer.toJson(),
        'metadata': metadata,
        'redirect_url': asString(redirectUrl),
        'callback_url': callbackUrl.trim(),
      }..removeWhere((String _, dynamic value) => value == null),
    );

    final Map<String, dynamic> data = _requireDataMap(
      envelope,
      operation: 'createSession',
    );
    final PaymentSession session = PaymentSession.fromJson(data);
    if ((session.paymentId ?? '').trim().isEmpty) {
      throw ParsingApiException(
        message: 'FastPay createSession response did not include payment_id.',
        rawPayload: envelope.rawPayload,
      );
    }
    return session;
  }

  @override
  Future<PaymentDetails> getPayment({required String paymentId}) async {
    Validators.requireNotBlank(paymentId, 'paymentId');
    final ApiEnvelope envelope = await _apiClient.get(
      _apiClient.config.endpoints.paymentDetails(paymentId),
    );
    return PaymentDetails.fromJson(
      _requireDataMap(envelope, operation: 'getPayment'),
    );
  }

  @override
  Future<RetryPaymentResult> retryPayment({
    required String paymentId,
    String? paymentMethod,
    String? redirectUrl,
    String? callbackUrl,
  }) async {
    Validators.requireNotBlank(paymentId, 'paymentId');
    final ApiEnvelope envelope = await _apiClient.post(
      _apiClient.config.endpoints.retryPayment(paymentId),
      body: <String, dynamic>{
        'payment_method': asString(paymentMethod),
        'redirect_url': asString(redirectUrl),
        'callback_url': asString(callbackUrl),
      }..removeWhere((String _, dynamic value) => value == null),
    );
    return RetryPaymentResult.fromJson(
      _requireDataMap(envelope, operation: 'retryPayment'),
    );
  }

  @override
  Future<CancelPaymentResult> cancelPayment({required String paymentId}) async {
    Validators.requireNotBlank(paymentId, 'paymentId');
    final ApiEnvelope envelope = await _apiClient.post(
      _apiClient.config.endpoints.cancelPayment(paymentId),
    );
    return CancelPaymentResult.fromJson(
      _requireDataMap(envelope, operation: 'cancelPayment'),
    );
  }

  Map<String, dynamic> _requireDataMap(
    ApiEnvelope envelope, {
    required String operation,
  }) {
    final Map<String, dynamic>? data = asJsonMap(envelope.data);
    if (data != null) {
      return data;
    }

    throw ParsingApiException(
      message: 'FastPay $operation response did not contain an object payload.',
      rawPayload: envelope.rawPayload,
    );
  }
}
