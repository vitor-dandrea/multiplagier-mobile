import 'package:flutter/material.dart';

import '../../data/models/user.dart';
import 'auth_controller.dart';
import 'login_page.dart';

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
            return LoginPage(controller: controller);
          case AuthStatus.authenticated:
            return authenticatedBuilder(context, user!);
        }
      },
    );
  }
}
