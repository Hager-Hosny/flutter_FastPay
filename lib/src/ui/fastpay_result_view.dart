import 'package:flutter/material.dart';

import '../models/payment_result.dart';
import 'fastpay_checkout_theme.dart';

/// Result UI rendered after processing a payment attempt.
class FastPayResultView extends StatelessWidget {
  /// Creates a [FastPayResultView].
  const FastPayResultView({
    super.key,
    required this.result,
    required this.onDone,
    this.onRetry,
    this.onRefreshStatus,
  });

  /// Payment result to display.
  final PaymentResult result;

  /// Called when the merchant closes the checkout.
  final VoidCallback onDone;

  /// Called when the user wants to retry the payment.
  final VoidCallback? onRetry;

  /// Called when the user wants to refresh a pending payment.
  final VoidCallback? onRefreshStatus;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final _ResultTone tone = _toneForResult(result);
    final String? amount = result.payment?.amount;
    final String? currency = result.payment?.currency;
    final String? paymentId =
        result.payment?.paymentId ?? result.session?.paymentId;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: fastPaySurfaceDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: tone.iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(tone.icon, size: 34, color: tone.iconColor),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            tone.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: FastPayCheckoutPalette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            result.errorMessage ?? _defaultMessage(result),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: FastPayCheckoutPalette.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (amount != null && currency != null) ...<Widget>[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: tone.amountBackground,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    '$amount $currency',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: tone.amountForeground,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'FastPay latest payment snapshot',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tone.amountForeground.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          _ResultDetailRow(label: 'Status', value: result.status ?? 'unknown'),
          if (paymentId != null)
            _ResultDetailRow(
              label: 'Payment ID',
              value: formatFastPayId(paymentId),
            ),
          if (result.session?.reference != null)
            _ResultDetailRow(
              label: 'Reference',
              value: result.session!.reference!,
            ),
          if (result.payment?.paymentMethod != null)
            _ResultDetailRow(
              label: 'Method',
              value: result.payment!.paymentMethod!,
            ),
          const SizedBox(height: 24),
          if (result.isPending && onRefreshStatus != null) ...<Widget>[
            FilledButton(
              style: _primaryButtonStyle(theme),
              onPressed: onRefreshStatus,
              child: const Text('Refresh status'),
            ),
            const SizedBox(height: 12),
          ],
          if (result.isFailure && onRetry != null) ...<Widget>[
            FilledButton(
              style: _primaryButtonStyle(theme),
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: FastPayCheckoutPalette.textPrimary,
              side: const BorderSide(color: FastPayCheckoutPalette.border),
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: onDone,
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  ButtonStyle _primaryButtonStyle(ThemeData theme) {
    return FilledButton.styleFrom(
      backgroundColor: FastPayCheckoutPalette.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  String _defaultMessage(PaymentResult result) {
    if (result.isSuccess) {
      return 'Your payment was confirmed and the order is ready to continue.';
    }

    if (result.isPending) {
      return 'We are waiting for the final payment confirmation from the gateway.';
    }

    return 'We could not complete the transaction. You can review the details and try again.';
  }

  _ResultTone _toneForResult(PaymentResult result) {
    if (result.isSuccess) {
      return const _ResultTone(
        title: 'Payment Successful',
        icon: Icons.check_rounded,
        iconBackground: FastPayCheckoutPalette.successSoft,
        iconColor: FastPayCheckoutPalette.success,
        amountBackground: FastPayCheckoutPalette.primary,
        amountForeground: Colors.white,
      );
    }

    if (result.isPending) {
      return const _ResultTone(
        title: 'Payment Pending',
        icon: Icons.schedule_rounded,
        iconBackground: FastPayCheckoutPalette.warningSoft,
        iconColor: FastPayCheckoutPalette.warning,
        amountBackground: FastPayCheckoutPalette.warningSoft,
        amountForeground: FastPayCheckoutPalette.textPrimary,
      );
    }

    return const _ResultTone(
      title: 'Payment Failed',
      icon: Icons.close_rounded,
      iconBackground: FastPayCheckoutPalette.dangerSoft,
      iconColor: FastPayCheckoutPalette.danger,
      amountBackground: FastPayCheckoutPalette.dangerSoft,
      amountForeground: FastPayCheckoutPalette.textPrimary,
    );
  }
}

class _ResultDetailRow extends StatelessWidget {
  const _ResultDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: FastPayCheckoutPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
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
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: FastPayCheckoutPalette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultTone {
  const _ResultTone({
    required this.title,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.amountBackground,
    required this.amountForeground,
  });

  final String title;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final Color amountBackground;
  final Color amountForeground;
}
