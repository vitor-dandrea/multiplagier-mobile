import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../core/validation/address_rules.dart';
import '../../core/validation/input_rules.dart';
import '../../data/models/shipping_address.dart';
import '../auth/auth_controller.dart';

/// Perfil do cliente: nome e endereço editáveis; e-mail somente leitura.
class AccountPage extends StatefulWidget {
  const AccountPage({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _streetController;
  late final TextEditingController _numberController;
  late final TextEditingController _complementController;
  late final TextEditingController _districtController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _zipController;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    final user = widget.authController.user;
    final address = user?.address;
    _nameController = TextEditingController(text: user?.name ?? '');
    _streetController = TextEditingController(text: address?.street ?? '');
    _numberController = TextEditingController(text: address?.number ?? '');
    _complementController =
        TextEditingController(text: address?.complement ?? '');
    _districtController = TextEditingController(text: address?.district ?? '');
    _cityController = TextEditingController(text: address?.city ?? '');
    _stateController = TextEditingController(text: address?.state ?? '');
    _zipController = TextEditingController(
      text: _formatZip(address?.zip ?? ''),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  ShippingAddress _readAddress() {
    return ShippingAddress(
      street: _streetController.text,
      number: _numberController.text,
      complement: _complementController.text.trim().isEmpty
          ? null
          : _complementController.text,
      district: _districtController.text,
      city: _cityController.text,
      state: _stateController.text,
      zip: _zipController.text,
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _successMessage = null);
    widget.authController.clearError();
    final ok = await widget.authController.updateProfile(
      name: _nameController.text,
      address: _readAddress(),
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _successMessage = AuthController.profileSavedMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final email = widget.authController.user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Minha conta')),
      body: ListenableBuilder(
        listenable: widget.authController,
        builder: (context, _) {
          final busy = widget.authController.isBusy;
          final error = widget.authController.errorMessage;
          return Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      Text('Dados pessoais', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('account_name'),
                        controller: _nameController,
                        enabled: !busy,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          final name = value?.trim() ?? '';
                          if (name.isEmpty) return InputRules.emptyNameMessage;
                          if (!InputRules.isValidName(name)) {
                            return InputRules.invalidNameMessage;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('account_email'),
                        initialValue: email,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.mail_outline),
                          helperText: 'O e-mail não pode ser alterado.',
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Endereço de entrega',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('account_zip'),
                        controller: _zipController,
                        enabled: !busy,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                          _ZipFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'CEP',
                          hintText: '00000-000',
                        ),
                        validator: (value) {
                          final raw = value ?? '';
                          if (AddressRules.digitsOnly(raw).isEmpty) {
                            return AddressRules.emptyZipMessage;
                          }
                          if (!AddressRules.isValidZip(raw)) {
                            return AddressRules.invalidZipMessage;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('account_street'),
                        controller: _streetController,
                        enabled: !busy,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Rua'),
                        validator: (value) => AddressRules.isNonEmpty(value)
                            ? null
                            : AddressRules.emptyStreetMessage,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              key: const Key('account_number'),
                              controller: _numberController,
                              enabled: !busy,
                              decoration:
                                  const InputDecoration(labelText: 'Número'),
                              validator: (value) => AddressRules.isNonEmpty(value)
                                  ? null
                                  : AddressRules.emptyNumberMessage,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              key: const Key('account_complement'),
                              controller: _complementController,
                              enabled: !busy,
                              decoration: const InputDecoration(
                                labelText: 'Complemento',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('account_district'),
                        controller: _districtController,
                        enabled: !busy,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Bairro'),
                        validator: (value) => AddressRules.isNonEmpty(value)
                            ? null
                            : AddressRules.emptyDistrictMessage,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              key: const Key('account_city'),
                              controller: _cityController,
                              enabled: !busy,
                              textCapitalization: TextCapitalization.words,
                              decoration:
                                  const InputDecoration(labelText: 'Cidade'),
                              validator: (value) => AddressRules.isNonEmpty(value)
                                  ? null
                                  : AddressRules.emptyCityMessage,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              key: const Key('account_state'),
                              controller: _stateController,
                              enabled: !busy,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(2),
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z]'),
                                ),
                              ],
                              decoration:
                                  const InputDecoration(labelText: 'UF'),
                              validator: (value) {
                                final raw = value ?? '';
                                if (raw.trim().isEmpty) {
                                  return AddressRules.emptyStateMessage;
                                }
                                if (!AddressRules.isValidState(raw)) {
                                  return AddressRules.invalidStateMessage;
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_successMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _successMessage!,
                          key: const Key('account_success'),
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          error,
                          key: const Key('account_error'),
                          style: TextStyle(
                            color: scheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Material(
                color: AppColors.surfaceContainer,
                elevation: 8,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          key: const Key('account_save'),
                          onPressed: busy ? null : _save,
                          child: busy
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.onPrimary,
                                  ),
                                )
                              : const Text('Salvar'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          key: const Key('account_logout'),
                          onPressed: busy
                              ? null
                              : () async {
                                  final navigator = Navigator.of(context);
                                  await widget.authController.logout();
                                  navigator.popUntil((route) => route.isFirst);
                                },
                          icon: const Icon(Icons.logout),
                          label: const Text('Sair'),
                        ),
                      ],
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

  static String _formatZip(String raw) {
    final digits = AddressRules.digitsOnly(raw);
    if (digits.length <= 5) return digits;
    return '${digits.substring(0, 5)}-${digits.substring(5)}';
  }
}

class _ZipFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = AddressRules.digitsOnly(newValue.text);
    final clipped = digits.length > 8 ? digits.substring(0, 8) : digits;
    final text = clipped.length <= 5
        ? clipped
        : '${clipped.substring(0, 5)}-${clipped.substring(5)}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
