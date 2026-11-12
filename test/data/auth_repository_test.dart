import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/core/security/password_hasher.dart';
import 'package:multiplagier_mobile/data/db/app_database.dart';
import 'package:multiplagier_mobile/data/db/seed.dart';
import 'package:multiplagier_mobile/data/repositories/auth_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late SqliteAuthRepository repository;
  final hasher = PasswordHasher(iterations: 100);

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
      hasher: hasher,
    );
    repository = SqliteAuthRepository(database, hasher);
  });

  tearDown(() => database.close());

  group('SqliteAuthRepository.authenticate', () {
    test('retorna o usuário com credenciais válidas', () async {
      final user = await repository.authenticate(
        demoUserEmail,
        demoUserPassword,
      );
      expect(user, isNotNull);
      expect(user!.email, demoUserEmail);
      expect(user.role, 'customer');
    });

    test('normaliza e-mail (espaços e maiúsculas)', () async {
      final user = await repository.authenticate(
        '  Cliente@Multiplagier.LOCAL ',
        demoUserPassword,
      );
      expect(user, isNotNull);
    });

    test('retorna null para senha incorreta', () async {
      expect(await repository.authenticate(demoUserEmail, 'errada'), isNull);
    });

    test('retorna null para e-mail inexistente', () async {
      expect(
        await repository.authenticate('ninguem@x.com', demoUserPassword),
        isNull,
      );
    });
  });

  group('SqliteAuthRepository.findById', () {
    test('encontra usuário existente e ignora inexistente', () async {
      final logged = await repository.authenticate(
        demoUserEmail,
        demoUserPassword,
      );
      expect((await repository.findById(logged!.id))?.email, demoUserEmail);
      expect(await repository.findById(9999), isNull);
    });
  });

  group('SqliteAuthRepository.register', () {
    test('grava cliente com senha hasheada e permite autenticar', () async {
      const email = 'Ana@Example.com';
      const password = 'Senha1234';

      final outcome = await repository.register(
        name: '  Ana Silva  ',
        email: '  $email ',
        password: password,
      );

      expect(outcome.failure, isNull);
      expect(outcome.user?.name, 'Ana Silva');
      expect(outcome.user?.email, 'ana@example.com');
      expect(outcome.user?.role, 'customer');

      final rows = await database.db.query(
        'users',
        where: 'id = ?',
        whereArgs: [outcome.user!.id],
      );
      final stored = rows.single['password_hash'] as String;
      expect(stored, isNot(contains(password)));
      expect(hasher.verify(password, stored), isTrue);
      expect(rows.single['role'], 'customer');

      final logged = await repository.authenticate(email, password);
      expect(logged?.id, outcome.user!.id);
    });

    test('rejeita e-mail duplicado sem distinguir maiúsculas', () async {
      final outcome = await repository.register(
        name: 'Outra Pessoa',
        email: 'CLIENTE@multiplagier.local',
        password: 'Senha1234',
      );

      expect(outcome.user, isNull);
      expect(outcome.failure, RegistrationFailure.emailTaken);
      final rows = await database.db.query('users');
      expect(rows, hasLength(1));
    });

    test('rejeita nome, e-mail ou senha inválidos sem inserir', () async {
      Future<void> reject({
        required String name,
        required String email,
        required String password,
        required RegistrationFailure failure,
      }) async {
        final outcome = await repository.register(
          name: name,
          email: email,
          password: password,
        );
        expect(outcome.failure, failure);
      }

      await reject(
        name: 'A',
        email: 'a@example.com',
        password: 'Senha1234',
        failure: RegistrationFailure.invalidName,
      );
      await reject(
        name: 'Ana',
        email: 'sem-arroba',
        password: 'Senha1234',
        failure: RegistrationFailure.invalidEmail,
      );
      await reject(
        name: 'Ana',
        email: 'ana@example.com',
        password: 'somente',
        failure: RegistrationFailure.weakPassword,
      );
      await reject(
        name: 'Ana',
        email: 'ana@example.com',
        password: '1' * 200,
        failure: RegistrationFailure.weakPassword,
      );

      final rows = await database.db.query('users');
      expect(rows, hasLength(1));
    });

    test('grava o nome como texto, sem interpretar SQL', () async {
      const payload = "Ana'; DROP TABLE users;--";
      final outcome = await repository.register(
        name: payload,
        email: 'ana@example.com',
        password: 'Senha1234',
      );

      expect(outcome.user?.name, payload);
      final tables = await database.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'users'",
      );
      expect(tables, isNotEmpty);
      final stored = await repository.findById(outcome.user!.id);
      expect(stored?.name, payload);
    });
  });
}
