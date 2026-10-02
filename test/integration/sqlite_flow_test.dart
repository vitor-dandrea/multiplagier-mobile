import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/app.dart';
import 'package:multiplagier_mobile/core/security/password_hasher.dart';
import 'package:multiplagier_mobile/data/db/app_database.dart';
import 'package:multiplagier_mobile/data/db/seed.dart';
import 'package:multiplagier_mobile/data/repositories/auth_repository.dart';
import 'package:multiplagier_mobile/data/repositories/catalog_repository.dart';
import 'package:multiplagier_mobile/features/auth/auth_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/fakes.dart';

/// Espera (com I/O real do SQLite) até [finder] aparecer.
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 50; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Widget não apareceu a tempo: $finder');
}

/// Fluxo ponta a ponta com SQLite real (em memória): sem fakes de dados.
void main() {
  sqfliteFfiInit();

  testWidgets('login com usuário seed e catálogo vindos do SQLite',
      (tester) async {
    final hasher = PasswordHasher(iterations: 100);
    late AppDatabase database;
    late AuthController controller;

    await tester.runAsync(() async {
      database = await AppDatabase.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
        hasher: hasher,
      );
      controller = AuthController(
        repository: SqliteAuthRepository(database, hasher),
        sessionStore: MemorySessionStore(),
      );
      await controller.restoreSession();
    });

    await tester.pumpWidget(
      MultiplagierApp(
        authController: controller,
        catalogRepository: SqliteCatalogRepository(database),
      ),
    );
    await tester.pump();

    // Senha errada: erro genérico, continua no login.
    await tester.enterText(
      find.byKey(const Key('login_email')),
      demoUserEmail,
    );
    await tester.enterText(find.byKey(const Key('login_password')), 'errada');
    await tester.tap(find.byKey(const Key('login_submit')));
    await pumpUntilFound(tester, find.byKey(const Key('login_error')));
    expect(find.text(AuthController.invalidCredentialsMessage), findsOneWidget);
    expect(find.byKey(const Key('catalog_list')), findsNothing);

    // Senha correta: entra no catálogo vindo do SQLite.
    await tester.enterText(
      find.byKey(const Key('login_password')),
      demoUserPassword,
    );
    await tester.tap(find.byKey(const Key('login_submit')));
    await pumpUntilFound(tester, find.byKey(const Key('catalog_list')));

    expect(find.text('Olá, Cliente Demo'), findsOneWidget);
    expect(find.text('Smart TV 50" 4K'), findsOneWidget);
    expect(find.text('R\$ 2.499,00'), findsOneWidget);
    expect(find.text('Produto Descontinuado'), findsNothing);

    await tester.runAsync(() => database.close());
  });
}
