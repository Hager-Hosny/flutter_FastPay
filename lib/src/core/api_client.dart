import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/token_pair.dart';
import '../utils/json_utils.dart';
import 'api_exception.dart';
import 'fastpay_config.dart';
import 'token_store.dart';

class ApiEnvelope {
  const ApiEnvelope({
    this.status,
    this.message,
    this.data,
    this.error,
    required this.rawPayload,
  });

  final String? status;
  final String? message;
  final Object? data;
  final Map<String, dynamic>? error;
  final Map<String, dynamic> rawPayload;
}

/// Thin HTTP client used by the SDK service layer.
class ApiClient {
  ApiClient({
    required FastPayConfig config,
    required TokenStore tokenStore,
    http.Client? httpClient,
  }) : _config = config,
       _tokenStore = tokenStore,
       _httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null;

  final FastPayConfig _config;
  final TokenStore _tokenStore;
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  FastPayConfig get config => _config;

  TokenStore get tokenStore => _tokenStore;

  Future<ApiEnvelope> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    Map<String, String>? extraHeaders,
  }) {
    return _send(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
      extraHeaders: extraHeaders,
    );
  }

  Future<ApiEnvelope> post(
    String path, {
    Object? body,
    bool requiresAuth = true,
    Map<String, String>? extraHeaders,
  }) {
    return _send(
      method: 'POST',
      path: path,
      body: body,
      requiresAuth: requiresAuth,
      extraHeaders: extraHeaders,
    );
  }

  Future<TokenPair> login({String? apiKey, String? apiSecret}) async {
    final String resolvedApiKey = asString(apiKey) ?? _config.apiKey;
    final String resolvedApiSecret =
        asString(apiSecret) ?? asString(_config.apiSecret) ?? '';

    if (resolvedApiKey.trim().isEmpty || resolvedApiSecret.trim().isEmpty) {
      throw ConfigurationApiException(
        message: 'FastPay login requires both apiKey and apiSecret.',
      );
    }

    final ApiEnvelope envelope = await post(
      _config.endpoints.authToken,
      requiresAuth: false,
      body: <String, dynamic>{
        'api_key': resolvedApiKey,
        'api_secret': resolvedApiSecret,
      },
    );

    final Map<String, dynamic> data = asJsonMap(envelope.data) ?? envelope.rawPayload;
    final TokenPair tokenPair = TokenPair.fromJson(data);
    if (tokenPair.accessToken.trim().isEmpty) {
      throw ParsingApiException(
        message: 'FastPay auth response did not include access_token.',
        rawPayload: envelope.rawPayload,
      );
    }

    await _tokenStore.write(tokenPair);
    return tokenPair;
  }

  Future<TokenPair> refresh({String? refreshToken}) async {
    final TokenPair? storedTokens = await _tokenStore.read();
    final String resolvedRefreshToken =
        asString(refreshToken) ?? asString(storedTokens?.refreshToken) ?? '';

    if (resolvedRefreshToken.trim().isEmpty) {
      throw AuthenticationApiException(
        message: 'FastPay refresh requires a refresh token.',
      );
    }

    final ApiEnvelope envelope = await post(
      _config.endpoints.refreshToken,
      requiresAuth: false,
      body: <String, dynamic>{'refresh_token': resolvedRefreshToken},
    );

    final Map<String, dynamic> data = asJsonMap(envelope.data) ?? envelope.rawPayload;
    final TokenPair refreshed = TokenPair.fromJson(data);
    if (refreshed.accessToken.trim().isEmpty) {
      throw ParsingApiException(
        message: 'FastPay refresh response did not include access_token.',
        rawPayload: envelope.rawPayload,
      );
    }

    final TokenPair merged = refreshed.copyWith(
      refreshToken: refreshed.refreshToken ?? storedTokens?.refreshToken,
    );
    await _tokenStore.write(merged);
    return merged;
  }

  Future<void> logout() async {
    final TokenPair? storedTokens = await _tokenStore.read();

    try {
      await post(
        _config.endpoints.logout,
        requiresAuth: false,
        body: storedTokens?.refreshToken == null
            ? null
            : <String, dynamic>{'refresh_token': storedTokens!.refreshToken},
      );
    } finally {
      await _tokenStore.clear();
    }
  }

  Future<String> resolveAccessToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      final TokenPair? refreshed = await _refreshTokenPair();
      if (refreshed != null) {
        return refreshed.accessToken;
      }
    }

    final TokenPair? storedTokens = await _tokenStore.read();
    final String? storedAccessToken = asString(storedTokens?.accessToken);
    if (storedAccessToken != null && storedAccessToken.isNotEmpty) {
      return storedAccessToken;
    }

    final String? staticAccessToken = asString(_config.accessToken);
    if (staticAccessToken != null && staticAccessToken.isNotEmpty) {
      return staticAccessToken;
    }

    if ((_config.apiSecret ?? '').trim().isNotEmpty) {
      return (await login()).accessToken;
    }

    throw ConfigurationApiException(
      message:
          'FastPay requires either access tokens or apiSecret to call authenticated routes.',
    );
  }

  void close() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  Future<ApiEnvelope> _send({
    required String method,
    required String path,
    Map<String, dynamic>? queryParameters,
    Object? body,
    required bool requiresAuth,
    Map<String, String>? extraHeaders,
    bool retryOnUnauthorized = true,
  }) async {
    final String? accessToken = requiresAuth
        ? await _getAccessTokenForRequest()
        : null;

    final Uri uri = _config.buildUri(path, queryParameters: queryParameters);
    final Map<String, String> headers = _buildHeaders(
      requiresAuth: requiresAuth,
      accessToken: accessToken,
      includeJsonContentType: method != 'GET' && body != null,
      extraHeaders: extraHeaders,
    );

    late http.Response response;
    try {
      response = await _dispatch(
        method: method,
        uri: uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ).timeout(_config.timeout);
    } on TimeoutException catch (error) {
      throw TimeoutApiException(
        message: 'FastPay request timed out.',
        cause: error,
      );
    } on SocketException catch (error) {
      throw NetworkApiException(
        message: 'Unable to reach the FastPay API.',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw NetworkApiException(
        message: 'HTTP client error while calling FastPay.',
        cause: error,
      );
    }

    final Map<String, dynamic> payload = _decodeJsonMap(response.body);
    final ApiEnvelope envelope = ApiEnvelope(
      status: asString(payload['status']),
      message: asString(payload['message']),
      data: payload['data'],
      error: asJsonMap(payload['error']),
      rawPayload: payload,
    );

    if (response.statusCode == 401 && requiresAuth && retryOnUnauthorized) {
      final TokenPair? refreshed = await _refreshTokenPair();
      if (refreshed != null) {
        return _send(
          method: method,
          path: path,
          queryParameters: queryParameters,
          body: body,
          requiresAuth: requiresAuth,
          extraHeaders: extraHeaders,
          retryOnUnauthorized: false,
        );
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _mapError(
        statusCode: response.statusCode,
        envelope: envelope,
        responseHeaders: response.headers,
      );
    }

    return envelope;
  }

  Future<String?> _getAccessTokenForRequest() async {
    final TokenPair? storedTokens = await _tokenStore.read();
    final String? storedAccessToken = asString(storedTokens?.accessToken);
    if (storedAccessToken != null && storedAccessToken.isNotEmpty) {
      return storedAccessToken;
    }

    final String? staticAccessToken = asString(_config.accessToken);
    if (staticAccessToken != null && staticAccessToken.isNotEmpty) {
      return staticAccessToken;
    }

    if ((_config.apiSecret ?? '').trim().isNotEmpty) {
      return (await login()).accessToken;
    }

    throw ConfigurationApiException(
      message:
          'FastPay attempted an authenticated request without an access token or apiSecret.',
    );
  }

  Future<TokenPair?> _refreshTokenPair() async {
    try {
      return await refresh();
    } on AuthenticationApiException {
      return null;
    } on ApiException catch (error) {
      if (error.type == ApiExceptionType.authentication) {
        return null;
      }
      rethrow;
    }
  }

  Future<http.Response> _dispatch({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) {
    switch (method) {
      case 'GET':
        return _httpClient.get(uri, headers: headers);
      case 'POST':
        return _httpClient.post(uri, headers: headers, body: body);
      default:
        throw ConfigurationApiException(
          message: 'Unsupported HTTP method "$method" for FastPay ApiClient.',
        );
    }
  }

  Map<String, String> _buildHeaders({
    required bool requiresAuth,
    required String? accessToken,
    required bool includeJsonContentType,
    Map<String, String>? extraHeaders,
  }) {
    final Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
      'X-Client-Source': _config.clientSource,
      'X-SDK-Version': _config.sdkVersion,
      'X-Platform': _config.platform ?? _defaultPlatform(),
      'X-Request-Id': _buildRequestId(),
      ..._config.defaultHeaders,
      ...?extraHeaders,
    };

    if (includeJsonContentType) {
      headers.putIfAbsent('Content-Type', () => 'application/json');
    }

    if (_config.apiKey.trim().isNotEmpty) {
      headers.putIfAbsent('X-Public-Key', () => _config.apiKey);
    }

    if ((_config.merchantId ?? '').trim().isNotEmpty) {
      headers.putIfAbsent('X-Merchant-Id', () => _config.merchantId!);
    }

    if (requiresAuth) {
      if (accessToken == null || accessToken.isEmpty) {
        throw ConfigurationApiException(
          message:
              'FastPay attempted an authenticated request without an access token.',
        );
      }
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }

  String _defaultPlatform() {
    if (kIsWeb) {
      return 'web';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  String _buildRequestId() {
    final int randomValue = Random().nextInt(1 << 32);
    return 'fp_${DateTime.now().microsecondsSinceEpoch}_${randomValue.toRadixString(16)}';
  }

  Map<String, dynamic> _decodeJsonMap(String body) {
    if (body.trim().isEmpty) {
      return const <String, dynamic>{};
    }

    try {
      final Object? decoded = jsonDecode(body);
      return asJsonMap(decoded) ?? <String, dynamic>{'data': decoded};
    } on FormatException catch (error) {
      throw ParsingApiException(
        message: 'FastPay returned malformed JSON.',
        cause: error,
      );
    }
  }

  ApiException _mapError({
    required int statusCode,
    required ApiEnvelope envelope,
    required Map<String, String> responseHeaders,
  }) {
    final Map<String, dynamic> error =
        envelope.error ?? const <String, dynamic>{};
    final Map<String, String> fieldErrors = asStringMap(
      asJsonMap(error['field_errors']),
    );
    final String message =
        asString(envelope.message) ??
        asString(error['message']) ??
        asString(error['code']) ??
        'FastPay request failed.';
    final String? requestId =
        asString(error['request_id']) ?? responseHeaders['x-request-id'];
    final String? errorCode = asString(error['code']);

    if (statusCode == 400) {
      return ValidationApiException(
        message: message,
        statusCode: statusCode,
        errorCode: errorCode,
        fieldErrors: fieldErrors,
        requestId: requestId,
        rawPayload: envelope.rawPayload,
      );
    }

    if (statusCode == 401) {
      return AuthenticationApiException(
        message: message,
        statusCode: statusCode,
        errorCode: errorCode,
        fieldErrors: fieldErrors,
        requestId: requestId,
        rawPayload: envelope.rawPayload,
      );
    }

    if (statusCode == 403) {
      return AuthorizationApiException(
        message: message,
        statusCode: statusCode,
        errorCode: errorCode,
        fieldErrors: fieldErrors,
        requestId: requestId,
        rawPayload: envelope.rawPayload,
      );
    }

    if (statusCode == 404) {
      return NotFoundApiException(
        message: message,
        statusCode: statusCode,
        errorCode: errorCode,
        fieldErrors: fieldErrors,
        requestId: requestId,
        rawPayload: envelope.rawPayload,
      );
    }

    if (statusCode == 422) {
      final bool isValidationError = fieldErrors.isNotEmpty ||
          errorCode == 'validation_error';
      if (isValidationError) {
        return ValidationApiException(
          message: message,
          statusCode: statusCode,
          errorCode: errorCode,
          fieldErrors: fieldErrors,
          requestId: requestId,
          rawPayload: envelope.rawPayload,
        );
      }

      return BusinessRuleApiException(
        message: message,
        statusCode: statusCode,
        errorCode: errorCode,
        fieldErrors: fieldErrors,
        requestId: requestId,
        rawPayload: envelope.rawPayload,
      );
    }

    if (statusCode >= 500) {
      return ServerApiException(
        message: message,
        statusCode: statusCode,
        errorCode: errorCode,
        fieldErrors: fieldErrors,
        requestId: requestId,
        rawPayload: envelope.rawPayload,
      );
    }

    return UnknownApiException(
      message: message,
      statusCode: statusCode,
      errorCode: errorCode,
      fieldErrors: fieldErrors,
      requestId: requestId,
      rawPayload: envelope.rawPayload,
    );
  }
}
