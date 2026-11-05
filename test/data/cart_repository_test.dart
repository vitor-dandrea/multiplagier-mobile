import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/core/security/password_hasher.dart';
import 'package:multiplagier_mobile/data/db/app_database.dart';
import 'package:multiplagier_mobile/data/db/seed.dart';
import 'package:multiplagier_mobile/data/repositories/auth_repository.dart';
import 'package:multiplagier_mobile/data/repositories/cart_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late SqliteCartRepository repository;
  late SqliteAuthRepository auth;
  final hasher = PasswordHasher(iterations: 100);

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
      hasher: hasher,
    );
    repository = SqliteCartRepository(database);
    auth = SqliteAuthRepository(database, hasher);
  });

  tearDown(() => database.close());

  Future<int> demoId() async {
    final rows = await database.db.query(
      'users',
      where: 'email = ?',
      whereArgs: [demoUserEmail],
    );
    return rows.single['id'] as int;
  }

  Future<Map<String, Object?>> productNamed(String name) async {
    final rows = await database.db.query(
      'products',
      where: 'name = ?',
      whereArgs: [name],
    );
    return rows.single;
  }

  group('SqliteCartRepository', () {
    test('soma quantidade do mesmo produto até o estoque', () async {
      final userId = await demoId();
      final fone = await productNamed('Fone de Ouvido Bluetooth');
      final productId = fone['id'] as int;

      expect(
        (await repository.add(userId, productId, quantity: 2)).isOk,
        isTrue,
      );
      expect((await repository.add(userId, productId)).isOk, isTrue);

      final lines = await repository.listForUser(userId);
      expect(lines, hasLength(1));
      expect(lines.single.quantity, 3);
      expect(lines.single.lineTotalCents, 18990 * 3);

      final over = await repository.add(userId, productId, quantity: 100);
      expect(over.failure, CartFailure.exceedsStock);
      expect((await repository.listForUser(userId)).single.quantity, 3);
    });

    test(
      'recusa produto inativo, sem estoque, inexistente ou quantidade inválida',
      () async {
        final userId = await demoId();
        final tablet = await productNamed('Tablet 10" 64GB');
        final hidden = await productNamed('Produto Descontinuado');

        expect(
          (await repository.add(userId, tablet['id'] as int)).failure,
          CartFailure.unavailable,
        );
        expect(
          (await repository.add(userId, hidden['id'] as int)).failure,
          CartFailure.unavailable,
        );
        expect(
          (await repository.add(userId, 9999)).failure,
          CartFailure.unavailable,
        );
        expect(
          (await repository.add(
            userId,
            tablet['id'] as int,
            quantity: 0,
          )).failure,
          CartFailure.invalidQuantity,
        );
        expect(await repository.listForUser(userId), isEmpty);
      },
    );

    test('isola o carrinho por usuário e mantém o item no banco', () async {
      final demo = await demoId();
      final other = await auth.register(
        name: 'Ana Silva',
        email: 'ana@example.com',
        password: 'Senha1234',
      );
      final mouse = await productNamed('Mouse Gamer RGB');

      expect((await repository.add(demo, mouse['id'] as int)).isOk, isTrue);

      expect(await repository.listForUser(other.user!.id), isEmpty);
      final again = SqliteCartRepository(database);
      final lines = await again.listForUser(demo);
      expect(lines.single.name, 'Mouse Gamer RGB');
    });

    test('altera quantidade, recusa acima do estoque e remove', () async {
      final userId = await demoId();
      final mouse = await productNamed('Mouse Gamer RGB');
      final productId = mouse['id'] as int;
      await repository.add(userId, productId);

      expect(
        (await repository.setQuantity(userId, productId, 50)).failure,
        CartFailure.exceedsStock,
      );
      expect((await repository.listForUser(userId)).single.quantity, 1);

      expect((await repository.setQuantity(userId, productId, 2)).isOk, isTrue);
      expect((await repository.listForUser(userId)).single.quantity, 2);

      expect(
        (await repository.setQuantity(userId, productId, 0)).failure,
        CartFailure.invalidQuantity,
      );

      await repository.remove(userId, productId);
      expect(await repository.listForUser(userId), isEmpty);
    });

    test(
      'produto desativado depois de entrar no carrinho continua visível',
      () async {
        final userId = await demoId();
        final fone = await productNamed('Fone de Ouvido Bluetooth');
        final productId = fone['id'] as int;
        await repository.add(userId, productId);
        await database.db.update(
          'products',
          {'is_active': 0},
          where: 'id = ?',
          whereArgs: [productId],
        );

        final line = (await repository.listForUser(userId)).single;
        expect(line.isActive, isFalse);
        expect(line.canCheckout, isFalse);
        expect(
          (await repository.setQuantity(userId, productId, 1)).failure,
          CartFailure.unavailable,
        );
      },
    );
  });
}
