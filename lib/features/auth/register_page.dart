import 'package:flutter/material.dart';

import '../../core/validation/input_rules.dart';
import 'auth_controller.dart';
import 'brand_header.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.controller,
    required this.onSignIn,
  });

  final AuthController controller;
  final VoidCallback onSignIn;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return InputRules.emptyNameMessage;
    if (!InputRules.isValidName(name)) return InputRules.invalidNameMessage;
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return InputRules.emptyEmailMessage;
    if (!InputRules.isValidEmail(email)) return InputRules.invalidEmailMessage;
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return InputRules.emptyNewPasswordMessage;
    }
    if (!InputRules.isValidPassword(value)) {
      return InputRules.weakPasswordMessage;
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return InputRules.emptyNewPasswordMessage;
    }
    if (value != _passwordController.text) {
      return InputRules.passwordMismatchMessage;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrandHeader(scheme: scheme),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ListenableBuilder(
                    listenable: widget.controller,
                    builder: (context, _) => _buildForm(theme),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    final busy = widget.controller.isBusy;
    final error = widget.controller.errorMessage;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Criar conta', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Cadastre-se para comprar no Multiplagier.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: const Key('register_name'),
            controller: _nameController,
            enabled: !busy,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(
              labelText: 'Nome',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: _validateName,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('register_email'),
            controller: _emailController,
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('register_password'),
            controller: _passwordController,
            enabled: !busy,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('register_password_confirm'),
            controller: _confirmController,
            enabled: !busy,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Confirmar senha',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscureConfirm
                    ? 'Mostrar confirmação'
                    : 'Ocultar confirmação',
                icon: Icon(
                  _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: _validateConfirm,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      error,
                      key: const Key('register_error'),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('register_submit'),
            onPressed: busy ? null : _submit,
            child: busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Cadastrar'),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('register_go_to_login'),
            onPressed: busy ? null : widget.onSignIn,
            child: const Text('Já tenho conta'),
          ),
        ],
      ),
    );
  }
}
