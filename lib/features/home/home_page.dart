import 'package:flutter/material.dart';

import '../../data/models/user.dart';
import '../auth/auth_controller.dart';

/// Área autenticada. O catálogo substitui o corpo nas próximas entregas.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.user, required this.authController});

  final User user;
  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiplagier'),
        actions: [
          IconButton(
            key: const Key('logout_button'),
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: authController.logout,
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Olá, ${user.name}',
          key: const Key('home_greeting'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
