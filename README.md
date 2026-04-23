# fastpay_sdk

`fastpay_sdk` is the Flutter client for the FastPay backend. It wraps the current `fastpay-apis` contract with typed models, typed exceptions, token storage hooks, and a hosted checkout helper.

## Features

- `FastPay.auth` for login, refresh, logout, and token inspection
- `FastPay.payments` for payment methods, session creation, payment lookup, retry, and cancel
- `FastPay.transactions` for paginated transaction lists and summaries
- `FastPay.refunds` and `FastPay.payouts`
- Built-in request validation before network calls
- Structured exceptions with status code, error code, field errors, and request ID
- In-memory token storage by default with pluggable `TokenStore`
- `FastPayCheckout.show(...)` for the hosted checkout flow

## Installation

```yaml
dependencies:
  fastpay_sdk:
    path: ../flutter_FastPay
```

Then run:

```bash
flutter pub get
```

## Initialize the SDK

```dart
import 'package:fastpay_sdk/fastpay_sdk.dart';

void main() {
  FastPay.initialize(
    const FastPayConfig(
      baseUrl: 'http://localhost:8080',
      apiKey: 'pk_test_replace_me',
      apiSecret: 'sk_test_replace_me',
    ),
  );
}
```

For production mobile apps, do not hardcode long-lived merchant secrets in the app. Prefer issuing access tokens from your backend or using a secure token exchange flow.

## Authentication

```dart
final TokenPair tokens = await FastPay.auth.login();

final TokenPair refreshed = await FastPay.auth.refresh();

final TokenPair? current = await FastPay.auth.currentTokens();

await FastPay.auth.logout();
```

The SDK stores tokens in the configured `TokenStore` and automatically tries one refresh after a `401` on authenticated requests.

## Payments

List enabled payment methods:

```dart
final methods = await FastPay.payments.listMethods();
```

Create a payment session:

```dart
final session = await FastPay.payments.createSession(
  amount: 150.0,
  currency: 'EGP',
  customer: const Customer(
    name: 'Elmira Stokes',
    email: 'elmira@example.com',
    phone: '+201000000000',
  ),
  merchantOrderId: 'ORD-10001',
  callbackUrl: 'https://merchant.example.com/api/payment/callback',
  redirectUrl: 'https://merchant.example.com/payment/result',
  metadata: const <String, dynamic>{
    'channel': 'mobile',
  },
);

debugPrint(session.paymentId);
debugPrint(session.checkoutUrl);
```

Get payment details:

```dart
final payment = await FastPay.payments.getPayment(
  paymentId: session.paymentId!,
);
```

Retry a failed payment:

```dart
final retry = await FastPay.payments.retryPayment(
  paymentId: session.paymentId!,
  paymentMethod: 'card',
  callbackUrl: 'https://merchant.example.com/api/payment/callback',
  redirectUrl: 'https://merchant.example.com/payment/result',
);
```

Cancel a payment:

```dart
final cancelled = await FastPay.payments.cancelPayment(
  paymentId: session.paymentId!,
);
```

## Transactions

Get a paginated list:

```dart
final page = await FastPay.transactions.list(page: 0, size: 10);
```

Get a summary:

```dart
final summary = await FastPay.transactions.summary(
  from: DateTime(2026, 4, 1),
  to: DateTime(2026, 4, 30),
  currency: 'EGP',
);
```

## Refunds

```dart
final refund = await FastPay.refunds.create(
  transactionId: 11,
  amount: '50.00',
  currency: 'EGP',
  reason: 'Customer requested refund',
  callbackUrl: 'https://merchant.example.com/api/refunds/callback',
);
```

## Payouts

```dart
final payout = await FastPay.payouts.create(
  amount: 100.0,
  currency: 'EGP',
  destinationType: 'bank_account',
  destinationDetails: const <String, dynamic>{
    'bank_name': 'Example Bank',
    'iban': 'EG380019000500000000263180002',
  },
  metadata: const <String, dynamic>{
    'purpose': 'vendor settlement',
  },
);
```

## Hosted Checkout Flow

```dart
final PaymentResult result = await FastPayCheckout.show(
  context,
  amount: 150.0,
  currency: 'EGP',
  customer: const Customer(
    name: 'Elmira Stokes',
    email: 'elmira@example.com',
    phone: '+201000000000',
  ),
  merchantOrderId: 'ORD-10001',
  callbackUrl: 'https://merchant.example.com/api/payment/callback',
  redirectUrl: 'https://merchant.example.com/payment/result',
);

if (result.isSuccess) {
  debugPrint('Payment succeeded: ${result.payment?.paymentId}');
} else if (result.isPending) {
  debugPrint('PaymeFlutter package
￼README.md: removed webhook usage/docs and added note that webhook delivery is automatic by backend jobs
￼api_reference.md: removed webhook client docs
￼api.blade.php: removed webhook mnt pending: ${result.status}');
} else {
  debugPrint('Payment failed: ${result.errorMessage}');
}
```

The backend generates `checkout_url`. The optional legacy checkout URL argument is ignored when the API response already includes `checkout_url`.

## Token Storage

The default store is in-memory:

```dart
final TokenStore store = InMemoryTokenStore();
```

You can provide a custom store with `FastPayConfig.tokenStore`.

## Error Handling

```dart
try {
  await FastPay.transactions.list(page: -1);
} on ValidationApiException catch (error) {
  debugPrint(error.fieldErrors.toString());
} on AuthenticationApiException catch (error) {
  debugPrint('Authentication failed: ${error.message}');
} on ApiException catch (error) {
  debugPrint('FastPay error: $error');
}
```

## Covered Backend Routes

- `POST /auth/token`
- `POST /auth/refresh`
- `POST /auth/logout`
- `GET /payment-methods`
- `POST /payments/session`
- `GET /payments/{payment_id}`
- `POST /payments/{payment_id}/retry`
- `POST /payments/{payment_id}/cancel`
- `GET /transactions`
- `GET /transactions/summary`
- `POST /refunds`
- `POST /payouts`

## Notes

- The SDK mirrors the current FastPay backend contract from `fastpay-apis`.
- The included example app should be configured with real credentials before live testing.
- Webhook delivery is handled automatically by backend jobs, so webhook endpoints are not exposed through the Flutter SDK.
- If your Laravel merchant project owns the API keys, keep credential exchange on the server and let Flutter consume short-lived tokens only.
