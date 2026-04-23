# FastPay SDK API Reference

This package is aligned to the current FastPay backend contract in
`fastpay-apis`.

## Namespaced Clients

- `FastPay.auth`
- `FastPay.payments`
- `FastPay.transactions`
- `FastPay.refunds`
- `FastPay.payouts`
- `FastPay.webhooks`

## Supported Backend Routes

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
- `POST /webhooks/dispatch`
- `POST /webhooks/logs/{log_id}/deliver`

## Request Headers

The SDK attaches:

- `Accept: application/json`
- `Content-Type: application/json` for JSON request bodies
- `Authorization: Bearer <access_token>` for authenticated routes
- `X-Public-Key: <api_key>`
- `X-Client-Source`
- `X-SDK-Version`
- `X-Platform`
- `X-Request-Id`

For webhook dispatch, the SDK sends `Authorization: Bearer <externalWebhookApiKey>`
instead of the merchant access token.

## Auth

### Login

`FastPay.auth.login()`

Maps to `POST /auth/token` and stores:

- `access_token`
- `refresh_token`
- `expires_in`

### Refresh

`FastPay.auth.refresh()`

Maps to `POST /auth/refresh` with `refresh_token` in the request body.

### Logout

`FastPay.auth.logout()`

Maps to `POST /auth/logout` and clears the local `TokenStore`.

## Payments

### Create Session

`FastPay.payments.createSession(...)`

Required fields:

- `amount`
- `currency`
- `merchant_order_id`
- `customer`
- `callback_url`

Optional fields:

- `redirect_url`
- `metadata`

The backend generates `checkout_url`; the SDK does not send it.

### Get Payment

`FastPay.payments.getPayment(paymentId: ...)`

Returns `PaymentDetails`.

### Retry Payment

`FastPay.payments.retryPayment(...)`

Optional body fields:

- `payment_method`
- `redirect_url`
- `callback_url`

Returns `RetryPaymentResult`.

### Cancel Payment

`FastPay.payments.cancelPayment(paymentId: ...)`

Returns `CancelPaymentResult`.

## Transactions

### List

`FastPay.transactions.list(page: 0, size: 10)`

Returns `PageResult<TransactionListItem>`.

### Summary

`FastPay.transactions.summary(from: ..., to: ..., currency: ...)`

Returns `TransactionsSummary`.

## Refunds

`FastPay.refunds.create(...)`

Required fields:

- `transaction_id`
- `amount`
- `currency`

The merchant identity is derived from the bearer token.

## Payouts

`FastPay.payouts.create(...)`

Required fields:

- `amount`
- `currency`
- `destination_type`
- `destination_details`

## Webhooks

### Dispatch

`FastPay.webhooks.dispatch(...)`

Requires:

- `merchant_id`
- `event_type`
- `payload`
- `externalWebhookApiKey`

### Deliver Stored Log

`FastPay.webhooks.deliverLog(logId: ...)`

Requires the merchant bearer token.

## Error Types

- `ValidationApiException`
- `AuthenticationApiException`
- `AuthorizationApiException`
- `NotFoundApiException`
- `BusinessRuleApiException`
- `NetworkApiException`
- `TimeoutApiException`
- `ParsingApiException`
- `ConfigurationApiException`
- `ServerApiException`
- `UnknownApiException`
