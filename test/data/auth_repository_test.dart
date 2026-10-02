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
}
