import 'api_exception.dart';

class Validators {
  static void requireNotBlank(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw ValidationApiException(
        message: '$fieldName is required.',
        fieldErrors: <String, String>{fieldName: 'Field is required'},
      );
    }
  }

  static void requirePositiveAmount(double amount, {String fieldName = 'amount'}) {
    if (amount <= 0) {
      throw ValidationApiException(
        message: '$fieldName must be greater than 0.',
        fieldErrors: <String, String>{
          fieldName: 'Value must be greater than 0',
        },
      );
    }
  }

  static void requireCurrency(String currency) {
    requireNotBlank(currency, 'currency');

    final String normalized = currency.trim();
    final RegExp pattern = RegExp(r'^[A-Za-z]{3}$');
    if (!pattern.hasMatch(normalized)) {
      throw ValidationApiException(
        message: 'currency must be a 3-letter ISO code.',
        fieldErrors: const <String, String>{
          'currency': 'Expected a 3-letter ISO currency code',
        },
      );
    }
  }

  static void requirePage(int page) {
    if (page < 0) {
      throw ValidationApiException(
        message: 'page must be 0 or greater.',
        fieldErrors: const <String, String>{
          'page': 'Expected a non-negative page index',
        },
      );
    }
  }

  static void requireSize(int size) {
    if (size <= 0 || size > 100) {
      throw ValidationApiException(
        message: 'size must be between 1 and 100.',
        fieldErrors: const <String, String>{
          'size': 'Expected a value between 1 and 100',
        },
      );
    }
  }

  static void requireDateRange(DateTime from, DateTime to) {
    if (from.isAfter(to)) {
      throw ValidationApiException(
        message: 'from must be before or equal to to.',
        fieldErrors: const <String, String>{
          'from': 'Must be before or equal to to',
        },
      );
    }
  }
}
