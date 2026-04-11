import 'package:flutter/material.dart';

import '../core/fastpay.dart';
import '../flow/fastpay_flow_controller.dart';
import '../flow/fastpay_flow_state.dart';
import '../models/customer.dart';
import '../models/payment_result.dart';
import '../services/payment_service.dart';
import 'fastpay_card_form.dart';
import 'fastpay_result_view.dart';

/// Internal checkout page used by [FastPayCheckout.show].
class FastPayCheckoutPage extends StatefulWidget {
  /// Creates a [FastPayCheckoutPage].
  const FastPayCheckoutPage({
    super.key,
    required this.amount,
    required this.currency,
    this.customer,
    this.merchantOrderId,
    this.metadata,
    this.redirectUrl,
    this.callbackUrl,
    this.paymentService,
  });

  /// Payment amount to charge.
  final double amount;

  /// ISO currency code.
  final String currency;

  /// Optional customer snapshot.
  final Customer? customer;

  /// Optional merchant order reference.
  final String? merchantOrderId;

  /// Optional backend metadata.
  final Map<String, dynamic>? metadata;

  /// Optional redirect URL.
  final String? redirectUrl;

  /// Optional callback URL.
  final String? callbackUrl;

  /// Optional service override used in tests.
  final PaymentService? paymentService;

  @override
  State<FastPayCheckoutPage> createState() => _FastPayCheckoutPageState();
}

class _FastPayCheckoutPageState extends State<FastPayCheckoutPage> {
  late final FastPayFlowController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FastPayFlowController(
      paymentService: widget.paymentService ?? FastPay.paymentService,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _start();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FastPay Checkout'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Close',
            onPressed: () => _close(_controller.state.result),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          final FastPayFlowState state = _controller.state;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _CheckoutSummary(
                    amount: widget.amount,
                    currency: widget.currency,
                    merchantOrderId: widget.merchantOrderId,
                  ),
                  const SizedBox(height: 20),
                  if (state.stage == FastPayFlowStage.creatingSession ||
                      state.stage == FastPayFlowStage.initial)
                    const _LoadingCard(
                      title: 'Creating secure session',
                      message: 'FastPay is preparing the checkout.',
                    )
                  else if (state.stage == FastPayFlowStage.ready ||
                      state.stage == FastPayFlowStage.processing)
                    Stack(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                'Card details',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your card details are used only for this payment attempt and are not stored by the SDK.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 20),
                              FastPayCardForm(
                                enabled: !state.isBusy,
                                onSubmit: (cardDetails) async {
                                  await _controller.submitCard(
                                    cardDetails: cardDetails,
                                    customer: widget.customer,
                                    merchantOrderId: widget.merchantOrderId,
                                    metadata: widget.metadata,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        if (state.isBusy)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                      ],
                    )
                  else if (state.result != null)
                    FastPayResultView(
                      result: state.result!,
                      onDone: () => _close(state.result),
                      onRetry: state.result!.isFailure
                          ? _controller.prepareRetry
                          : null,
                      onRefreshStatus: state.result!.isPending
                          ? () async {
                              await _controller.checkStatus();
                            }
                          : null,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _start() async {
    try {
      await _controller.startCheckout(
        amount: widget.amount,
        currency: widget.currency,
        customer: widget.customer,
        merchantOrderId: widget.merchantOrderId,
        metadata: widget.metadata,
        redirectUrl: widget.redirectUrl,
        callbackUrl: widget.callbackUrl,
      );
    } catch (_) {
      // The controller already captures the failure state.
    }
  }

  void _close(PaymentResult? result) {
    final PaymentResult finalResult =
        result ??
        PaymentResult(
          outcome: PaymentOutcome.failure,
          status: 'cancelled',
          errorMessage: 'Checkout was dismissed before completion.',
          session: _controller.state.session,
        );

    Navigator.of(context).pop(finalResult);
  }
}

class _CheckoutSummary extends StatelessWidget {
  const _CheckoutSummary({
    required this.amount,
    required this.currency,
    this.merchantOrderId,
  });

  final double amount;
  final String currency;
  final String? merchantOrderId;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF062E2D), Color(0xFF0C6C66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Amount due',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white70,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$amount $currency',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (merchantOrderId != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Order: $merchantOrderId',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
