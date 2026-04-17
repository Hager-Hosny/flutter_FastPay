# FastPay SDK API Reference

This package is aligned to the current FastPay backend contract in
`fastpay-apis`.

## Supported Endpoints

- `POST /auth/token`
- `POST /payments/session`
- `GET /payments/{payment_id}`
- `POST /payments/{payment_id}/retry`
- `POST /payments/{payment_id}/cancel`

## Request Headers

The SDK sends these headers on every request:

- `Accept: application/json`
- `Authorization: Bearer <access_token>` for protected routes
- `X-Public-Key: <api_key>`
- `X-Client-Source: flutter_sdk`
- `X-SDK-Version: <sdk_version>`
- `X-Platform: <platform>`
- `X-Request-Id: <generated_request_id>`

These headers are for observability only. They are not a security boundary.

## `createSession`

### Method and Path

`POST /payments/session`

### Required Request Fields

- `amount`
- `currency`
- `merchant_order_id`
- `customer`
- `checkout_url`
- `callback_url`

### Optional Request Fields

- `redirect_url`
- `metadata`

### Example Response

```json
{
  "status": "success",
  "message": "Payment session created",
  "data": {
    "payment_id": "pay_123",
    "reference": "ref_123",
    "status": "created",
    "checkout_url": "https://merchant.example.com/checkout/pay_123"
  }
}
```

## `getPayment`

### Method and Path

`GET /payments/{payment_id}`

### Example Response

```json
{
  "status": "success",
  "message": "Payment retrieved successfully",
  "data": {
    "id": 11,
    "external_reference": "pay_123",
    "provider_reference": "provider_123",
    "status": "completed",
    "amount": "150.00",
    "currency": "EGP",
    "payment_method": "card"
  }
}
```

## `retryPayment`

### Method and Path

`POST /payments/{payment_id}/retry`

### Optional Request Fields

- `redirect_url`
- `callback_url`

## `cancelPayment`

### Method and Path

`POST /payments/{payment_id}/cancel`

## Mobile Auth Guidance

For production Flutter apps:

1. Keep `apiSecret` on your backend, not inside the app.
2. Issue short-lived access tokens from your backend to the mobile app.
3. Use the SDK with `accessToken` whenever possible.
