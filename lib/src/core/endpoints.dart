/// Configurable endpoint definitions for the FastPay backend.
class FastPayEndpoints {
  const FastPayEndpoints({
    this.authToken = '/auth/token',
    this.refreshToken = '/auth/refresh',
    this.logout = '/auth/logout',
    this.paymentMethods = '/payment-methods',
    this.createSession = '/payments/session',
    this.paymentDetailsTemplate = '/payments/{payment_id}',
    this.retryPaymentTemplate = '/payments/{payment_id}/retry',
    this.cancelPaymentTemplate = '/payments/{payment_id}/cancel',
    this.transactions = '/transactions',
    this.transactionsSummary = '/transactions/summary',
    this.refunds = '/refunds',
    this.payouts = '/payouts',
  });

  final String authToken;
  final String refreshToken;
  final String logout;
  final String paymentMethods;
  final String createSession;
  final String paymentDetailsTemplate;
  final String retryPaymentTemplate;
  final String cancelPaymentTemplate;
  final String transactions;
  final String transactionsSummary;
  final String refunds;
  final String payouts;

  String paymentDetails(String paymentId) =>
      paymentDetailsTemplate.replaceFirst('{payment_id}', paymentId);

  String retryPayment(String paymentId) =>
      retryPaymentTemplate.replaceFirst('{payment_id}', paymentId);

  String cancelPayment(String paymentId) =>
      cancelPaymentTemplate.replaceFirst('{payment_id}', paymentId);

  FastPayEndpoints copyWith({
    String? authToken,
    String? refreshToken,
    String? logout,
    String? paymentMethods,
    String? createSession,
    String? paymentDetailsTemplate,
    String? retryPaymentTemplate,
    String? cancelPaymentTemplate,
    String? transactions,
    String? transactionsSummary,
    String? refunds,
    String? payouts,
  }) {
    return FastPayEndpoints(
      authToken: authToken ?? this.authToken,
      refreshToken: refreshToken ?? this.refreshToken,
      logout: logout ?? this.logout,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      createSession: createSession ?? this.createSession,
      paymentDetailsTemplate:
          paymentDetailsTemplate ?? this.paymentDetailsTemplate,
      retryPaymentTemplate: retryPaymentTemplate ?? this.retryPaymentTemplate,
      cancelPaymentTemplate:
          cancelPaymentTemplate ?? this.cancelPaymentTemplate,
      transactions: transactions ?? this.transactions,
      transactionsSummary: transactionsSummary ?? this.transactionsSummary,
      refunds: refunds ?? this.refunds,
      payouts: payouts ?? this.payouts,
    );
  }
}
