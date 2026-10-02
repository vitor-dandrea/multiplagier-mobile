import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/core/theme.dart';
import 'package:multiplagier_mobile/features/auth/auth_controller.dart';
import 'package:multiplagier_mobile/features/auth/login_page.dart';

import '../support/fakes.dart';

void main() {
  late AuthController controller;

  setUp(() {
    controller = AuthController(
      repository: FakeAuthRepository(),
      sessionStore: MemorySessionStore(),
    );
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: LoginPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await tester.enterText(find.byKey(const Key('login_email')), email);
    await tester.enterText(find.byKey(const Key('login_password')), password);
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();
  }

  testWidgets('exibe marca, campos e botão de entrar', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Multiplagier'), findsOneWidget);
    expect(find.byKey(const Key('login_email')), findsOneWidget);
    expect(find.byKey(const Key('login_password')), findsOneWidget);
    expect(find.byKey(const Key('login_submit')), findsOneWidget);
  });

  testWidgets('campos vazios mostram validação e não chamam o login',
      (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    expect(controller.status, AuthStatus.unknown);
  });

  testWidgets('e-mail malformado é rejeitado', (tester) async {
    await pumpLogin(tester);

    await fillAndSubmit(tester, email: 'sem-arroba', password: 'abc');

    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
  });

  testWidgets('credenciais inválidas mostram erro genérico', (tester) async {
    await pumpLogin(tester);

    await fillAndSubmit(
      tester,
      email: 'cliente@multiplagier.local',
      password: 'errada',
    );

    expect(find.byKey(const Key('login_error')), findsOneWidget);
    expect(find.text(AuthController.invalidCredentialsMessage), findsOneWidget);
    expect(controller.status, isNot(AuthStatus.authenticated));
  });

  testWidgets('credenciais válidas autenticam o usuário', (tester) async {
    await pumpLogin(tester);

    await fillAndSubmit(
      tester,
      email: 'cliente@multiplagier.local',
      password: 'Multiplagier@2026',
    );

    expect(controller.status, AuthStatus.authenticated);
    expect(find.byKey(const Key('login_error')), findsNothing);
  });

  testWidgets('botão alterna visibilidade da senha', (tester) async {
    await pumpLogin(tester);

    EditableText field() => tester.widget<EditableText>(
          find.descendant(
            of: find.byKey(const Key('login_password')),
            matching: find.byType(EditableText),
          ),
        );

    expect(field().obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();
    expect(field().obscureText, isFalse);
  });
}
