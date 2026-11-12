import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../core/format/money.dart';
import '../../data/models/payment_info.dart';
import '../../data/repositories/order_repository.dart';
import '../cart/cart_controller.dart';
import '../orders/order_detail_page.dart';
import 'payment_rules.dart';

/// Checkout: formulário de pagamento simulado antes de criar o pedido.
class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    required this.controller,
    required this.orderRepository,
    required this.onOrderPlaced,
  });

  final CartController controller;
  final OrderRepository orderRepository;
  final VoidCallback onOrderPlaced;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _nameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  PaymentMethod _method = PaymentMethod.card;
  bool _submitting = false;
  String? _error;

  static const _fakePixCode =
      '00020126580014BR.GOV.BCB.PIX0136multiplagier-demo-pix520400005303986540';

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  PaymentInfo? _buildPayment() {
    if (_method == PaymentMethod.pix) {
      return const PaymentInfo.pix();
    }
    if (!_formKey.currentState!.validate()) return null;
    final last4 = PaymentRules.last4FromCardNumber(_numberController.text);
    if (last4 == null) return null;
    return PaymentInfo.card(last4: last4);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final payment = _buildPayment();
    if (payment == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    // Simula processamento offline (sem gateway).
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final orderId = await widget.controller.checkout(payment);
    if (!mounted) return;

    if (orderId == null) {
      setState(() {
        _submitting = false;
        _error =
            widget.controller.errorMessage ?? CartController.unexpectedMessage;
      });
      return;
    }

    widget.onOrderPlaced();
    // Remove carrinho + pagamento e deixa o detalhe sobre o Home
    // (mesmo empilhamento do antigo pushReplacement a partir do carrinho).
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailPage(
          repository: widget.orderRepository,
          userId: widget.controller.userId,
          orderId: orderId,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = formatBrl(widget.controller.totalCents);

    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final busy = _submitting || widget.controller.busy;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Text(
                      'Total a pagar',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total,
                      key: const Key('payment_total'),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Forma de pagamento', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          key: const Key('payment_method_card'),
                          avatar: const Icon(Icons.credit_card, size: 18),
                          label: const Text('Cartão'),
                          selected: _method == PaymentMethod.card,
                          onSelected: busy
                              ? null
                              : (_) => setState(() {
                                  _method = PaymentMethod.card;
                                  _error = null;
                                }),
                        ),
                        FilterChip(
                          key: const Key('payment_method_pix'),
                          avatar: const Icon(Icons.qr_code_2, size: 18),
                          label: const Text('Pix'),
                          selected: _method == PaymentMethod.pix,
                          onSelected: busy
                              ? null
                              : (_) => setState(() {
                                  _method = PaymentMethod.pix;
                                  _error = null;
                                }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_method == PaymentMethod.card)
                      _CardForm(
                        formKey: _formKey,
                        enabled: !busy,
                        numberController: _numberController,
                        nameController: _nameController,
                        expiryController: _expiryController,
                        cvvController: _cvvController,
                      )
                    else
                      _PixPanel(code: _fakePixCode, total: total),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        key: const Key('payment_error'),
                        style: TextStyle(
                          color: scheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Material(
                color: AppColors.surfaceContainer,
                elevation: 8,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: FilledButton(
                      key: const Key('payment_submit'),
                      onPressed: busy ? null : _submit,
                      child: busy
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.onPrimary,
                              ),
                            )
                          : Text(
                              _method == PaymentMethod.pix
                                  ? 'Confirmar pagamento'
                                  : 'Pagar $total',
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CardForm extends StatelessWidget {
  const _CardForm({
    required this.formKey,
    required this.enabled,
    required this.numberController,
    required this.nameController,
    required this.expiryController,
    required this.cvvController,
  });

  final GlobalKey<FormState> formKey;
  final bool enabled;
  final TextEditingController numberController;
  final TextEditingController nameController;
  final TextEditingController expiryController;
  final TextEditingController cvvController;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            key: const Key('payment_card_number'),
            controller: numberController,
            enabled: enabled,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(19),
              _CardNumberFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: 'Número do cartão',
              prefixIcon: Icon(Icons.credit_card),
            ),
            validator: (value) {
              final raw = value ?? '';
              if (PaymentRules.digitsOnly(raw).isEmpty) {
                return PaymentRules.emptyCardNumberMessage;
              }
              if (!PaymentRules.isValidCardNumber(raw)) {
                return PaymentRules.invalidCardNumberMessage;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('payment_card_name'),
            controller: nameController,
            enabled: enabled,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nome no cartão',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              final raw = value ?? '';
              if (raw.trim().isEmpty) {
                return PaymentRules.emptyCardNameMessage;
              }
              if (!PaymentRules.isValidCardName(raw)) {
                return PaymentRules.invalidCardNameMessage;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('payment_card_expiry'),
                  controller: expiryController,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Validade',
                    hintText: 'MM/AA',
                  ),
                  validator: (value) {
                    final raw = value ?? '';
                    if (PaymentRules.digitsOnly(raw).isEmpty) {
                      return PaymentRules.emptyExpiryMessage;
                    }
                    if (!PaymentRules.isValidExpiryFormat(raw)) {
                      return PaymentRules.invalidExpiryMessage;
                    }
                    if (!PaymentRules.isExpiryInFuture(raw)) {
                      return PaymentRules.expiredCardMessage;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: const Key('payment_card_cvv'),
                  controller: cvvController,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    final raw = value ?? '';
                    if (raw.isEmpty) return PaymentRules.emptyCvvMessage;
                    if (!PaymentRules.isValidCvv(raw)) {
                      return PaymentRules.invalidCvvMessage;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PixPanel extends StatelessWidget {
  const _PixPanel({required this.code, required this.total});

  final String code;
  final String total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.qr_code_2, size: 96, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              'Pix simulado — valor $total',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Copie o código abaixo e confirme o pagamento no app.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              code,
              key: const Key('payment_pix_code'),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = PaymentRules.digitsOnly(newValue.text);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = PaymentRules.digitsOnly(newValue.text);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
