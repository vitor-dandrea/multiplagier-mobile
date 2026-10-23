import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/core/theme.dart';
import 'package:multiplagier_mobile/core/validation/input_rules.dart';
import 'package:multiplagier_mobile/features/auth/auth_controller.dart';
import 'package:multiplagier_mobile/features/auth/register_page.dart';

import '../support/fakes.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthController controller;

  setUp(() {
    repository = FakeAuthRepository();
    controller = AuthController(
      repository: repository,
      sessionStore: MemorySessionStore(),
    );
  });

  Future<void> pumpRegister(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: RegisterPage(controller: controller, onSignIn: () {}),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fill(
    WidgetTester tester, {
    String name = 'Ana Silva',
    String email = 'ana@example.com',
    String password = 'Senha1234',
    String confirm = 'Senha1234',
  }) async {
    await tester.enterText(find.byKey(const Key('register_name')), name);
    await tester.enterText(find.byKey(const Key('register_email')), email);
    await tester.enterText(
      find.byKey(const Key('register_password')),
      password,
    );
    await tester.enterText(
      find.byKey(const Key('register_password_confirm')),
      confirm,
    );
  }

  testWidgets('campos vazios não chamam o cadastro', (tester) async {
    await pumpRegister(tester);

    await tester.tap(find.byKey(const Key('register_submit')));
    await tester.pumpAndSettle();

    expect(find.text(InputRules.emptyNameMessage), findsOneWidget);
    expect(find.text(InputRules.emptyEmailMessage), findsOneWidget);
    expect(find.text(InputRules.emptyNewPasswordMessage), findsWidgets);
    expect(repository.registerCalls, 0);
    expect(controller.status, AuthStatus.unknown);
  });

  testWidgets('senha fraca e confirmação diferente são rejeitadas', (
    tester,
  ) async {
    await pumpRegister(tester);
    await fill(tester, password: 'somente', confirm: 'somente');
    await tester.tap(find.byKey(const Key('register_submit')));
    await tester.pumpAndSettle();

    expect(find.text(InputRules.weakPasswordMessage), findsOneWidget);
    expect(repository.registerCalls, 0);

    await fill(tester, confirm: 'Senha9999');
    await tester.tap(find.byKey(const Key('register_submit')));
    await tester.pumpAndSettle();

    expect(find.text(InputRules.passwordMismatchMessage), findsOneWidget);
    expect(repository.registerCalls, 0);
  });

  testWidgets('e-mail já cadastrado mostra mensagem clara', (tester) async {
    await pumpRegister(tester);
    await fill(
      tester,
      email: 'Cliente@Multiplagier.local',
      password: 'OutraSenha1',
      confirm: 'OutraSenha1',
    );
    await tester.tap(find.byKey(const Key('register_submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('register_error')), findsOneWidget);
    expect(find.text(AuthController.emailTakenMessage), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('register_error'))).data,
      isNot(contains('OutraSenha1')),
    );
    expect(controller.status, isNot(AuthStatus.authenticated));
  });

  testWidgets('cadastro válido autentica', (tester) async {
    await pumpRegister(tester);
    await fill(tester);
    await tester.tap(find.byKey(const Key('register_submit')));
    await tester.pumpAndSettle();

    expect(controller.status, AuthStatus.authenticated);
    expect(controller.user?.name, 'Ana Silva');
    expect(controller.user?.role, 'customer');
    expect(find.byKey(const Key('register_error')), findsNothing);
  });
}
