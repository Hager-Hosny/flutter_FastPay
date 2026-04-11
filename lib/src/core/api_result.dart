import 'api_exception.dart';

/// A typed wrapper around SDK operations that may succeed or fail.
class ApiResult<T> {
  const ApiResult._({this.data, this.exception});

  /// Successful payload.
  final T? data;

  /// Failure details.
  final ApiException? exception;

  /// Whether the operation completed successfully.
  bool get isSuccess => exception == null;

  /// Returns the successful payload or throws the contained exception.
  T requireData() {
    if (data != null) {
      return data as T;
    }

    throw exception ??
        const ApiException(
          type: ApiExceptionType.unknown,
          message: 'FastPay operation failed without an exception payload.',
        );
  }

  /// Creates a successful [ApiResult].
  factory ApiResult.success(T data) => ApiResult<T>._(data: data);

  /// Creates a failed [ApiResult].
  factory ApiResult.failure(ApiException exception) {
    return ApiResult<T>._(exception: exception);
  }
}
