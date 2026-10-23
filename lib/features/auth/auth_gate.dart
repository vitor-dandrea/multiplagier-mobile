import 'package:flutter/material.dart';

import '../../data/models/user.dart';
import 'auth_controller.dart';
import 'login_page.dart';
import 'register_page.dart';

/// Decide entre splash, login e a área autenticada conforme a sessão.
/// Visitante sem login nunca chega à área autenticada.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.controller,
    required this.authenticatedBuilder,
  });

  final AuthController controller;
  final Widget Function(BuildContext context, User user) authenticatedBuilder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final user = controller.user;
        switch (controller.status) {
          case AuthStatus.unknown:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.unauthenticated:
            return _AccountEntry(controller: controller);
          case AuthStatus.authenticated:
            return authenticatedBuilder(context, user!);
        }
      },
    );
  }
}

/// Alterna login e cadastro sem empilhar rotas. Quando o cadastro autentica,
/// o [AuthGate] troca a árvore inteira e esta tela é descartada.
class _AccountEntry extends StatefulWidget {
  const _AccountEntry({required this.controller});

  final AuthController controller;

  @override
  State<_AccountEntry> createState() => _AccountEntryState();
}

class _AccountEntryState extends State<_AccountEntry> {
  bool _registering = false;

  void _showRegister() {
    setState(() => _registering = true);
    widget.controller.clearError();
  }

  void _showLogin() {
    setState(() => _registering = false);
    widget.controller.clearError();
  }

  @override
  Widget build(BuildContext context) {
    if (_registering) {
      return RegisterPage(controller: widget.controller, onSignIn: _showLogin);
    }
    return LoginPage(
      controller: widget.controller,
      onCreateAccount: _showRegister,
    );
  }
}
