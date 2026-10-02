import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/repositories/catalog_repository.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_gate.dart';
import 'features/home/home_page.dart';

class MultiplagierApp extends StatelessWidget {
  const MultiplagierApp({
    super.key,
    required this.authController,
    required this.catalogRepository,
  });

  final AuthController authController;
  final CatalogRepository catalogRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multiplagier',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: AuthGate(
        controller: authController,
        authenticatedBuilder: (context, user) => HomePage(
          user: user,
          authController: authController,
          catalogRepository: catalogRepository,
        ),
      ),
    );
  }
}
