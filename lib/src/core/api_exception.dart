/// Categories used for typed API failures.
enum ApiExceptionType {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  timeout,
  network,
  parsing,
  configuration,
  server,
  unknown,
}

/// Typed exception surfaced by the FastPay SDK.
class ApiException implements Exception {
  /// Creates an [ApiException].
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.details,
    this.cause,
  });

  /// The error category.
  final ApiExceptionType type;

  /// Human-readable description.
  final String message;

  /// Optional HTTP status code.
  final int? statusCode;

  /// Optional error details payload.
  final Map<String, dynamic>? details;

  /// Optional underlying cause.
  final Object? cause;

  /// Creates a configuration failure.
  factory ApiException.configuration(String message) {
    return ApiException(type: ApiExceptionType.configuration, message: message);
  }

  /// Creates a parsing failure.
  factory ApiException.parsing(
    String message, {
    Map<String, dynamic>? details,
  }) {
    return ApiException(
      type: ApiExceptionType.parsing,
      message: message,
      details: details,
    );
  }

  @override
  String toString() {
    final String code = statusCode == null ? '' : ' (statusCode: $statusCode)';
    return 'ApiException[$type]$code: $message';
  }
}
