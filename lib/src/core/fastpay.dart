import 'package:http/http.dart' as http;

import '../models/cancel_payment_result.dart';
import '../models/customer.dart';
import '../models/page_result.dart';
import '../models/payment_details.dart';
import '../models/payment_method.dart';
import '../models/payment_session.dart';
import '../models/payout_result.dart';
import '../models/refund_result.dart';
import '../models/retry_payment_result.dart';
import '../models/token_pair.dart';
import '../models/transaction_list_item.dart';
import '../models/transactions_summary.dart';
import '../models/webhook_delivery_result.dart';
import '../models/webhook_dispatch_result.dart';
import '../utils/json_utils.dart';
import '../services/fastpay_payment_service.dart';
import '../services/payment_service.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'endpoints.dart';
import 'fastpay_config.dart';
import 'token_store.dart';
import 'validators.dart';

/// Static entry point for initializing and accessing the FastPay SDK.
class FastPay {
  FastPay._();

  static FastPayConfig? _config;
  static ApiClient? _apiClient;
  static PaymentService? _paymentService;
  static TokenStore? _tokenStore;
  static FastPayAuthClient? _auth;
  static FastPayPaymentsClient? _payments;
  static FastPayTransactionsClient? _transactions;
  static FastPayRefundsClient? _refunds;
  static FastPayPayoutsClient? _payouts;
  static FastPayWebhooksClient? _webhooks;

  static bool get isInitialized => _apiClient != null;

  static void initialize(
    FastPayConfig config, {
    http.Client? httpClient,
    TokenStore? tokenStore,
    PaymentService? paymentService,
  }) {
    _config = config;
    _apiClient?.close();

    final TokenStore resolvedTokenStore =
        tokenStore ??
        config.tokenStore ??
        InMemoryTokenStore(initialTokens: config.initialTokens);

    _tokenStore = resolvedTokenStore;
    _apiClient = ApiClient(
      config: config,
      tokenStore: resolvedTokenStore,
      httpClient: httpClient,
    );
    _paymentService =
        paymentService ?? FastPayPaymentService(apiClient: _apiClient!);
    _auth = FastPayAuthClient._(_apiClient!);
    _payments = FastPayPaymentsClient._(_paymentService!);
    _transactions = FastPayTransactionsClient._(_apiClient!);
    _refunds = FastPayRefundsClient._(_apiClient!);
    _payouts = FastPayPayoutsClient._(_apiClient!);
    _webhooks = FastPayWebhooksClient._(_apiClient!);
  }

  static FastPayConfig get config => _config ?? _throwNotInitialized();

  static TokenStore get tokenStore => _tokenStore ?? _throwNotInitialized();

  static FastPayAuthClient get auth => _auth ?? _throwNotInitialized();

  static FastPayPaymentsClient get payments =>
      _payments ?? _throwNotInitialized();

  static PaymentService get paymentService =>
      _paymentService ?? _throwNotInitialized();

  static FastPayTransactionsClient get transactions =>
      _transactions ?? _throwNotInitialized();

  static FastPayRefundsClient get refunds => _refunds ?? _throwNotInitialized();

  static FastPayPayoutsClient get payouts => _payouts ?? _throwNotInitialized();

  static FastPayWebhooksClient get webhooks =>
      _webhooks ?? _throwNotInitialized();

  static Future<String> resolveAccessToken({
    FastPayConfig? config,
    String? baseUrl,
    String? apiKey,
    String? apiSecret,
    String? accessToken,
    String? refreshToken,
    String? merchantId,
    String? externalWebhookApiKey,
    Duration? timeout,
    Map<String, String>? defaultHeaders,
    FastPayEndpoints? endpoints,
    TokenStore? tokenStore,
    http.Client? httpClient,
    bool forceRefresh = false,
  }) async {
    final bool hasOverrides =
        baseUrl != null ||
        apiKey != null ||
        apiSecret != null ||
        accessToken != null ||
        refreshToken != null ||
        merchantId != null ||
        externalWebhookApiKey != null ||
        timeout != null ||
        defaultHeaders != null ||
        endpoints != null ||
        tokenStore != null;

    if (config == null && !hasOverrides) {
      final ApiClient apiClient = _apiClient ?? _throwNotInitialized();
      return apiClient.resolveAccessToken(forceRefresh: forceRefresh);
    }

    final FastPayConfig? baseConfig = config ?? _config;
    final FastPayConfig effectiveConfig;

    if (baseConfig != null) {
      effectiveConfig = baseConfig.copyWith(
        baseUrl: baseUrl,
        apiKey: apiKey,
        apiSecret: apiSecret,
        accessToken: accessToken,
        refreshToken: refreshToken,
        merchantId: merchantId,
        externalWebhookApiKey: externalWebhookApiKey,
        timeout: timeout,
        defaultHeaders: defaultHeaders,
        endpoints: endpoints,
        tokenStore: tokenStore,
      );
    } else {
      final String? resolvedBaseUrl = asString(baseUrl);
      final String? resolvedApiKey = asString(apiKey);
      if (resolvedBaseUrl == null || resolvedApiKey == null) {
        throw ConfigurationApiException(
          message:
              'FastPay.resolveAccessToken requires both baseUrl and apiKey when the SDK has not been initialized.',
        );
      }

      effectiveConfig = FastPayConfig(
        baseUrl: resolvedBaseUrl,
        apiKey: resolvedApiKey,
        apiSecret: apiSecret,
        accessToken: accessToken,
        refreshToken: refreshToken,
        merchantId: merchantId,
        externalWebhookApiKey: externalWebhookApiKey,
        timeout: timeout ?? const Duration(seconds: 30),
        defaultHeaders: defaultHeaders ?? const <String, String>{},
        endpoints: endpoints ?? const FastPayEndpoints(),
        tokenStore: tokenStore,
      );
    }

    final TokenStore resolvedTokenStore =
        effectiveConfig.tokenStore ??
        InMemoryTokenStore(initialTokens: effectiveConfig.initialTokens);
    final ApiClient apiClient = ApiClient(
      config: effectiveConfig,
      tokenStore: resolvedTokenStore,
      httpClient: httpClient,
    );

    try {
      return await apiClient.resolveAccessToken(forceRefresh: forceRefresh);
    } finally {
      apiClient.close();
    }
  }

  static void dispose() {
    _apiClient?.close();
    _apiClient = null;
    _paymentService = null;
    _tokenStore = null;
    _auth = null;
    _payments = null;
    _transactions = null;
    _refunds = null;
    _payouts = null;
    _webhooks = null;
    _config = null;
  }

  static Never _throwNotInitialized() {
    throw ConfigurationApiException(
      message: 'FastPay.initialize must be called before using the SDK.',
    );
  }
}

class FastPayAuthClient {
  FastPayAuthClient._(this._apiClient);

  final ApiClient _apiClient;

  Future<TokenPair> login({String? apiKey, String? apiSecret}) {
    return _apiClient.login(apiKey: apiKey, apiSecret: apiSecret);
  }

  Future<TokenPair> refresh({String? refreshToken}) {
    return _apiClient.refresh(refreshToken: refreshToken);
  }

  Future<void> logout() => _apiClient.logout();

  Future<TokenPair?> currentTokens() => _apiClient.tokenStore.read();
}

class FastPayPaymentsClient {
  FastPayPaymentsClient._(this._paymentService);

  final PaymentService _paymentService;

  Future<List<PaymentMethod>> listMethods() => _paymentService.listMethods();

  Future<PaymentSession> createSession({
    required double amount,
    required String currency,
    required Customer customer,
    required String merchantOrderId,
    required String callbackUrl,
    Map<String, dynamic>? metadata,
    String? redirectUrl,
  }) {
    return _paymentService.createSession(
      amount: amount,
      currency: currency,
      customer: customer,
      merchantOrderId: merchantOrderId,
      callbackUrl: callbackUrl,
      metadata: metadata,
      redirectUrl: redirectUrl,
    );
  }

  Future<PaymentDetails> getPayment({required String paymentId}) {
    return _paymentService.getPayment(paymentId: paymentId);
  }

  Future<RetryPaymentResult> retryPayment({
    required String paymentId,
    String? paymentMethod,
    String? redirectUrl,
    String? callbackUrl,
  }) {
    return _paymentService.retryPayment(
      paymentId: paymentId,
      paymentMethod: paymentMethod,
      redirectUrl: redirectUrl,
      callbackUrl: callbackUrl,
    );
  }

  Future<CancelPaymentResult> cancelPayment({required String paymentId}) {
    return _paymentService.cancelPayment(paymentId: paymentId);
  }
}

class FastPayTransactionsClient {
  FastPayTransactionsClient._(this._apiClient);

  final ApiClient _apiClient;

  Future<PageResult<TransactionListItem>> list({
    int page = 0,
    int size = 10,
  }) async {
    Validators.requirePage(page);
    Validators.requireSize(size);

    final ApiEnvelope envelope = await _apiClient.get(
      _apiClient.config.endpoints.transactions,
      queryParameters: <String, dynamic>{'page': page, 'size': size},
    );

    return PageResult<TransactionListItem>.fromJson(
      _requireDataMap(envelope, operation: 'listTransactions'),
      TransactionListItem.fromJson,
    );
  }

  Future<TransactionsSummary> summary({
    required DateTime from,
    required DateTime to,
    required String currency,
  }) async {
    Validators.requireDateRange(from, to);
    Validators.requireCurrency(currency);

    final ApiEnvelope envelope = await _apiClient.get(
      _apiClient.config.endpoints.transactionsSummary,
      queryParameters: <String, dynamic>{
        'from': _formatDate(from),
        'to': _formatDate(to),
        'currency': currency.trim().toUpperCase(),
      },
    );

    return TransactionsSummary.fromJson(
      _requireDataMap(envelope, operation: 'transactionsSummary'),
    );
  }
}

class FastPayRefundsClient {
  FastPayRefundsClient._(this._apiClient);

  final ApiClient _apiClient;

  Future<RefundResult> create({
    required int transactionId,
    required String amount,
    required String currency,
    String? paymentId,
    String? reason,
    String? providerReference,
    Map<String, dynamic>? metadata,
    String? callbackUrl,
  }) async {
    if (transactionId <= 0) {
      throw ValidationApiException(
        message: 'transactionId must be greater than 0.',
        fieldErrors: const <String, String>{
          'transactionId': 'Expected a positive transaction id',
        },
      );
    }

    Validators.requireNotBlank(amount, 'amount');
    Validators.requireCurrency(currency);

    final ApiEnvelope envelope = await _apiClient.post(
      _apiClient.config.endpoints.refunds,
      body: <String, dynamic>{
        'transaction_id': transactionId,
        'amount': amount.trim(),
        'currency': currency.trim().toUpperCase(),
        'payment_id': asString(paymentId),
        'reason': asString(reason),
        'provider_reference': asString(providerReference),
        'metadata': metadata,
        'callback_url': asString(callbackUrl),
      }..removeWhere((String _, dynamic value) => value == null),
    );

    return RefundResult.fromJson(
      _requireDataMap(envelope, operation: 'createRefund'),
    );
  }
}

class FastPayPayoutsClient {
  FastPayPayoutsClient._(this._apiClient);

  final ApiClient _apiClient;

  Future<PayoutResult> create({
    required double amount,
    required String currency,
    required String destinationType,
    required Map<String, dynamic> destinationDetails,
    Map<String, dynamic>? metadata,
  }) async {
    Validators.requirePositiveAmount(amount);
    Validators.requireCurrency(currency);
    Validators.requireNotBlank(destinationType, 'destinationType');
    if (destinationDetails.isEmpty) {
      throw ValidationApiException(
        message: 'destinationDetails is required.',
        fieldErrors: const <String, String>{
          'destinationDetails': 'Field is required',
        },
      );
    }

    final ApiEnvelope envelope = await _apiClient.post(
      _apiClient.config.endpoints.payouts,
      body: <String, dynamic>{
        'amount': amount,
        'currency': currency.trim().toUpperCase(),
        'destination_type': destinationType.trim(),
        'destination_details': destinationDetails,
        'metadata': metadata,
      }..removeWhere((String _, dynamic value) => value == null),
    );

    return PayoutResult.fromJson(
      _requireDataMap(envelope, operation: 'createPayout'),
    );
  }
}

class FastPayWebhooksClient {
  FastPayWebhooksClient._(this._apiClient);

  final ApiClient _apiClient;

  Future<WebhookDispatchResult> dispatch({
    required int merchantId,
    required String eventType,
    required Map<String, dynamic> payload,
    String? environment,
    String? eventId,
    String? apiKey,
  }) async {
    if (merchantId <= 0) {
      throw ValidationApiException(
        message: 'merchantId must be greater than 0.',
        fieldErrors: const <String, String>{
          'merchantId': 'Expected a positive merchant id',
        },
      );
    }
    Validators.requireNotBlank(eventType, 'eventType');
    if (payload.isEmpty) {
      throw ValidationApiException(
        message: 'payload is required.',
        fieldErrors: const <String, String>{'payload': 'Field is required'},
      );
    }

    final String resolvedApiKey =
        asString(apiKey) ?? asString(_apiClient.config.externalWebhookApiKey) ?? '';
    if (resolvedApiKey.trim().isEmpty) {
      throw ConfigurationApiException(
        message:
            'FastPay webhook dispatch requires externalWebhookApiKey in config or method call.',
      );
    }

    final ApiEnvelope envelope = await _apiClient.post(
      _apiClient.config.endpoints.webhookDispatch,
      requiresAuth: false,
      extraHeaders: <String, String>{
        'Authorization': 'Bearer $resolvedApiKey',
      },
      body: <String, dynamic>{
        'merchant_id': merchantId,
        'environment': asString(environment),
        'event_type': eventType.trim(),
        'event_id': asString(eventId),
        'payload': payload,
      }..removeWhere((String _, dynamic value) => value == null),
    );

    return WebhookDispatchResult.fromJson(
      _requireDataMap(envelope, operation: 'dispatchWebhook'),
    );
  }

  Future<WebhookDeliveryResult> deliverLog({required int logId}) async {
    if (logId <= 0) {
      throw ValidationApiException(
        message: 'logId must be greater than 0.',
        fieldErrors: const <String, String>{
          'logId': 'Expected a positive log id',
        },
      );
    }

    final ApiEnvelope envelope = await _apiClient.post(
      _apiClient.config.endpoints.deliverWebhookLog(logId),
    );

    return WebhookDeliveryResult.fromJson(
      _requireDataMap(envelope, operation: 'deliverWebhookLog'),
    );
  }
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

String _formatDate(DateTime date) {
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
