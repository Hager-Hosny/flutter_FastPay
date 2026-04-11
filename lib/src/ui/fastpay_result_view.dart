import 'package:flutter/material.dart';

import '../models/payment_result.dart';

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

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircleAvatar(
            radius: 32,
            backgroundColor: tone.iconBackground,
            child: Icon(tone.icon, size: 32, color: tone.iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            tone.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            result.errorMessage ??
                result.transaction?.message ??
                'Status: ${result.status ?? 'unknown'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (result.transaction?.transactionId != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              'Transaction ID: ${result.transaction!.transactionId}',
              style: theme.textTheme.labelLarge,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          if (result.isFailure && onRetry != null)
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          if (result.isPending && onRefreshStatus != null)
            OutlinedButton(
              onPressed: onRefreshStatus,
              child: const Text('Refresh status'),
            ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onDone, child: const Text('Done')),
        ],
      ),
    );
  }

  _ResultTone _toneForResult(PaymentResult result) {
    if (result.isSuccess) {
      return const _ResultTone(
        title: 'Payment successful',
        icon: Icons.check_rounded,
        background: Color(0xFFF0FDF4),
        border: Color(0xFFBBF7D0),
        iconBackground: Color(0xFFDCFCE7),
        iconColor: Color(0xFF15803D),
      );
    }

    if (result.isPending) {
      return const _ResultTone(
        title: 'Payment pending',
        icon: Icons.schedule_rounded,
        background: Color(0xFFFFFBEB),
        border: Color(0xFFFDE68A),
        iconBackground: Color(0xFFFEF3C7),
        iconColor: Color(0xFFB45309),
      );
    }

    return const _ResultTone(
      title: 'Payment failed',
      icon: Icons.close_rounded,
      background: Color(0xFFFEF2F2),
      border: Color(0xFFFECACA),
      iconBackground: Color(0xFFFEE2E2),
      iconColor: Color(0xFFB91C1C),
    );
  }
}

class _ResultTone {
  const _ResultTone({
    required this.title,
    required this.icon,
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.iconColor,
  });

  final String title;
  final IconData icon;
  final Color background;
  final Color border;
  final Color iconBackground;
  final Color iconColor;
}
