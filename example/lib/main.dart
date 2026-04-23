import 'package:fastpay_sdk/fastpay_sdk.dart';
import 'package:flutter/material.dart';

void main() {
  FastPay.initialize(
    const FastPayConfig(
      baseUrl: 'https://api.fastpay.dpdns.org',
      apiKey: 'pk_test_replace_me',
      accessToken: 'merchant_backend_issued_token',
      merchantId: 'merchant_demo',
    ),
  );

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FastPay SDK Example',
      theme: ThemeData(
        scaffoldBackgroundColor: FastPayCheckoutPalette.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: FastPayCheckoutPalette.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  PaymentResult? _lastResult;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String paymentId =
        _lastResult?.payment?.paymentId ??
        _lastResult?.session?.paymentId ??
        'n/a';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('FastPay SDK Example'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: fastPaySurfaceDecoration(),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Demo payment',
                  style: TextStyle(
                    color: FastPayCheckoutPalette.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '150.00 EGP',
                  style: TextStyle(
                    color: FastPayCheckoutPalette.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Replace the placeholder API credentials in example/main.dart before testing against the live FastPay backend.',
                  style: TextStyle(
                    color: FastPayCheckoutPalette.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: FastPayCheckoutPalette.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: _busy ? null : _openCheckout,
            child: Text(_busy ? 'Opening...' : 'Open FastPay Checkout'),
          ),
          if (_lastResult != null) ...<Widget>[
            const SizedBox(height: 24),
            Text(
              'Last result',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: fastPaySurfaceDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Outcome: ${_lastResult!.outcome.name}'),
                  const SizedBox(height: 6),
                  Text('Status: ${_lastResult!.status ?? 'unknown'}'),
                  const SizedBox(height: 6),
                  Text('Message: ${_lastResult!.errorMessage ?? 'n/a'}'),
                  const SizedBox(height: 6),
                  Text('Payment ID: $paymentId'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openCheckout() async {
    setState(() {
      _busy = true;
    });

    final PaymentResult result = await FastPayCheckout.show(
      context,
      amount: 150.0,
      currency: 'EGP',
      customer: const Customer(
        name: 'Elmira Stokes',
        email: 'elmira@example.com',
        phone: '605-590-6006',
      ),
      merchantOrderId: 'ORD-10001',
      callbackUrl: 'https://merchant.example.com/api/fastpay/callback',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _busy = false;
      _lastResult = result;
    });
  }
}
