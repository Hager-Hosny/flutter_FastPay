/// Categories used for typed API failures.
enum ApiExceptionType {
  validation,
  authentication,
  authorization,
  notFound,
  businessRule,
  network,
  timeout,
  parsing,
  configuration,
  server,
  unknown,
}

/// Base typed exception surfaced by the FastPay SDK.
class ApiException implements Exception {
  ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.errorCode,
    this.fieldErrors = const <String, String>{},
    this.requestId,
    this.rawPayload,
    this.cause,
  });

  final ApiExceptionType type;
  final String message;
  final int? statusCode;
  final String? errorCode;
  final Map<String, String> fieldErrors;
  final String? requestId;
  final Map<String, dynamic>? rawPayload;
  final Object? cause;

  @override
  String toString() {
    final String status = statusCode == null ? '' : ' status=$statusCode';
    final String code = errorCode == null ? '' : ' code=$errorCode';
    final String request = requestId == null ? '' : ' requestId=$requestId';
    return 'ApiException[$type$status$code$request]: $message';
  }
}

class ValidationApiException extends ApiException {
  ValidationApiException({
    required super.message,
    super.statusCode,
    super.errorCode,
    super.fieldErrors,
    super.requestId,
    super.rawPayload,
    super.cause,
  }) : super(type: ApiExceptionType.validation);
}

class AuthenticationApiException extends ApiException {
  AuthenticationApiException({
    required super.message,
    super.statusCode,
    super.errorCode,
    super.fieldErrors,
    super.requestId,
    super.rawPayload,
    super.cause,
  }) : super(type: ApiExceptionType.authentication);
}

class AuthorizationApiException extends ApiException {
  AuthorizationApiException({
    required super.message,
    super.statusCode,
    super.errorCode,
    super.fieldErrors,
    super.requestId,
    super.rawPayload,
    super.cause,
  }) : super(type: ApiExceptionType.authorization);
}

class NotFoundApiException extends ApiException {
  NotFoundApiException({
    required super.message,
    super.statusCode,
    super.errorCode,
    super.fieldErrors,
    super.requestId,
    super.rawPayload,
    super.cause,
  }) : super(type: ApiExceptionType.notFound);
}

class BusinessRuleApiException extends ApiException {
  BusinessRuleApiException({
    required super.message,
    super.statusCode,
    super.errorCode,
    super.fieldErrors,
    super.requestId,
    super.rawPayload,
    super.cause,
  }) : super(type: ApiExceptionType.businessRule);
}

class NetworkApiException extends ApiException {
  NetworkApiException({
    required super.message,
    super.statusCode,
    super.errorCode,
    super.fieldErrors,
    super.requestId,
    super.rawPayload,
    super.cause,
  }) : super(type: ApiExceptionType.network);
}

class TimeoutApiException extends ApiException {
  TimeoutApiException({
    required super.message,
    super.statusCode,
    super.errorCode,
    super.fieldErrors,
    super.requestId,
    super.rawPayload,
    super.cause,
  }) : super(type: ApiExceptionType.timeout);
}

class ParsingApiException extends ApiException {
  ParsingApiException({
    required super.message,
    super.statusCode,
    super.errorCode,
    super.fieldErrors,
    super.requestId,
    super.rawPayload,
    super.cause,
  }) : super(type: ApiExceptionType.parsing);
}

class ConfigurationApiException extends ApiException {
  ConfigurationApiException({
    required super.message,
    super.statusCode,
    super.errorCode,
    super.fieldErrors,
    super.requestId,
    super.rawPayload,
    super.cause,
  }) : super(type: ApiExceptionType.configuration);
}

class ServerApiException extends ApiException {
  ServerApiException({
    required super.message,
    super.statusCode,
    super.errorCode,
    super.fieldErrors,
    super.requestId,
    super.rawPayload,
    super.cause,
  }) : super(type: ApiExceptionType.server);
}

class UnknownApiException extends ApiException {
  UnknownApiException({
    required super.message,
    super.statusCode,
    super.errorCode,
    super.fieldErrors,
    super.requestId,
    super.rawPayload,
    super.cause,
  }) : super(type: ApiExceptionType.unknown);
}
