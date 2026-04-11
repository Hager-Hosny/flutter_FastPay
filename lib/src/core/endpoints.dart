/// Configurable endpoint definitions for the FastPay backend.
class FastPayEndpoints {
  /// Creates a [FastPayEndpoints] instance.
  const FastPayEndpoints({
    this.authToken = '/auth/token',
    this.refreshToken = '/auth/refresh',
    this.createSession = '/payments/session',
    this.processTransaction = '/payments/process-transaction',
    this.getTransactionStatus = '/payments/transaction-status',
    this.paymentDetailsTemplate = '/payments/{payment_id}',
    this.retryPayment = '/payments/retry',
    this.retryPaymentTemplate = '/payments/{payment_id}/retry',
  });

  /// Public auth endpoint used to exchange API credentials for a JWT.
  final String authToken;

  /// Public auth refresh endpoint.
  final String refreshToken;

  /// Protected endpoint that creates a payment session.
  final String createSession;

  /// Protected endpoint that processes a card payment for a session.
  ///
  /// TODO(Postman): confirm the exact path for transaction processing.
  final String processTransaction;

  /// Protected endpoint that looks up the latest transaction status.
  ///
  /// TODO(Postman): confirm the exact status lookup route and method.
  final String getTransactionStatus;

  /// Protected documented route that returns payment details.
  final String paymentDetailsTemplate;

  /// Protected retry endpoint when the backend uses a body-based route.
  ///
  /// TODO(Postman): confirm whether this route exists or if only the templated
  /// payment retry route is supported.
  final String retryPayment;

  /// Protected documented route that retries an existing payment.
  final String retryPaymentTemplate;

  /// Returns a copy with the provided overrides.
  FastPayEndpoints copyWith({
    String? authToken,
    String? refreshToken,
    String? createSession,
    String? processTransaction,
    String? getTransactionStatus,
    String? paymentDetailsTemplate,
    String? retryPayment,
    String? retryPaymentTemplate,
  }) {
    return FastPayEndpoints(
      authToken: authToken ?? this.authToken,
      refreshToken: refreshToken ?? this.refreshToken,
      createSession: createSession ?? this.createSession,
      processTransaction: processTransaction ?? this.processTransaction,
      getTransactionStatus: getTransactionStatus ?? this.getTransactionStatus,
      paymentDetailsTemplate:
          paymentDetailsTemplate ?? this.paymentDetailsTemplate,
      retryPayment: retryPayment ?? this.retryPayment,
      retryPaymentTemplate: retryPaymentTemplate ?? this.retryPaymentTemplate,
    );
  }
}
