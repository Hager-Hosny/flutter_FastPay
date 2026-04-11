# FastPay SDK API Reference Template

This document is the SDK-facing API contract template for the FastPay payment
flow. It is intentionally structured so the final request and response fields
can be confirmed from Postman and copied into the SDK mappings with minimal
rework.

Current public documentation confirms:

- Base URL: `https://api.fastpay.dpdns.org`
- Authentication model: `Authorization: Bearer <access_token>`
- Common envelope:

```json
{
  "status": "success",
  "message": "Human-readable summary",
  "data": {}
}
```

Critical identifiers to preserve across the flow:

- `session_id`
- `transaction_id`
- `status`

TODO(Postman): replace all placeholder fields and example payloads below with
the final backend contract from the active Postman collection.

## `createSession`

### Name
`createSession`

### Method
`POST`

### Path
`/payments/session`

### Headers
- `Authorization: Bearer <access_token>`
- `Content-Type: application/json`
- `Accept: application/json`
- `X-Public-Key: <api_key>` if required by gateway policy
- `X-Merchant-Id: <merchant_id>` if required by gateway policy

### Authentication
Protected route. Obtain access token from `POST /auth/token`.

### Request Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `amount` | `number` | Yes | Decimal amount. TODO(Postman): confirm precision and whether minor units are ever used. |
| `currency` | `string` | Yes | ISO currency code such as `EGP`. |
| `merchant_order_id` | `string` | No | Merchant-side order reference. |
| `customer` | `object` | No | Nested customer object. |
| `customer.name` | `string` | TODO | TODO(Postman): confirm if required. |
| `customer.email` | `string` | TODO | TODO(Postman): confirm if required. |
| `customer.phone` | `string` | TODO | TODO(Postman): confirm format rules. |
| `metadata` | `object` | No | Arbitrary merchant metadata. |
| `redirect_url` | `string` | No | Redirect target after hosted/redirect flow. |
| `callback_url` | `string` | No | Server-side callback endpoint. |
| `source` | `string` | No | SDK source marker such as `sdk`. |

### Response Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `status` | `string` | Yes | Envelope status and/or session status. TODO(Postman): confirm exact location. |
| `message` | `string` | No | Human-readable summary. |
| `data.session_id` | `string` | Yes | Primary session identifier. |
| `data.payment_id` | `string` | TODO | TODO(Postman): confirm if returned at session creation time. |
| `data.status` | `string` | Yes | Session lifecycle state. |
| `data.amount` | `number` | No | Echoed amount. |
| `data.currency` | `string` | No | Echoed currency. |
| `data.merchant_order_id` | `string` | No | Echoed merchant order reference. |
| `data.checkout_url` | `string` | TODO | TODO(Postman): confirm hosted checkout or redirect field name. |
| `data.redirect_url` | `string` | TODO | TODO(Postman): confirm if response includes it. |
| `data.customer` | `object` | No | Echoed or normalized customer details. |
| `data.metadata` | `object` | No | Echoed metadata. |

### Important IDs
- `session_id`: required for card processing and retry orchestration.
- `payment_id`: optional until Postman confirms if this exists at this stage.

### Status Values
- Known examples: `created`, `pending`
- TODO(Postman): finalize full session status enum.

### Error Responses

| HTTP Code | Meaning | Notes |
| --- | --- | --- |
| `400` | Invalid payload | Missing amount, invalid currency, malformed customer data. |
| `401` | Unauthorized | Missing or invalid bearer token. |
| `422` | Validation error | TODO(Postman): confirm if backend uses `422`. |
| `500` | Server error | Unexpected processing failure. |

### Example Request

```json
{
  "amount": 1500.00,
  "currency": "EGP",
  "merchant_order_id": "ORD-10001",
  "customer": {
    "name": "Elmira Stokes",
    "email": "elmira@example.com",
    "phone": "605-590-6006"
  },
  "metadata": {
    "channel": "mobile_sdk"
  },
  "redirect_url": "https://example.com/payment/redirect",
  "callback_url": "https://example.com/payment/callback",
  "source": "sdk"
}
```

### Example Response

```json
{
  "status": "success",
  "message": "Payment session created",
  "data": {
    "session_id": "sess_123456",
    "payment_id": "pay_123456",
    "status": "created",
    "amount": 1500.0,
    "currency": "EGP",
    "merchant_order_id": "ORD-10001",
    "checkout_url": "https://checkout.fastpay.example/session/sess_123456",
    "customer": {
      "name": "Elmira Stokes",
      "email": "elmira@example.com",
      "phone": "605-590-6006"
    }
  }
}
```

## `processTransaction`

### Name
`processTransaction`

### Method
`POST`

### Path
`/payments/process-transaction`

TODO(Postman): confirm whether the real path is body-driven, `/payments/process-transaction`,
`/payments/process`, or another Spring mapping.

### Headers
- `Authorization: Bearer <access_token>`
- `Content-Type: application/json`
- `Accept: application/json`

### Authentication
Protected route.

### Request Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `session_id` | `string` | Yes | Session identifier returned by `createSession`. |
| `payment_method` | `string` | Yes | Typically `card`. TODO(Postman): confirm enum. |
| `merchant_order_id` | `string` | No | Optional merchant reference. |
| `amount` | `number` | No | Optional amount override if backend expects it. |
| `currency` | `string` | No | Optional currency echo. |
| `customer` | `object` | No | Optional customer context. |
| `save_card` | `boolean` | No | TODO(Postman): confirm card vaulting support. |
| `metadata` | `object` | No | Merchant metadata. |
| `card_details` | `object` | Yes | Card payload for direct processing. |
| `card_details.number` | `string` | Yes | Card PAN. |
| `card_details.expiry_month` | `number` | Yes | Card expiry month. |
| `card_details.expiry_year` | `number` | Yes | Card expiry year. |
| `card_details.cvv` | `string` | Yes | CVV/CVC code. |
| `card_details.cardholder_name` | `string` | Yes | Printed cardholder name. |
| `card_details.token` | `string` | No | Tokenized card reference if supported. |

### Response Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `status` | `string` | Yes | Envelope status and/or transaction status. |
| `message` | `string` | No | Gateway response text. |
| `data.transaction_id` | `string` | Yes | Primary transaction identifier. |
| `data.session_id` | `string` | Yes | Parent session identifier. |
| `data.payment_id` | `string` | TODO | TODO(Postman): confirm field availability. |
| `data.status` | `string` | Yes | Transaction state. |
| `data.amount` | `number` | No | Processed amount. |
| `data.currency` | `string` | No | Processed currency. |
| `data.card_details` | `object` | No | Safe card summary fields only. |
| `data.card_details.last4` | `string` | No | Last four digits. |
| `data.card_details.brand` | `string` | No | Card brand. |
| `data.redirect_url` | `string` | TODO | TODO(Postman): confirm if 3DS or redirect flows return a URL. |

### Important IDs
- `session_id`
- `transaction_id`
- `payment_id` if returned

### Status Values
- Known examples: `authorized`, `approved`, `pending`, `failed`
- TODO(Postman): finalize success, pending, challenge, and failure enums.

### Error Responses

| HTTP Code | Meaning | Notes |
| --- | --- | --- |
| `400` | Invalid request | Malformed session or card payload. |
| `401` | Unauthorized | Missing or invalid token. |
| `402` | Payment failure | TODO(Postman): confirm whether backend uses `402` or `200` with failed status. |
| `422` | Validation error | Invalid card details or unsupported currency. |
| `500` | Server error | Gateway or orchestration failure. |

### Example Request

```json
{
  "session_id": "sess_123456",
  "payment_method": "card",
  "merchant_order_id": "ORD-10001",
  "card_details": {
    "number": "4242424242424242",
    "expiry_month": 12,
    "expiry_year": 2030,
    "cvv": "123",
    "cardholder_name": "Elmira Stokes"
  }
}
```

### Example Response

```json
{
  "status": "success",
  "message": "Transaction processed",
  "data": {
    "transaction_id": "txn_123456",
    "session_id": "sess_123456",
    "payment_id": "pay_123456",
    "status": "authorized",
    "amount": 1500.0,
    "currency": "EGP",
    "card_details": {
      "last4": "4242",
      "brand": "visa"
    }
  }
}
```

## `getTransactionStatus`

### Name
`getTransactionStatus`

### Method
Primary template: `POST`

Fallback documented lookup: `GET /payments/{payment_id}`

### Path
Primary template: `/payments/transaction-status`

Fallback documented route: `/payments/{payment_id}`

TODO(Postman): confirm whether status lookup is transaction-based, payment-based,
or whether both routes are valid.

### Headers
- `Authorization: Bearer <access_token>`
- `Content-Type: application/json` for `POST`
- `Accept: application/json`

### Authentication
Protected route.

### Request Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `transaction_id` | `string` | TODO | Required if lookup is transaction-based. |
| `session_id` | `string` | TODO | Optional fallback context. |
| `payment_id` | `string` | TODO | Used when lookup is payment-based. |

### Response Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `status` | `string` | Yes | Envelope status and/or payment status. |
| `message` | `string` | No | Human-readable summary. |
| `data.transaction_id` | `string` | TODO | Confirm when payment-based lookup is used. |
| `data.session_id` | `string` | TODO | Parent session identifier. |
| `data.payment_id` | `string` | TODO | Payment identifier. |
| `data.status` | `string` | Yes | Latest transaction/payment state. |
| `data.amount` | `number` | No | Processed amount. |
| `data.currency` | `string` | No | Currency code. |
| `data.updated_at` | `string` | No | TODO(Postman): confirm timestamp format. |
| `data.message` | `string` | No | Gateway detail if present. |

### Important IDs
- `transaction_id`
- `payment_id`
- `session_id`

### Status Values
- Known examples: `pending`, `processing`, `authorized`, `completed`, `failed`
- TODO(Postman): confirm terminal vs intermediate states.

### Error Responses

| HTTP Code | Meaning | Notes |
| --- | --- | --- |
| `400` | Invalid identifier payload | Missing identifiers or malformed request body. |
| `401` | Unauthorized | Missing or invalid token. |
| `404` | Not found | Transaction or payment not found. |
| `500` | Server error | Status lookup failure. |

### Example Request

```json
{
  "transaction_id": "txn_123456",
  "session_id": "sess_123456"
}
```

### Example Response

```json
{
  "status": "success",
  "message": "Transaction status retrieved",
  "data": {
    "transaction_id": "txn_123456",
    "session_id": "sess_123456",
    "payment_id": "pay_123456",
    "status": "completed",
    "amount": 1500.0,
    "currency": "EGP",
    "updated_at": "2026-04-11T12:00:00Z"
  }
}
```

## `retryPayment`

### Name
`retryPayment`

### Method
Primary template: `POST`

### Path
Preferred documented route: `/payments/{payment_id}/retry`

Fallback template: `/payments/retry`

TODO(Postman): confirm whether retries are payment-based only or whether the
body-based fallback exists in the backend.

### Headers
- `Authorization: Bearer <access_token>`
- `Content-Type: application/json`
- `Accept: application/json`

### Authentication
Protected route.

### Request Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `payment_id` | `string` | TODO | Required when using the templated route. |
| `transaction_id` | `string` | No | Original failed transaction. |
| `session_id` | `string` | No | Original session identifier. |
| `payment_method` | `string` | No | Usually `card`. |
| `card_details` | `object` | TODO | TODO(Postman): confirm whether fresh card data is accepted on retry. |
| `metadata` | `object` | No | Merchant retry context. |

### Response Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `status` | `string` | Yes | Envelope status and/or retry status. |
| `message` | `string` | No | Retry summary. |
| `data.transaction_id` | `string` | Yes | TODO(Postman): confirm whether this is new or reused. |
| `data.session_id` | `string` | No | Parent session identifier. |
| `data.payment_id` | `string` | No | Payment identifier. |
| `data.status` | `string` | Yes | Current retry state. |
| `data.amount` | `number` | No | Retry amount. |
| `data.currency` | `string` | No | Retry currency. |
| `data.card_details` | `object` | No | Safe card summary. |

### Important IDs
- `payment_id`
- `transaction_id`
- `session_id`

### Status Values
- Known examples: `pending`, `authorized`, `failed`
- TODO(Postman): confirm if retry introduces new statuses such as `retrying`.

### Error Responses

| HTTP Code | Meaning | Notes |
| --- | --- | --- |
| `400` | Invalid retry request | Missing identifiers or invalid status for retry. |
| `401` | Unauthorized | Missing or invalid token. |
| `404` | Not found | Payment or transaction not found. |
| `409` | Conflict | Retry not allowed from current state. |
| `500` | Server error | Retry orchestration failure. |

### Example Request

```json
{
  "transaction_id": "txn_123456",
  "session_id": "sess_123456",
  "payment_method": "card",
  "card_details": {
    "number": "4242424242424242",
    "expiry_month": 12,
    "expiry_year": 2030,
    "cvv": "123",
    "cardholder_name": "Elmira Stokes"
  }
}
```

### Example Response

```json
{
  "status": "success",
  "message": "Payment retried",
  "data": {
    "transaction_id": "txn_987654",
    "session_id": "sess_123456",
    "payment_id": "pay_123456",
    "status": "pending",
    "amount": 1500.0,
    "currency": "EGP"
  }
}
```
