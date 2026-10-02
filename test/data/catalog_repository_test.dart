import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/core/security/password_hasher.dart';
import 'package:multiplagier_mobile/data/db/app_database.dart';
import 'package:multiplagier_mobile/data/repositories/catalog_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late SqliteCatalogRepository repository;

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
      hasher: PasswordHasher(iterations: 100),
    );
    repository = SqliteCatalogRepository(database);
  });

  tearDown(() => database.close());

  group('SqliteCatalogRepository.listActiveProducts', () {
    test('lista somente produtos ativos', () async {
      final products = await repository.listActiveProducts();

      expect(products, hasLength(5));
      expect(products.every((p) => p.isActive), isTrue);
      expect(
        products.map((p) => p.name),
        isNot(contains('Produto Descontinuado')),
      );
    });

    test('ordena por nome', () async {
      final names =
          (await repository.listActiveProducts()).map((p) => p.name).toList();
      final sorted = [...names]
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      expect(names, sorted);
    });

    test('retorna lista vazia quando não há produtos ativos', () async {
      await database.db.update('products', {'is_active': 0});
      expect(await repository.listActiveProducts(), isEmpty);
    });
  });

  group('SqliteCatalogRepository.findActiveById', () {
    test('retorna produto ativo com seus dados', () async {
      final first = (await repository.listActiveProducts()).first;

      final found = await repository.findActiveById(first.id);

      expect(found, isNotNull);
      expect(found!.name, first.name);
      expect(found.priceCents, first.priceCents);
    });

    test('retorna null para id inexistente', () async {
      expect(await repository.findActiveById(9999), isNull);
    });

    test('retorna null para produto inativo', () async {
      final inactive = (await database.db.query(
        'products',
        where: 'is_active = 0',
      ))
          .first;

      expect(await repository.findActiveById(inactive['id'] as int), isNull);
    });
  });
}
