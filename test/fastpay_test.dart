import 'dart:convert';

import 'package:fastpay_sdk/fastpay.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  tearDown(FastPay.dispose);

  test(
    'resolveAccessToken returns the initialized static access token',
    () async {
      FastPay.initialize(
        const FastPayConfig(
          baseUrl: 'https://api.fastpay.dpdns.org',
          apiKey: 'pk_test',
          accessToken: 'access_token',
        ),
      );

      final String token = await FastPay.resolveAccessToken();

      expect(token, 'access_token');
    },
  );

  test(
    'resolveAccessToken exchanges api credentials from an explicit config',
    () async {
      final MockClient httpClient = MockClient((http.Request request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/auth/token');

        final Map<String, dynamic> body =
            jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['api_key'], 'pk_test');
        expect(body['api_secret'], 'sk_test');

        return http.Response(
          jsonEncode(<String, dynamic>{
            'status': 'success',
            'message': 'Token generated',
            'data': <String, dynamic>{'access_token': 'resolved_token'},
          }),
          200,
        );
      });

      final String token = await FastPay.resolveAccessToken(
        config: const FastPayConfig(
          baseUrl: 'https://api.fastpay.dpdns.org',
          apiKey: 'pk_test',
          apiSecret: 'sk_test',
        ),
        httpClient: httpClient,
      );

      expect(token, 'resolved_token');
    },
  );

  test(
    'resolveAccessToken fails before initialization when base config is missing',
    () async {
      expect(
        FastPay.resolveAccessToken(forceRefresh: true),
        throwsA(
          isA<ApiException>().having(
            (ApiException error) => error.type,
            'type',
            ApiExceptionType.configuration,
          ),
        ),
      );
    },
  );
}
