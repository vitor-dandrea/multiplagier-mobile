import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/app.dart';
import 'package:multiplagier_mobile/features/auth/auth_controller.dart';

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

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(MultiplagierApp(authController: controller));
    await tester.pumpAndSettle();
  }

  testWidgets('sem sessão, o app abre na tela de login', (tester) async {
    await controller.restoreSession();
    await pumpApp(tester);

    expect(find.byKey(const Key('login_submit')), findsOneWidget);
    expect(find.byKey(const Key('home_greeting')), findsNothing);
  });

  testWidgets('antes de restaurar a sessão, exibe indicador de carregamento',
      (tester) async {
    await tester.pumpWidget(MultiplagierApp(authController: controller));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('login_submit')), findsNothing);
  });

  testWidgets('fluxo completo: login, área autenticada e logout',
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

    expect(find.byKey(const Key('home_greeting')), findsOneWidget);
    expect(find.text('Olá, Cliente Demo'), findsOneWidget);
    expect(session.id, FakeAuthRepository.user.id);

    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_submit')), findsOneWidget);
    expect(find.byKey(const Key('home_greeting')), findsNothing);
    expect(session.id, isNull);
  });

  testWidgets('sessão salva leva direto à área autenticada', (tester) async {
    session.id = FakeAuthRepository.user.id;
    await controller.restoreSession();
    await pumpApp(tester);

    expect(find.byKey(const Key('home_greeting')), findsOneWidget);
    expect(find.byKey(const Key('login_submit')), findsNothing);
  });
}
