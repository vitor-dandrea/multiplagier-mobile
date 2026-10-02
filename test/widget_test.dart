import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/app.dart';
import 'package:multiplagier_mobile/features/auth/auth_controller.dart';

import 'support/fake_catalog.dart';
import 'support/fakes.dart';

void main() {
  late MemorySessionStore session;
  late AuthController controller;

  setUp(() {
    session = MemorySessionStore();
    controller = AuthController(
      repository: FakeAuthRepository(),
      sessionStore: session,
    );
  });

  Widget buildApp() => MultiplagierApp(
        authController: controller,
        catalogRepository: FakeCatalogRepository(),
      );

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
  }

  testWidgets('sem sessão, o app abre na tela de login', (tester) async {
    await controller.restoreSession();
    await pumpApp(tester);

    expect(find.byKey(const Key('login_submit')), findsOneWidget);
    expect(find.byKey(const Key('home_greeting')), findsNothing);
    expect(find.byKey(const Key('catalog_list')), findsNothing);
  });

  testWidgets('antes de restaurar a sessão, exibe indicador de carregamento',
      (tester) async {
    await tester.pumpWidget(buildApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('login_submit')), findsNothing);
  });

  testWidgets('fluxo completo: login, catálogo, detalhe e logout',
      (tester) async {
    await controller.restoreSession();
    await pumpApp(tester);

    await tester.enterText(
      find.byKey(const Key('login_email')),
      'cliente@multiplagier.local',
    );
    await tester.enterText(
      find.byKey(const Key('login_password')),
      'Multiplagier@2026',
    );
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    // Catálogo
    expect(find.text('Olá, Cliente Demo'), findsOneWidget);
    expect(find.byKey(const Key('catalog_list')), findsOneWidget);
    expect(find.text('Fone Bluetooth'), findsOneWidget);
    expect(session.id, FakeAuthRepository.user.id);

    // Detalhe
    await tester.tap(find.byKey(const Key('product_tile_1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('detail_name')), findsOneWidget);
    expect(find.byKey(const Key('detail_description')), findsOneWidget);

    // Volta para o catálogo
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('catalog_list')), findsOneWidget);

    // Logout
    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login_submit')), findsOneWidget);
    expect(find.byKey(const Key('catalog_list')), findsNothing);
    expect(session.id, isNull);
  });

  testWidgets('sessão salva leva direto ao catálogo', (tester) async {
    session.id = FakeAuthRepository.user.id;
    await controller.restoreSession();
    await pumpApp(tester);

    expect(find.byKey(const Key('catalog_list')), findsOneWidget);
    expect(find.byKey(const Key('login_submit')), findsNothing);
  });
}
