/// Configurable endpoint definitions for the FastPay backend.
class FastPayEndpoints {
  /// Creates a [FastPayEndpoints] instance.
  const FastPayEndpoints({
    this.authToken = '/auth/token',
    this.refreshToken = '/auth/refresh',
    this.createSession = '/payments/session',
    this.paymentDetailsTemplate = '/payments/{payment_id}',
    this.retryPaymentTemplate = '/payments/{payment_id}/retry',
    this.cancelPaymentTemplate = '/payments/{payment_id}/cancel',
  });

  /// Public auth endpoint used to exchange API credentials for a JWT.
  final String authToken;

  /// Public auth refresh endpoint.
  final String refreshToken;

  /// Protected endpoint that creates a payment session.
  final String createSession;

  /// Protected documented route that returns payment details.
  final String paymentDetailsTemplate;

  /// Protected documented route that retries an existing payment.
  final String retryPaymentTemplate;

  /// Protected documented route that cancels an existing payment.
  final String cancelPaymentTemplate;

  /// Returns a copy with the provided overrides.
  FastPayEndpoints copyWith({
    String? authToken,
    String? refreshToken,
    String? createSession,
    String? paymentDetailsTemplate,
    String? retryPaymentTemplate,
    String? cancelPaymentTemplate,
  }) {
    return FastPayEndpoints(
      authToken: authToken ?? this.authToken,
      refreshToken: refreshToken ?? this.refreshToken,
      createSession: createSession ?? this.createSession,
      paymentDetailsTemplate:
          paymentDetailsTemplate ?? this.paymentDetailsTemplate,
      retryPaymentTemplate: retryPaymentTemplate ?? this.retryPaymentTemplate,
      cancelPaymentTemplate:
          cancelPaymentTemplate ?? this.cancelPaymentTemplate,
    );
  }
}
