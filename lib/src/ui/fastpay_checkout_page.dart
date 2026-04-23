import 'package:flutter/material.dart';

import '../core/fastpay.dart';
import '../flow/fastpay_flow_controller.dart';
import '../flow/fastpay_flow_state.dart';
import '../models/customer.dart';
import '../models/payment_result.dart';
import '../services/payment_service.dart';
import 'fastpay_card_form.dart';
import 'fastpay_checkout_theme.dart';
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
      backgroundColor: FastPayCheckoutPalette.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFF7F8FC), Color(0xFFEEF2FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, _) {
            final FastPayFlowState state = _controller.state;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _CheckoutHeader(
                          onClose: () => _close(_controller.state.result),
                        ),
                        const SizedBox(height: 20),
                        _CheckoutSummary(
                          amount: widget.amount,
                          currency: widget.currency,
                          merchantOrderId: widget.merchantOrderId,
                        ),
                        const SizedBox(height: 18),
                        if (state.stage == FastPayFlowStage.creatingSession ||
                            state.stage ==
                                FastPayFlowStage.initial) ...<Widget>[
                          const _PaymentMethodCard(),
                          const SizedBox(height: 18),
                          const _StatusCard(
                            title: 'Creating secure session',
                            message:
                                'FastPay is preparing your checkout and validating the payment request.',
                            icon: Icons.shield_outlined,
                          ),
                        ] else if (state.stage ==
                            FastPayFlowStage.ready) ...<Widget>[
                          const _PaymentMethodCard(),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: fastPaySurfaceDecoration(),
                            child: FastPayCardForm(
                              amount: widget.amount,
                              currency: widget.currency,
                              enabled: true,
                              onSubmit: (cardDetails) async {
                                await _controller.submitCard(
                                  cardDetails: cardDetails,
                                  customer: widget.customer,
                                  merchantOrderId: widget.merchantOrderId,
                                  metadata: widget.metadata,
                                );
                              },
                            ),
                          ),
                        ] else if (state.stage == FastPayFlowStage.processing)
                          const _StatusCard(
                            title: 'Processing your payment',
                            message:
                                'Please do not close this page while we confirm the transaction with the gateway.',
                            icon: Icons.bolt_rounded,
                            showSpinner: true,
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
                        if (state.errorMessage != null &&
                            state.stage == FastPayFlowStage.ready) ...<Widget>[
                          const SizedBox(height: 18),
                          _InlineNotice(message: state.errorMessage!),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          'Powered by FastPay',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: FastPayCheckoutPalette.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
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

class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        _CircleIconButton(icon: Icons.arrow_back_rounded, onPressed: onClose),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'FastPay',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: FastPayCheckoutPalette.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Secure checkout',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: FastPayCheckoutPalette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: FastPayCheckoutPalette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: FastPayCheckoutPalette.border),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: FastPayCheckoutPalette.primary,
              ),
              SizedBox(width: 6),
              Text(
                'SSL',
                style: TextStyle(
                  color: FastPayCheckoutPalette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FastPayCheckoutPalette.surface,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: FastPayCheckoutPalette.textPrimary),
      ),
    );
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
      padding: const EdgeInsets.all(22),
      decoration: fastPaySurfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: FastPayCheckoutPalette.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: FastPayCheckoutPalette.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Order summary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: FastPayCheckoutPalette.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Review the payment details before you continue.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: FastPayCheckoutPalette.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SummaryRow(
            label: 'Payment amount',
            value: formatFastPayAmount(amount, currency),
            emphasize: true,
          ),
          _SummaryRow(label: 'Payment method', value: 'Credit card'),
          if (merchantOrderId != null)
            _SummaryRow(label: 'Order reference', value: merchantOrderId!),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: FastPayCheckoutPalette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style:
                  (emphasize
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(
                        color: FastPayCheckoutPalette.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: fastPaySurfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Choose payment method',
            style: theme.textTheme.titleMedium?.copyWith(
              color: FastPayCheckoutPalette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Card payments are available now. Additional methods can be added by the merchant later.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: FastPayCheckoutPalette.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          const _PaymentMethodOption(
            icon: Icons.credit_card_rounded,
            label: 'Credit card',
            subtitle: 'Visa, Mastercard, Meeza',
            active: true,
          ),
          const SizedBox(height: 12),
          const _PaymentMethodOption(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Wallet',
            subtitle: 'Coming soon',
          ),
          const SizedBox(height: 12),
          const _PaymentMethodOption(
            icon: Icons.account_balance_outlined,
            label: 'Bank transfer',
            subtitle: 'Coming soon',
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  const _PaymentMethodOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: active
            ? FastPayCheckoutPalette.primarySoft
            : FastPayCheckoutPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? FastPayCheckoutPalette.primary
              : FastPayCheckoutPalette.border,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: active
                  ? FastPayCheckoutPalette.primary
                  : FastPayCheckoutPalette.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: active
                  ? Colors.white
                  : FastPayCheckoutPalette.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: FastPayCheckoutPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: FastPayCheckoutPalette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            active ? Icons.radio_button_checked : Icons.radio_button_off,
            color: active
                ? FastPayCheckoutPalette.primary
                : FastPayCheckoutPalette.border,
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.message,
    required this.icon,
    this.showSpinner = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: fastPaySurfaceDecoration(),
      child: Column(
        children: <Widget>[
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: FastPayCheckoutPalette.primarySoft,
              shape: BoxShape.circle,
            ),
            child: showSpinner
                ? const Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FastPayCheckoutPalette.primary,
                      ),
                    ),
                  )
                : Icon(icon, size: 34, color: FastPayCheckoutPalette.primary),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: FastPayCheckoutPalette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: FastPayCheckoutPalette.textSecondary,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: FastPayCheckoutPalette.dangerSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FastPayCheckoutPalette.danger),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: FastPayCheckoutPalette.danger,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: FastPayCheckoutPalette.textPrimary,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
