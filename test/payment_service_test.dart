import 'dart:convert';

import 'package:fastpay_sdk/src/core/api_client.dart';
import 'package:fastpay_sdk/src/core/fastpay_config.dart';
import 'package:fastpay_sdk/src/core/token_store.dart';
import 'package:fastpay_sdk/src/models/customer.dart';
import 'package:fastpay_sdk/src/models/token_pair.dart';
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
        ),
        tokenStore: InMemoryTokenStore(
          initialTokens: const TokenPair(accessToken: 'access_token'),
        ),
        httpClient: MockClient(handler),
      ),
    );
  }

  test('listMethods parses the backend payment-methods response', () async {
    final FastPayPaymentService service = buildService((http.Request request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/payment-methods');

      return http.Response(
        jsonEncode(<String, dynamic>{
          'status': 'success',
          'message': 'Payment methods retrieved successfully',
          'data': <Map<String, dynamic>>[
            <String, dynamic>{'code': 'card', 'name': 'Card'},
            <String, dynamic>{'code': 'wallet', 'name': 'Wallet'},
          ],
        }),
        200,
      );
    });

    final methods = await service.listMethods();

    expect(methods, hasLength(2));
    expect(methods.first.code, 'card');
    expect(methods.last.name, 'Wallet');
  });

  test('createSession sends the current API contract and parses PaymentSession', () async {
    final FastPayPaymentService service = buildService((http.Request request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/payments/session');
      expect(request.headers['Authorization'], 'Bearer access_token');
      expect(request.headers['X-Client-Source'], 'flutter_sdk');

      final Map<String, dynamic> body =
          jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['merchant_order_id'], 'ORD-10001');
      expect(body['callback_url'], 'https://merchant.example.com/callback');
      expect(body.containsKey('checkout_url'), isFalse);

      return http.Response(
        jsonEncode(<String, dynamic>{
          'status': 'success',
          'message': 'Payment session created successfully',
          'data': <String, dynamic>{
            'payment_id': 'pay_123',
            'reference': 'ref_123',
            'status': 'initiated',
            'checkout_url': 'https://merchant.example.com/checkout/pay_123',
          },
        }),
        200,
      );
    });

    final session = await service.createSession(
      amount: 150,
      currency: 'EGP',
      customer: const Customer(
        name: 'Elmira',
        email: 'elmira@example.com',
        phone: '+201000000000',
      ),
      merchantOrderId: 'ORD-10001',
      callbackUrl: 'https://merchant.example.com/callback',
    );

    expect(session.paymentId, 'pay_123');
    expect(session.status, 'initiated');
    expect(session.checkoutUrl, contains('pay_123'));
  });

  test('getPayment parses PaymentDetails without injecting ids from the request', () async {
    final FastPayPaymentService service = buildService((http.Request request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/payments/pay_123');

      return http.Response(
        jsonEncode(<String, dynamic>{
          'status': 'success',
          'message': 'Payment retrieved successfully',
          'data': <String, dynamic>{
            'payment_id': 'pay_123',
            'id': 11,
            'external_reference': 'pay_123',
            'provider_reference': 'provider_123',
            'status': 'completed',
            'amount': '150.00',
            'currency': 'EGP',
            'payment_method': 'card',
          },
        }),
        200,
      );
    });

    final payment = await service.getPayment(paymentId: 'pay_123');

    expect(payment.paymentId, 'pay_123');
    expect(payment.id, 11);
    expect(payment.providerReference, 'provider_123');
    expect(payment.status, 'completed');
  });
}
