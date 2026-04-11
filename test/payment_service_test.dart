import 'dart:convert';

import 'package:fastpay_sdk/src/core/api_client.dart';
import 'package:fastpay_sdk/src/core/fastpay_config.dart';
import 'package:fastpay_sdk/src/models/card_details.dart';
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
      return http.Response(
        jsonEncode(<String, dynamic>{
          'status': 'success',
          'message': 'Session created',
          'data': <String, dynamic>{
            'session_id': 'sess_123',
            'status': 'created',
            'amount': 150.0,
            'currency': 'EGP',
            'merchant_order_id': 'ORD-10001',
          },
        }),
        200,
      );
    });

    final session = await service.createSession(
      amount: 150,
      currency: 'EGP',
      customer: const Customer(name: 'Elmira'),
      merchantOrderId: 'ORD-10001',
    );

    expect(session.sessionId, 'sess_123');
    expect(session.status, 'created');
    expect(session.currency, 'EGP');
  });

  test('processTransaction maps nested card details', () async {
    final FastPayPaymentService service = buildService((
      http.Request request,
    ) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/payments/process-transaction');

      final Map<String, dynamic> body =
          jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['session_id'], 'sess_123');
      expect(body['card_details']['number'], '4242424242424242');

      return http.Response(
        jsonEncode(<String, dynamic>{
          'status': 'success',
          'message': 'Approved',
          'data': <String, dynamic>{
            'transaction_id': 'txn_123',
            'session_id': 'sess_123',
            'status': 'authorized',
            'amount': 150.0,
            'currency': 'EGP',
            'card_details': <String, dynamic>{'last4': '4242', 'brand': 'visa'},
          },
        }),
        200,
      );
    });

    final transaction = await service.processTransaction(
      sessionId: 'sess_123',
      cardDetails: const CardDetails(
        number: '4242424242424242',
        expiryMonth: 12,
        expiryYear: 2030,
        cvv: '123',
        cardholderName: 'Elmira',
      ),
    );

    expect(transaction.transactionId, 'txn_123');
    expect(transaction.cardDetails?.last4, '4242');
    expect(transaction.message, 'Approved');
  });
}
