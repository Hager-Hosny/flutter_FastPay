import '../models/token_pair.dart';
import 'endpoints.dart';
import 'token_store.dart';

/// Configuration required to initialize the FastPay SDK.
class FastPayConfig {
  const FastPayConfig({
    required this.baseUrl,
    required this.apiKey,
    this.apiSecret,
    this.accessToken,
    this.refreshToken,
    this.externalWebhookApiKey,
    this.merchantId,
    this.clientSource = 'flutter_sdk',
    this.sdkVersion = '0.1.0',
    this.platform,
    this.timeout = const Duration(seconds: 30),
    this.defaultHeaders = const <String, String>{},
    this.endpoints = const FastPayEndpoints(),
    this.tokenStore,
  });

  final String baseUrl;
  final String apiKey;
  final String? apiSecret;
  final String? accessToken;
  final String? refreshToken;
  final String? externalWebhookApiKey;
  final String? merchantId;
  final String clientSource;
  final String sdkVersion;
  final String? platform;
  final Duration timeout;
  final Map<String, String> defaultHeaders;
  final FastPayEndpoints endpoints;
  final TokenStore? tokenStore;

  TokenPair? get initialTokens {
    if ((accessToken == null || accessToken!.isEmpty) &&
        (refreshToken == null || refreshToken!.isEmpty)) {
      return null;
    }

    return TokenPair(
      accessToken: accessToken ?? '',
      refreshToken: refreshToken,
      expiresIn: null,
    );
  }

  FastPayConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? apiSecret,
    String? accessToken,
    String? refreshToken,
    String? externalWebhookApiKey,
    String? merchantId,
    String? clientSource,
    String? sdkVersion,
    String? platform,
    Duration? timeout,
    Map<String, String>? defaultHeaders,
    FastPayEndpoints? endpoints,
    TokenStore? tokenStore,
  }) {
    return FastPayConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      apiSecret: apiSecret ?? this.apiSecret,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      externalWebhookApiKey:
          externalWebhookApiKey ?? this.externalWebhookApiKey,
      merchantId: merchantId ?? this.merchantId,
      clientSource: clientSource ?? this.clientSource,
      sdkVersion: sdkVersion ?? this.sdkVersion,
      platform: platform ?? this.platform,
      timeout: timeout ?? this.timeout,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      endpoints: endpoints ?? this.endpoints,
      tokenStore: tokenStore ?? this.tokenStore,
    );
  }

  Uri buildUri(String path, {Map<String, dynamic>? queryParameters}) {
    final Uri baseUri = Uri.parse(baseUrl);
    final String normalizedBasePath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    final String normalizedPath = path.startsWith('/') ? path : '/$path';

    return baseUri.replace(
      path: '$normalizedBasePath$normalizedPath',
      queryParameters: queryParameters == null
          ? null
          : queryParameters.map(
              (String key, dynamic value) => MapEntry(key, value?.toString()),
            ),
    );
  }
}
