import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/core/security/password_hasher.dart';
import 'package:multiplagier_mobile/data/db/app_database.dart';
import 'package:multiplagier_mobile/data/db/seed.dart';
import 'package:multiplagier_mobile/data/models/user.dart';
import 'package:multiplagier_mobile/data/repositories/auth_repository.dart';
import 'package:multiplagier_mobile/features/auth/auth_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/fakes.dart';

class _ThrowingRepository implements AuthRepository {
  @override
  Future<User?> authenticate(String email, String password) =>
      throw StateError('db offline');

  @override
  Future<User?> findById(int id) => throw StateError('db offline');
}

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late MemorySessionStore session;
  late AuthController controller;
  final hasher = PasswordHasher(iterations: 100);

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
      hasher: hasher,
    );
    session = MemorySessionStore();
    controller = AuthController(
      repository: SqliteAuthRepository(database, hasher),
      sessionStore: session,
    );
  });

  tearDown(() => database.close());

  group('AuthController', () {
    test('login válido autentica e persiste a sessão', () async {
      final ok = await controller.login(demoUserEmail, demoUserPassword);

      expect(ok, isTrue);
      expect(controller.status, AuthStatus.authenticated);
      expect(controller.user?.email, demoUserEmail);
      expect(controller.errorMessage, isNull);
      expect(session.id, controller.user!.id);
    });

    test('login inválido usa mensagem genérica e não cria sessão', () async {
      final wrongPassword = await controller.login(demoUserEmail, 'errada');
      final unknownEmail =
          await controller.login('ninguem@x.com', demoUserPassword);

      expect(wrongPassword, isFalse);
      expect(unknownEmail, isFalse);
      expect(controller.errorMessage, AuthController.invalidCredentialsMessage);
      expect(controller.status, isNot(AuthStatus.authenticated));
      expect(session.id, isNull);
    });

    test('restoreSession recupera usuário salvo', () async {
      await controller.login(demoUserEmail, demoUserPassword);
      final restored = AuthController(
        repository: SqliteAuthRepository(database, hasher),
        sessionStore: session,
      );

      await restored.restoreSession();

      expect(restored.status, AuthStatus.authenticated);
      expect(restored.user?.email, demoUserEmail);
    });

    test('restoreSession descarta sessão de usuário inexistente', () async {
      session.id = 9999;

      await controller.restoreSession();

      expect(controller.status, AuthStatus.unauthenticated);
      expect(session.id, isNull);
    });

    test('logout encerra a sessão', () async {
      await controller.login(demoUserEmail, demoUserPassword);
      await controller.logout();

      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.user, isNull);
      expect(session.id, isNull);
    });

    test('falha inesperada vira mensagem amigável sem vazar detalhes', () async {
      final failing = AuthController(
        repository: _ThrowingRepository(),
        sessionStore: session,
      );

      final ok = await failing.login(demoUserEmail, demoUserPassword);

      expect(ok, isFalse);
      expect(failing.errorMessage, AuthController.unexpectedErrorMessage);
      expect(failing.errorMessage, isNot(contains('db offline')));
    });
  });
}
