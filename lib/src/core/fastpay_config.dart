import 'endpoints.dart';

/// Configuration required to initialize the FastPay SDK.
class FastPayConfig {
  /// Creates a [FastPayConfig].
  const FastPayConfig({
    required this.baseUrl,
    required this.apiKey,
    this.apiSecret,
    this.accessToken,
    this.merchantId,
    this.clientSource = 'flutter_sdk',
    this.sdkVersion = '0.0.1',
    this.platform,
    this.timeout = const Duration(seconds: 30),
    this.defaultHeaders = const <String, String>{},
    this.endpoints = const FastPayEndpoints(),
  });

  /// Base URL for the FastPay API, such as `https://api.fastpay.dpdns.org`.
  final String baseUrl;

  /// Merchant API key.
  final String apiKey;

  /// Merchant API secret used to obtain a bearer token.
  final String? apiSecret;

  /// Optional pre-issued bearer token.
  final String? accessToken;

  /// Optional merchant identifier sent as a hint header.
  final String? merchantId;

  /// Source marker attached to each request for observability.
  final String clientSource;

  /// SDK version attached to each request for observability.
  final String sdkVersion;

  /// Optional client platform override.
  final String? platform;

  /// Default network timeout for all requests.
  final Duration timeout;

  /// Caller-supplied headers that should be attached to every request.
  final Map<String, String> defaultHeaders;

  /// Configurable route definitions.
  final FastPayEndpoints endpoints;

  /// Returns a copy with the provided overrides.
  FastPayConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? apiSecret,
    String? accessToken,
    String? merchantId,
    String? clientSource,
    String? sdkVersion,
    String? platform,
    Duration? timeout,
    Map<String, String>? defaultHeaders,
    FastPayEndpoints? endpoints,
  }) {
    return FastPayConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      apiSecret: apiSecret ?? this.apiSecret,
      accessToken: accessToken ?? this.accessToken,
      merchantId: merchantId ?? this.merchantId,
      clientSource: clientSource ?? this.clientSource,
      sdkVersion: sdkVersion ?? this.sdkVersion,
      platform: platform ?? this.platform,
      timeout: timeout ?? this.timeout,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      endpoints: endpoints ?? this.endpoints,
    );
  }

  /// Builds a [Uri] from a relative API path and optional query parameters.
  Uri buildUri(String path, {Map<String, dynamic>? queryParameters}) {
    final Uri baseUri = Uri.parse(baseUrl);
    final String normalizedBasePath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    final String normalizedPath = path.startsWith('/') ? path : '/$path';

    return baseUri.replace(
      path: '$normalizedBasePath$normalizedPath',
      queryParameters: queryParameters?.map(
        (String key, dynamic value) => MapEntry(key, value?.toString()),
      ),
    );
  }
}
