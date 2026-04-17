import 'package:http/http.dart' as http;

import '../models/card_details.dart';
import '../models/customer.dart';
import '../models/session.dart';
import '../models/transaction.dart';
import '../services/fastpay_payment_service.dart';
import '../services/payment_service.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'endpoints.dart';
import 'fastpay_config.dart';

/// Static entry point for initializing and accessing the FastPay SDK.
class FastPay {
  FastPay._();

  static FastPayConfig? _config;
  static ApiClient? _apiClient;
  static PaymentService? _paymentService;
  static FastPayPayments? _payments;

  /// Whether the SDK has been initialized.
  static bool get isInitialized => _paymentService != null;

  /// Initializes the SDK singleton.
  static void initialize(
    FastPayConfig config, {
    http.Client? httpClient,
    PaymentService? paymentService,
  }) {
    _config = config;
    _apiClient?.close();
    _apiClient = ApiClient(config: config, httpClient: httpClient);
    _paymentService =
        paymentService ?? FastPayPaymentService(apiClient: _apiClient!);
    _payments = FastPayPayments._(_paymentService!);
  }

  /// Payment APIs exposed to merchants.
  static FastPayPayments get payments {
    return _payments ?? _throwNotInitialized();
  }

  /// Internal access to the initialized payment service.
  static PaymentService get paymentService {
    return _paymentService ?? _throwNotInitialized();
  }

  /// Returns the active configuration.
  static FastPayConfig get config {
    final FastPayConfig? config = _config;
    if (config == null) {
      _throwNotInitialized();
    }
    return config;
  }

  /// Returns a usable bearer token for the current or provided configuration.
  static Future<String> resolveAccessToken([
    FastPayConfig? initialConfig,
  ], {
    FastPayConfig? config,
    String? baseUrl,
    String? apiKey,
    String? apiSecret,
    String? accessToken,
    String? merchantId,
    Duration? timeout,
    Map<String, String>? defaultHeaders,
    FastPayEndpoints? endpoints,
    http.Client? httpClient,
    bool forceRefresh = false,
  }) async {
    final bool hasOverrides =
        baseUrl != null ||
        apiKey != null ||
        apiSecret != null ||
        accessToken != null ||
        merchantId != null ||
        timeout != null ||
        defaultHeaders != null ||
        endpoints != null;

    if (initialConfig == null && config == null && !hasOverrides) {
      final ApiClient apiClient = _apiClient ?? _throwNotInitialized();
      return apiClient.resolveAccessToken(forceRefresh: forceRefresh);
    }

    final FastPayConfig? baseConfig = config ?? initialConfig ?? _config;
    final FastPayConfig effectiveConfig;

    if (baseConfig != null) {
      effectiveConfig = baseConfig.copyWith(
        baseUrl: baseUrl,
        apiKey: apiKey,
        apiSecret: apiSecret,
        accessToken: accessToken,
        merchantId: merchantId,
        timeout: timeout,
        defaultHeaders: defaultHeaders,
        endpoints: endpoints,
      );
    } else {
      if (baseUrl == null || apiKey == null) {
        throw ApiException.configuration(
          'FastPay.resolveAccessToken requires both baseUrl and apiKey when the SDK has not been initialized.',
        );
      }

      effectiveConfig = FastPayConfig(
        baseUrl: baseUrl,
        apiKey: apiKey,
        apiSecret: apiSecret,
        accessToken: accessToken,
        merchantId: merchantId,
        timeout: timeout ?? const Duration(seconds: 30),
        defaultHeaders: defaultHeaders ?? const <String, String>{},
        endpoints: endpoints ?? const FastPayEndpoints(),
      );
    }

    final ApiClient apiClient = ApiClient(
      config: effectiveConfig,
      httpClient: httpClient,
    );

    try {
      return await apiClient.resolveAccessToken(forceRefresh: forceRefresh);
    } finally {
      apiClient.close();
    }
  }

  /// Disposes the singleton resources.
  static void dispose() {
    _apiClient?.close();
    _apiClient = null;
    _paymentService = null;
    _payments = null;
    _config = null;
  }

  static Never _throwNotInitialized() {
    throw ApiException.configuration(
      'FastPay.initialize must be called before using the SDK.',
    );
  }
}

/// Public payment APIs surfaced through [FastPay.payments].
class FastPayPayments {
  FastPayPayments._(this._paymentService);

  final PaymentService _paymentService;

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
  }) {
    return _paymentService.createSession(
      amount: amount,
      currency: currency,
      customer: customer,
      merchantOrderId: merchantOrderId,
      metadata: metadata,
      redirectUrl: redirectUrl,
      callbackUrl: callbackUrl,
      source: source,
    );
  }

  /// Processes a card payment.
  Future<Transaction> processPayment({
    required String sessionId,
    required CardDetails cardDetails,
    double? amount,
    String? currency,
    Customer? customer,
    String paymentMethod = 'card',
    bool? saveCard,
    String? merchantOrderId,
    Map<String, dynamic>? metadata,
  }) {
    return _paymentService.processTransaction(
      sessionId: sessionId,
      cardDetails: cardDetails,
      amount: amount,
      currency: currency,
      customer: customer,
      paymentMethod: paymentMethod,
      saveCard: saveCard,
      merchantOrderId: merchantOrderId,
      metadata: metadata,
    );
  }

  /// Returns the latest payment or transaction status.
  Future<Transaction> getStatus({
    String? paymentId,
    String? transactionId,
    String? sessionId,
  }) {
    return _paymentService.getTransactionStatus(
      paymentId: paymentId,
      transactionId: transactionId,
      sessionId: sessionId,
    );
  }

  /// Retries a failed payment.
  Future<Transaction> retryPayment({
    String? paymentId,
    String? transactionId,
    String? sessionId,
    CardDetails? cardDetails,
    String paymentMethod = 'card',
    Map<String, dynamic>? metadata,
  }) {
    return _paymentService.retryPayment(
      paymentId: paymentId,
      transactionId: transactionId,
      sessionId: sessionId,
      cardDetails: cardDetails,
      paymentMethod: paymentMethod,
      metadata: metadata,
    );
  }
}
