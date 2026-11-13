import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/core/security/login_throttle.dart';
import 'package:multiplagier_mobile/core/security/password_hasher.dart';
import 'package:multiplagier_mobile/data/db/app_database.dart';
import 'package:multiplagier_mobile/data/db/seed.dart';
import 'package:multiplagier_mobile/data/models/shipping_address.dart';
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

  @override
  Future<RegistrationOutcome> register({
    required String name,
    required String email,
    required String password,
  }) => throw StateError('db offline');

  @override
  Future<ProfileUpdateOutcome> updateProfile({
    required int userId,
    required String name,
    required ShippingAddress address,
  }) => throw StateError('db offline');
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
      final unknownEmail = await controller.login(
        'ninguem@x.com',
        demoUserPassword,
      );

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

    test('cadastro válido autentica e permite um novo login', () async {
      const email = 'ana@example.com';
      const password = 'Senha1234';

      final ok = await controller.register(
        name: '  Ana Silva  ',
        email: email,
        password: password,
      );

      expect(ok, isTrue);
      expect(controller.status, AuthStatus.authenticated);
      expect(controller.user?.name, 'Ana Silva');
      expect(controller.user?.email, email);
      expect(controller.user?.role, 'customer');
      expect(session.id, controller.user!.id);
      expect(controller.isBusy, isFalse);

      final again = AuthController(
        repository: SqliteAuthRepository(database, hasher),
        sessionStore: MemorySessionStore(),
      );
      expect(await again.login(email, password), isTrue);
      expect(again.user?.name, 'Ana Silva');
    });

    test('updateProfile persiste e atualiza currentUser', () async {
      await controller.login(demoUserEmail, demoUserPassword);
      final ok = await controller.updateProfile(
        name: 'Cliente Novo Nome',
        address: const ShippingAddress(
          street: 'Rua B',
          number: '20',
          district: 'Centro',
          city: 'Mauá',
          state: 'SP',
          zip: '09310000',
        ),
      );
      expect(ok, isTrue);
      expect(controller.user?.name, 'Cliente Novo Nome');
      expect(controller.user?.address?.street, 'Rua B');
    });

    test('e-mail duplicado é recusado sem criar sessão', () async {
      final ok = await controller.register(
        name: 'Outra Pessoa',
        email: '  Cliente@Multiplagier.LOCAL ',
        password: 'Senha1234',
      );

      expect(ok, isFalse);
      expect(controller.errorMessage, AuthController.emailTakenMessage);
      expect(controller.status, isNot(AuthStatus.authenticated));
      expect(session.id, isNull);
    });

    test('senha fraca é recusada sem gravar a senha na mensagem', () async {
      const password = 'curta';
      final ok = await controller.register(
        name: 'Ana',
        email: 'ana@example.com',
        password: password,
      );

      expect(ok, isFalse);
      expect(controller.errorMessage, isNot(contains(password)));
      expect(session.id, isNull);
      final rows = await database.db.query(
        'users',
        where: 'email = ?',
        whereArgs: ['ana@example.com'],
      );
      expect(rows, isEmpty);
    });

    test('falha inesperada no cadastro não vaza detalhes', () async {
      final failing = AuthController(
        repository: _ThrowingRepository(),
        sessionStore: session,
      );

      final ok = await failing.register(
        name: 'Ana',
        email: 'ana@example.com',
        password: 'Senha1234',
      );

      expect(ok, isFalse);
      expect(
        failing.errorMessage,
        AuthController.unexpectedRegistrationMessage,
      );
      expect(failing.errorMessage, isNot(contains('db offline')));
      expect(failing.isBusy, isFalse);
    });

    test(
      'falha inesperada vira mensagem amigável sem vazar detalhes',
      () async {
        final failing = AuthController(
          repository: _ThrowingRepository(),
          sessionStore: session,
        );

        final ok = await failing.login(demoUserEmail, demoUserPassword);

        expect(ok, isFalse);
        expect(failing.errorMessage, AuthController.unexpectedErrorMessage);
        expect(failing.errorMessage, isNot(contains('db offline')));
      },
    );

    test('SEC-003 bloqueia após várias falhas e não consulta o banco', () async {
      var now = DateTime(2026, 11, 5, 16);
      final fake = FakeAuthRepository();
      final locked = AuthController(
        repository: fake,
        sessionStore: MemorySessionStore(),
        loginThrottle: LoginThrottle(
          maxAttempts: 3,
          lockDuration: const Duration(minutes: 1),
          clock: () => now,
        ),
      );

      for (var i = 0; i < 3; i++) {
        expect(await locked.login(demoUserEmail, 'errada'), isFalse);
      }
      expect(fake.authenticateCalls, 3);
      expect(locked.errorMessage, AuthController.tooManyAttemptsMessage);

      expect(await locked.login(demoUserEmail, demoUserPassword), isFalse);
      expect(fake.authenticateCalls, 3);
      expect(locked.errorMessage, AuthController.tooManyAttemptsMessage);

      now = now.add(const Duration(minutes: 1, seconds: 1));
      expect(await locked.login(demoUserEmail, demoUserPassword), isTrue);
      expect(fake.authenticateCalls, 4);
      expect(locked.status, AuthStatus.authenticated);
    });
  });
}
