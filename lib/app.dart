import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_gate.dart';
import 'features/home/home_page.dart';

class MultiplagierApp extends StatelessWidget {
  const MultiplagierApp({super.key, required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multiplagier',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: AuthGate(
        controller: authController,
        authenticatedBuilder: (context, user) =>
            HomePage(user: user, authController: authController),
      ),
    );
  }
}
