import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../utils/json_utils.dart';
import 'api_exception.dart';
import 'fastpay_config.dart';

/// Thin HTTP client used by the SDK service layer.
class ApiClient {
  /// Creates an [ApiClient].
  ApiClient({required FastPayConfig config, http.Client? httpClient})
    : _config = config,
      _httpClient = httpClient ?? http.Client(),
      _ownsHttpClient = httpClient == null,
      _accessToken = config.accessToken;

  final FastPayConfig _config;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  String? _accessToken;

  /// Active SDK configuration.
  FastPayConfig get config => _config;

  /// Sends a GET request and returns the parsed JSON map.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    return _send(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  /// Sends a POST request and returns the parsed JSON map.
  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    bool requiresAuth = true,
  }) {
    return _send(
      method: 'POST',
      path: path,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  /// Closes the underlying HTTP client.
  void close() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  /// Returns a usable bearer token for the current configuration.
  Future<String> resolveAccessToken({bool forceRefresh = false}) async {
    await _ensureAccessToken(forceRefresh: forceRefresh);

    final String? token = _accessToken ?? _config.accessToken;
    if (token == null || token.isEmpty) {
      throw ApiException.configuration(
        'FastPay attempted an authenticated request without a bearer token.',
      );
    }

    return token;
  }

  Future<Map<String, dynamic>> _send({
    required String method,
    required String path,
    Map<String, dynamic>? queryParameters,
    Object? body,
    required bool requiresAuth,
    bool retryOnUnauthorized = true,
  }) async {
    if (requiresAuth) {
      await _ensureAccessToken();
    }

    final Uri uri = _config.buildUri(path, queryParameters: queryParameters);
    final Map<String, String> headers = _buildHeaders(
      requiresAuth: requiresAuth,
      includeJsonContentType: method != 'GET',
    );

    final String? encodedBody = body == null ? null : jsonEncode(body);

    late http.Response response;
    try {
      response = await _dispatch(
        method: method,
        uri: uri,
        headers: headers,
        body: encodedBody,
      ).timeout(_config.timeout);
    } on TimeoutException catch (error) {
      throw ApiException(
        type: ApiExceptionType.timeout,
        message: 'FastPay request timed out.',
        cause: error,
      );
    } on SocketException catch (error) {
      throw ApiException(
        type: ApiExceptionType.network,
        message: 'Unable to reach the FastPay API.',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        type: ApiExceptionType.network,
        message: 'HTTP client error while calling FastPay.',
        cause: error,
      );
    }

    if (response.statusCode == 401 &&
        retryOnUnauthorized &&
        _config.apiSecret != null &&
        _config.apiSecret!.isNotEmpty) {
      _accessToken = null;
      await _ensureAccessToken(forceRefresh: true);
      return _send(
        method: method,
        path: path,
        queryParameters: queryParameters,
        body: body,
        requiresAuth: requiresAuth,
        retryOnUnauthorized: false,
      );
    }

    final Map<String, dynamic> payload = _decodeJsonMap(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _mapError(statusCode: response.statusCode, payload: payload);
    }

    return payload;
  }

  Future<void> _ensureAccessToken({bool forceRefresh = false}) async {
    if (!forceRefresh && _accessToken != null && _accessToken!.isNotEmpty) {
      return;
    }

    final String? staticToken = _config.accessToken;
    if (staticToken != null &&
        staticToken.isNotEmpty &&
        (!forceRefresh ||
            _config.apiSecret == null ||
            _config.apiSecret!.isEmpty)) {
      _accessToken = staticToken;
      return;
    }

    if (_config.apiSecret == null || _config.apiSecret!.isEmpty) {
      throw ApiException.configuration(
        'FastPay requires either an accessToken or an apiSecret to call protected routes.',
      );
    }

    final Map<String, dynamic> authResponse = await _send(
      method: 'POST',
      path: _config.endpoints.authToken,
      requiresAuth: false,
      retryOnUnauthorized: false,
      body: <String, dynamic>{
        'api_key': _config.apiKey,
        'api_secret': _config.apiSecret,
      },
    );

    _accessToken = _extractAccessToken(authResponse);
    if (_accessToken == null || _accessToken!.isEmpty) {
      throw ApiException.parsing(
        'FastPay auth response did not include an access token.',
        details: authResponse,
      );
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
        throw ApiException.configuration(
          'Unsupported HTTP method "$method" for FastPay ApiClient.',
        );
    }
  }

  Map<String, String> _buildHeaders({
    required bool requiresAuth,
    required bool includeJsonContentType,
  }) {
    final Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
      ..._config.defaultHeaders,
    };

    if (includeJsonContentType) {
      headers['Content-Type'] = 'application/json';
    }

    headers.putIfAbsent('X-Public-Key', () => _config.apiKey);

    if (_config.merchantId != null && _config.merchantId!.isNotEmpty) {
      headers.putIfAbsent('X-Merchant-Id', () => _config.merchantId!);
    }

    if (requiresAuth) {
      final String? token = _accessToken ?? _config.accessToken;
      if (token == null || token.isEmpty) {
        throw ApiException.configuration(
          'FastPay attempted an authenticated request without a bearer token.',
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Map<String, dynamic> _decodeJsonMap(String body) {
    if (body.trim().isEmpty) {
      return const <String, dynamic>{};
    }

    try {
      final Object? decoded = jsonDecode(body);
      return asJsonMap(decoded) ?? <String, dynamic>{'data': decoded};
    } on FormatException catch (error) {
      throw ApiException(
        type: ApiExceptionType.parsing,
        message: 'FastPay returned malformed JSON.',
        cause: error,
      );
    }
  }

  ApiException _mapError({
    required int statusCode,
    required Map<String, dynamic> payload,
  }) {
    final String message =
        asString(payload['message']) ??
        asString(payload['error']) ??
        'FastPay request failed.';

    final ApiExceptionType type = switch (statusCode) {
      400 => ApiExceptionType.badRequest,
      401 => ApiExceptionType.unauthorized,
      403 => ApiExceptionType.forbidden,
      404 => ApiExceptionType.notFound,
      >= 500 => ApiExceptionType.server,
      _ => ApiExceptionType.unknown,
    };

    return ApiException(
      type: type,
      message: message,
      statusCode: statusCode,
      details: payload,
    );
  }

  String? _extractAccessToken(Map<String, dynamic> payload) {
    final Map<String, dynamic>? data = asJsonMap(payload['data']);

    return asString(payload['access_token']) ??
        asString(payload['token']) ??
        asString(data?['access_token']) ??
        asString(data?['token']) ??
        asString(data?['jwt']);
  }
}
