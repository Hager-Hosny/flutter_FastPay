import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/card_details.dart';
import '../utils/card_input_formatters.dart';

/// Card entry form embedded in the FastPay checkout page.
class FastPayCardForm extends StatefulWidget {
  /// Creates a [FastPayCardForm].
  const FastPayCardForm({
    super.key,
    required this.enabled,
    required this.onSubmit,
  });

  /// Whether inputs should be interactive.
  final bool enabled;

  /// Callback triggered after successful validation.
  final ValueChanged<CardDetails> onSubmit;

  @override
  State<FastPayCardForm> createState() => _FastPayCardFormState();
}

class _FastPayCardFormState extends State<FastPayCardForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _cardNumberController;
  late final TextEditingController _expiryController;
  late final TextEditingController _cvvController;
  late final TextEditingController _cardholderController;

  @override
  void initState() {
    super.initState();
    _cardNumberController = TextEditingController();
    _expiryController = TextEditingController();
    _cvvController = TextEditingController();
    _cardholderController = TextEditingController();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: _cardholderController,
            enabled: widget.enabled,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Cardholder name',
              hintText: 'Name on card',
            ),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter the cardholder name.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cardNumberController,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Card number',
              hintText: '4111 1111 1111 1111',
            ),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              CardNumberInputFormatter(),
            ],
            validator: (String? value) {
              final String digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
              if (digits.length < 13 || digits.length > 19) {
                return 'Enter a valid card number.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Expiry',
                    hintText: 'MM/YY',
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    ExpiryDateInputFormatter(),
                  ],
                  validator: (String? value) {
                    final List<String> parts = (value ?? '').split('/');
                    if (parts.length != 2) {
                      return 'Use MM/YY.';
                    }

                    final int? month = int.tryParse(parts[0]);
                    final int? year = int.tryParse(parts[1]);
                    if (month == null ||
                        year == null ||
                        month < 1 ||
                        month > 12) {
                      return 'Invalid expiry date.';
                    }

                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (String? value) {
                    final String digits =
                        value?.replaceAll(RegExp(r'\D'), '') ?? '';
                    if (digits.length < 3 || digits.length > 4) {
                      return 'Invalid CVV.';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: widget.enabled ? _submit : null,
            child: const Text('Pay now'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final List<String> parts = _expiryController.text.split('/');
    final int month = int.parse(parts[0]);
    final int year = int.parse(parts[1]) + 2000;
    final String number = _cardNumberController.text.replaceAll(
      RegExp(r'\D'),
      '',
    );

    widget.onSubmit(
      CardDetails(
        number: number,
        expiryMonth: month,
        expiryYear: year,
        cvv: _cvvController.text,
        cardholderName: _cardholderController.text.trim(),
        last4: number.length >= 4 ? number.substring(number.length - 4) : null,
      ),
    );
  }
}
