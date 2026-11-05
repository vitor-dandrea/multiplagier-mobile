import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/core/security/password_hasher.dart';
import 'package:multiplagier_mobile/data/db/app_database.dart';
import 'package:multiplagier_mobile/data/db/seed.dart';
import 'package:path/path.dart' as p;
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
    test('cria tabelas de usuários, catálogo, carrinho e pedidos', () async {
      final tables = await database.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      expect(
        tables.map((t) => t['name']),
        containsAll([
          'users',
          'products',
          'cart_items',
          'orders',
          'order_items',
          'security_events',
        ]),
      );
    });

    test('semeia o usuário demo com senha hasheada', () async {
      final rows = await database.db.query(
        'users',
        where: 'email = ?',
        whereArgs: [demoUserEmail],
      );
      expect(rows, hasLength(1));

      final stored = rows.single['password_hash'] as String;
      expect(stored, isNot(contains(demoUserPassword)));
      expect(hasher.verify(demoUserPassword, stored), isTrue);
    });

    test('semeia produtos ativos e ao menos um inativo', () async {
      final active = await database.db.query(
        'products',
        where: 'is_active = 1',
      );
      final inactive = await database.db.query(
        'products',
        where: 'is_active = 0',
      );
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

    test(
      'impede item de carrinho sem usuário ou com quantidade inválida',
      () async {
        final product = (await database.db.query('products', limit: 1)).single;
        expect(
          () => database.db.insert('cart_items', {
            'user_id': 9999,
            'product_id': product['id'],
            'quantity': 1,
          }),
          throwsA(isA<DatabaseException>()),
        );
        final user = (await database.db.query('users', limit: 1)).single;
        expect(
          () => database.db.insert('cart_items', {
            'user_id': user['id'],
            'product_id': product['id'],
            'quantity': 0,
          }),
          throwsA(isA<DatabaseException>()),
        );
      },
    );

    test('migra um banco v1 sem apagar os usuários', () async {
      final dir = await Directory.systemTemp.createTemp('multiplagier_db_');
      final path = p.join(dir.path, 'legado.db');
      AppDatabase? upgraded;
      try {
        final legacy = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('''
                CREATE TABLE users (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  name TEXT NOT NULL,
                  email TEXT NOT NULL UNIQUE,
                  password_hash TEXT NOT NULL,
                  role TEXT NOT NULL DEFAULT 'customer',
                  created_at TEXT NOT NULL
                )
              ''');
              await db.execute('''
                CREATE TABLE products (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  name TEXT NOT NULL,
                  description TEXT NOT NULL,
                  price_cents INTEGER NOT NULL CHECK (price_cents >= 0),
                  stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
                  is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
                )
              ''');
              await db.insert('users', {
                'name': 'Cliente Antigo',
                'email': 'antigo@example.com',
                'password_hash': 'pbkdf2\$1\$aa\$bb',
                'role': 'customer',
                'created_at': '2026-01-01T00:00:00.000Z',
              });
              await db.insert('products', {
                'name': 'Rádio',
                'description': 'Rádio de mesa',
                'price_cents': 1000,
                'stock': 4,
                'is_active': 1,
              });
            },
          ),
        );
        await legacy.close();

        upgraded = await AppDatabase.open(
          factory: databaseFactoryFfi,
          path: path,
          hasher: hasher,
        );
        final users = await upgraded.db.query('users');
        expect(users, hasLength(1));
        expect(users.single['email'], 'antigo@example.com');

        final tables = await upgraded.db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        );
        expect(tables.map((t) => t['name']), contains('cart_items'));
        expect(tables.map((t) => t['name']), contains('orders'));

        final products = await upgraded.db.query('products');
        expect(products.single['category'], 'Outros');

        await upgraded.db.insert('cart_items', {
          'user_id': users.single['id'],
          'product_id': 1,
          'quantity': 2,
        });
      } finally {
        await upgraded?.close();
        if (dir.existsSync()) {
          await dir.delete(recursive: true);
        }
      }
    });

    test('migra produtos v2 preenchendo a categoria', () async {
      final dir = await Directory.systemTemp.createTemp('multiplagier_db_v2_');
      final path = p.join(dir.path, 'v2.db');
      AppDatabase? upgraded;
      try {
        final legacy = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 2,
            onCreate: (db, version) async {
              await db.execute('''
                CREATE TABLE users (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  name TEXT NOT NULL,
                  email TEXT NOT NULL UNIQUE,
                  password_hash TEXT NOT NULL,
                  role TEXT NOT NULL DEFAULT 'customer',
                  created_at TEXT NOT NULL
                )
              ''');
              await db.execute('''
                CREATE TABLE products (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  name TEXT NOT NULL,
                  description TEXT NOT NULL,
                  price_cents INTEGER NOT NULL CHECK (price_cents >= 0),
                  stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
                  is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
                )
              ''');
              await db.insert('users', {
                'name': 'Cliente',
                'email': 'v2@example.com',
                'password_hash': 'pbkdf2\$1\$aa\$bb',
                'role': 'customer',
                'created_at': '2026-01-01T00:00:00.000Z',
              });
              await db.insert('products', {
                'name': 'Smart TV 50" 4K',
                'description': 'TV',
                'price_cents': 1000,
                'stock': 1,
                'is_active': 1,
              });
              await db.insert('products', {
                'name': 'Fone de Ouvido Bluetooth',
                'description': 'Fone',
                'price_cents': 1000,
                'stock': 1,
                'is_active': 1,
              });
            },
          ),
        );
        await legacy.close();

        upgraded = await AppDatabase.open(
          factory: databaseFactoryFfi,
          path: path,
          hasher: hasher,
        );
        final rows = await upgraded.db.query('products', orderBy: 'id ASC');
        expect(rows[0]['category'], 'TVs');
        expect(rows[1]['category'], 'Áudio');
      } finally {
        await upgraded?.close();
        if (dir.existsSync()) {
          await dir.delete(recursive: true);
        }
      }
    });
  });
}
