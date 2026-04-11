# fastpay_sdk

`fastpay_sdk` is a production-style Flutter package that wraps FastPay payment
session creation, transaction processing, checkout UI, flow orchestration, and
typed results behind a small merchant-facing API.

## Features

- `FastPay.initialize(...)` for one-time SDK setup
- `FastPay.payments.createSession(...)`
- `FastPay.payments.processPayment(...)`
- `FastPay.payments.getStatus(...)`
- `FastPay.payments.retryPayment(...)`
- `FastPayCheckout.show(...)` for an embedded SDK checkout experience
- Typed models for sessions, transactions, customers, cards, and payment results
- Typed exceptions and clean service/core separation
- Internal stateful checkout flow with loading, ready, processing, success,
  failure, and pending states
- Extensible TODO-marked backend mappings for fields that still need Postman
  confirmation

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  fastpay_sdk:
    path: ../fastpay_sdk
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
      apiSecret: 'sk_test_replace_me',
      merchantId: 'merchant_123',
    ),
  );
}
```

You can also provide a pre-issued `accessToken` instead of `apiSecret` if your
backend handles token exchange outside the SDK.

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
  merchantOrderId: 'ORD-10001',
);

final transaction = await FastPay.payments.processPayment(
  sessionId: session.sessionId!,
  cardDetails: const CardDetails(
    number: '4242424242424242',
    expiryMonth: 12,
    expiryYear: 2030,
    cvv: '123',
    cardholderName: 'Elmira Stokes',
  ),
);

final latestStatus = await FastPay.payments.getStatus(
  transactionId: transaction.transactionId,
  paymentId: transaction.paymentId,
  sessionId: transaction.sessionId,
);
```

## Architecture Overview

The package is organized into clean layers under `lib/src/`:

- `core/`: SDK configuration, singleton entry point, API client, endpoints, typed errors
- `models/`: immutable domain models with `fromJson`, `toJson`, `copyWith`, and equality
- `services/`: typed API contract and backend-backed payment service
- `flow/`: checkout orchestration and internal state machine
- `ui/`: checkout page, card form, and result view
- `utils/`: parsing helpers and input formatters

Rules followed by the implementation:

- Raw JSON stays inside `core/` and `services/`
- UI does not perform HTTP requests
- Payment orchestration lives in a separate flow controller
- API responses are converted into typed Dart models
- Errors use typed exceptions and result objects

## Backend Contract Note

The public docs at `https://fastpay.dpdns.org/docs` confirm the base URL,
authentication model, and the `/payments/session` and `/payments/{payment_id}/retry`
style routes. Some transaction-processing details are still inferred from the
Postman collection and screenshoted routes.

Before shipping to production, replace the TODO-marked placeholder mappings in:

- `docs/api_reference.md`
- `lib/src/core/endpoints.dart`
- `lib/src/services/fastpay_payment_service.dart`
- `lib/src/models/`

with the exact field names, status enums, and route shapes from the final
Postman contract.

## Development Notes

- The SDK will automatically exchange `apiKey` + `apiSecret` for a bearer token
  using `POST /auth/token` when `accessToken` is not supplied.
- Sensitive card data is handled only in memory and is not surfaced in result
  models beyond safe fields such as `last4`.
- The included example uses placeholder credentials and should be updated with
  real merchant credentials before live API testing.
