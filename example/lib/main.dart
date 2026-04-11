import 'package:fastpay_sdk/fastpay_sdk.dart';
import 'package:flutter/material.dart';

void main() {
  FastPay.initialize(
    const FastPayConfig(
      baseUrl: 'https://api.fastpay.dpdns.org',
      apiKey: 'pk_test_replace_me',
      apiSecret: 'sk_test_replace_me',
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0C6C66),
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

    return Scaffold(
      appBar: AppBar(title: const Text('FastPay SDK Example')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF062E2D), Color(0xFF0C6C66)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Demo Payment',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '150.00 EGP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Replace the placeholder API credentials in example/main.dart before testing against the live FastPay backend.',
                  style: TextStyle(color: Colors.white, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Outcome: ${_lastResult!.outcome.name}'),
                    Text('Status: ${_lastResult!.status ?? 'unknown'}'),
                    Text(
                      'Message: ${_lastResult!.errorMessage ?? _lastResult!.transaction?.message ?? 'n/a'}',
                    ),
                    Text(
                      'Transaction: ${_lastResult!.transaction?.transactionId ?? 'n/a'}',
                    ),
                  ],
                ),
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
