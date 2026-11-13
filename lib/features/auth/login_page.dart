import 'package:flutter/material.dart';

import '../../core/validation/input_rules.dart';
import 'auth_controller.dart';
import 'brand_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.controller,
    required this.onCreateAccount,
  });

  final AuthController controller;
  final VoidCallback onCreateAccount;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.login(
      _emailController.text,
      _passwordController.text,
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return InputRules.emptyEmailMessage;
    if (!InputRules.isValidEmail(email)) return InputRules.invalidEmailMessage;
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return InputRules.emptyPasswordMessage;
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
          Text('Entrar', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Acesse sua conta para ver o catálogo.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: const Key('login_email'),
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
            key: const Key('login_password'),
            controller: _passwordController,
            enabled: !busy,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _submit(),
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
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      error,
                      key: const Key('login_error'),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('login_submit'),
            onPressed: busy ? null : _submit,
            child: busy
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Text('Entrar'),
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('login_create_account'),
            onPressed: busy ? null : widget.onCreateAccount,
            child: const Text('Criar conta'),
          ),
        ],
      ),
    );
  }
}
