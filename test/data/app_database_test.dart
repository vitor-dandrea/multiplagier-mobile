import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/core/security/password_hasher.dart';
import 'package:multiplagier_mobile/data/db/app_database.dart';
import 'package:multiplagier_mobile/data/db/seed.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  final hasher = PasswordHasher(iterations: 100);

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
      hasher: hasher,
    );
  });

  tearDown(() => database.close());

  group('AppDatabase', () {
    test('cria as tabelas users e products', () async {
      final tables = await database.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN ('users', 'products')",
      );
      expect(tables.map((t) => t['name']), containsAll(['users', 'products']));
    });

    test('semeia o usuário demo com senha hasheada', () async {
      final rows = await database.db
          .query('users', where: 'email = ?', whereArgs: [demoUserEmail]);
      expect(rows, hasLength(1));

      final stored = rows.single['password_hash'] as String;
      expect(stored, isNot(contains(demoUserPassword)));
      expect(hasher.verify(demoUserPassword, stored), isTrue);
    });

    test('semeia produtos ativos e ao menos um inativo', () async {
      final active = await database.db
          .query('products', where: 'is_active = 1');
      final inactive = await database.db
          .query('products', where: 'is_active = 0');
      expect(active.length, greaterThanOrEqualTo(3));
      expect(inactive, isNotEmpty);
    });

    test('impede e-mails duplicados', () async {
      expect(
        () => database.db.insert('users', {
          'name': 'Outro',
          'email': demoUserEmail,
          'password_hash': 'x',
          'created_at': DateTime.now().toIso8601String(),
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
