import 'dart:convert';

import 'package:fastpay_sdk/src/core/api_client.dart';
import 'package:fastpay_sdk/src/core/fastpay_config.dart';
import 'package:fastpay_sdk/src/models/customer.dart';
import 'package:fastpay_sdk/src/services/fastpay_payment_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  FastPayPaymentService buildService(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return FastPayPaymentService(
      apiClient: ApiClient(
        config: const FastPayConfig(
          baseUrl: 'https://api.fastpay.dpdns.org',
          apiKey: 'pk_test',
          accessToken: 'access_token',
        ),
        httpClient: MockClient(handler),
      ),
    );
  }

  test('createSession maps envelope data into a Session model', () async {
    final FastPayPaymentService service = buildService((
      http.Request request,
    ) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/payments/session');
      expect(request.headers['Authorization'], 'Bearer access_token');
      expect(request.headers['X-Client-Source'], 'flutter_sdk');
      expect(request.headers['X-SDK-Version'], '0.0.1');
      expect(request.headers['X-Request-Id'], isNotEmpty);
      return http.Response(
        jsonEncode(<String, dynamic>{
          'status': 'success',
          'message': 'Session created',
          'data': <String, dynamic>{
            'payment_id': 'pay_123',
            'reference': 'ref_123',
            'status': 'created',
            'checkout_url': 'https://merchant.example.com/checkout/pay_123',
          },
        }),
        200,
      );
    });

    final session = await service.createSession(
      amount: 150,
      currency: 'EGP',
      customer: const Customer(name: 'Elmira', email: 'elmira@example.com'),
      merchantOrderId: 'ORD-10001',
      checkoutUrl: 'https://merchant.example.com/checkout',
      callbackUrl: 'https://merchant.example.com/api/fastpay/callback',
    );

    expect(session.paymentId, 'pay_123');
    expect(session.sessionId, 'pay_123');
    expect(session.reference, 'ref_123');
    expect(session.status, 'created');
    expect(session.checkoutUrl, contains('pay_123'));
  });

  test('getPayment maps the current backend payment payload', () async {
    final FastPayPaymentService service = buildService((
      http.Request request,
    ) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/payments/pay_123');

      return http.Response(
        jsonEncode(<String, dynamic>{
          'status': 'success',
          'message': 'Payment retrieved successfully',
          'data': <String, dynamic>{
            'id': 11,
            'external_reference': 'pay_123',
            'provider_reference': 'provider_123',
            'status': 'completed',
            'amount': 150.0,
            'currency': 'EGP',
            'payment_method': 'card',
          },
        }),
        200,
      );
    });

    final transaction = await service.getPayment(paymentId: 'pay_123');

    expect(transaction.paymentId, 'pay_123');
    expect(transaction.providerReference, 'provider_123');
    expect(transaction.paymentMethod, 'card');
    expect(transaction.status, 'completed');
  });
}
