import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/features/account/account_page.dart';
import 'package:multiplagier_mobile/features/auth/auth_controller.dart';

import '../support/fakes.dart';

void main() {
  late AuthController auth;

  setUp(() async {
    auth = AuthController(
      repository: FakeAuthRepository(),
      sessionStore: MemorySessionStore(),
    );
    await auth.login('cliente@multiplagier.local', 'Multiplagier@2026');
  });

  testWidgets('salva nome e endereço e permite sair', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: AccountPage(authController: auth)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('account_email')), findsOneWidget);

    Future<void> fill(Key key, String value) async {
      final finder = find.byKey(key);
      await tester.scrollUntilVisible(
        finder,
        80,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(finder, value);
    }

    await fill(const Key('account_name'), 'Cliente X');
    await fill(const Key('account_zip'), '09310000');
    await fill(const Key('account_street'), 'Rua Nova');
    await fill(const Key('account_number'), '55');
    await fill(const Key('account_district'), 'Centro');
    await fill(const Key('account_city'), 'Mauá');
    await fill(const Key('account_state'), 'SP');

    await tester.scrollUntilVisible(
      find.byKey(const Key('account_save')),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    // Botão Salvar fica no rodapé (fora do ListView).
    await tester.ensureVisible(find.byKey(const Key('account_save')));
    await tester.tap(find.byKey(const Key('account_save')));
    await tester.pumpAndSettle();

    expect(find.text(AuthController.profileSavedMessage), findsOneWidget);
    expect(auth.user?.name, 'Cliente X');
    expect(auth.user?.address?.street, 'Rua Nova');

    await tester.tap(find.byKey(const Key('account_logout')));
    await tester.pumpAndSettle();
    expect(auth.status, AuthStatus.unauthenticated);
  });
}
