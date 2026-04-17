# fastpay_sdk

`fastpay_sdk` is a Flutter package that wraps the current FastPay backend
contract around payment session creation, hosted checkout orchestration,
payment lookup, and typed result handling.

## Features

- `FastPay.initialize(...)` for one-time SDK setup
- `FastPay.payments.createSession(...)`
- `FastPay.payments.getPayment(...)`
- `FastPay.payments.retryPayment(...)`
- `FastPay.payments.cancelPayment(...)`
- `FastPayCheckout.show(...)` for an embedded SDK checkout experience
- Typed models for sessions, payments, customers, and payment results
- Typed exceptions and clean service/core separation
- Internal checkout flow with loading, ready, processing, success, failure,
  and pending states

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  fastpay_sdk:
    path: ../flutter_FastPay
```

Then run:

```bash
flutter pub get
```

## Initialization

Initialize once before using any FastPay API or UI flow:

```dart
import 'package:fastpay_sdk/fastpay_sdk.dart';

void main() {
  FastPay.initialize(
    const FastPayConfig(
      baseUrl: 'https://api.fastpay.dpdns.org',
      apiKey: 'pk_test_replace_me',
      accessToken: 'backend_issued_access_token',
      merchantId: 'merchant_123',
    ),
  );
}
```

For production mobile apps, prefer a backend-issued `accessToken` over putting
`apiSecret` inside the app.

## Checkout Usage

```dart
final result = await FastPayCheckout.show(
  context,
  amount: 150.0,
  currency: 'EGP',
  customer: const Customer(
    name: 'Elmira Stokes',
    email: 'elmira@example.com',
    phone: '605-590-6006',
  ),
  merchantOrderId: 'ORD-10001',
  checkoutUrl: 'https://merchant.example.com/checkout',
  callbackUrl: 'https://merchant.example.com/api/fastpay/callback',
);

if (result.isSuccess) {
  debugPrint('Payment succeeded: ${result.transaction?.transactionId}');
} else if (result.isPending) {
  debugPrint('Payment pending: ${result.status}');
} else {
  debugPrint('Payment failed: ${result.errorMessage}');
}
```

## Direct API Usage

```dart
final session = await FastPay.payments.createSession(
  amount: 150.0,
  currency: 'EGP',
  customer: const Customer(
    name: 'Elmira Stokes',
    email: 'elmira@example.com',
    phone: '605-590-6006',
  ),
  merchantOrderId: 'ORD-10001',
  checkoutUrl: 'https://merchant.example.com/checkout',
  callbackUrl: 'https://merchant.example.com/api/fastpay/callback',
);

final payment = await FastPay.payments.getPayment(
  paymentId: session.paymentId!,
);

final latestStatus = await FastPay.payments.retryPayment(
  paymentId: session.paymentId!,
  redirectUrl: 'https://merchant.example.com/result',
  callbackUrl: 'https://merchant.example.com/api/fastpay/callback',
);
```

## Architecture Overview

The package is organized into clean layers under `lib/src/`:

- `core/`: SDK configuration, singleton entry point, API client, endpoints, typed errors
- `models/`: immutable domain models with `fromJson`, `toJson`, `copyWith`, and equality
- `services/`: typed API contract and backend-backed payment service
- `flow/`: checkout orchestration and internal state machine
- `ui/`: checkout page and result view
- `utils/`: parsing helpers and input formatters

Rules followed by the implementation:

- Raw JSON stays inside `core/` and `services/`
- UI does not perform payment logic
- Payment orchestration lives in a separate flow controller
- API responses are converted into typed Dart models
- Errors use typed exceptions and result objects

## Backend Contract Note

The current backend contract is centered around:

- `POST /payments/session`
- `GET /payments/{payment_id}`
- `POST /payments/{payment_id}/retry`
- `POST /payments/{payment_id}/cancel`

The SDK also attaches tracing headers on every request:

- `X-Client-Source`
- `X-SDK-Version`
- `X-Platform`
- `X-Request-Id`

These headers are for observability only, not for authentication.

## Development Notes

- The SDK will automatically exchange `apiKey` + `apiSecret` for a bearer token
  using `POST /auth/token` when `accessToken` is not supplied.
- For mobile production usage, prefer short-lived tokens issued by your backend.
- The included example uses placeholder merchant URLs and should be updated with
  real endpoints before live API testing.
