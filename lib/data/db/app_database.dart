import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/security/password_hasher.dart';
import 'seed.dart';

/// Acesso ao banco SQLite local do app.
///
/// O schema espelha, de forma reduzida, o domínio do Multiplagier web:
/// usuários, produtos, carrinho e pedidos do próprio cliente.
class AppDatabase {
  AppDatabase._(this.db);

  static const _schemaVersion = 4;
  static const _fileName = 'multiplagier.db';

  final Database db;

  /// Abre (e cria, se necessário) o banco.
  ///
  /// - [factory]: permite injetar `databaseFactoryFfi` em testes/desktop.
  /// - [path]: use `inMemoryDatabasePath` para um banco descartável.
  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
    PasswordHasher? hasher,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath =
        path ?? p.join(await dbFactory.getDatabasesPath(), _fileName);
    final passwordHasher = hasher ?? PasswordHasher();

    final db = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _schemaVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createSchema(db);
          await seedDatabase(db, passwordHasher);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createCommerceSchema(db);
          }
          if (oldVersion < 3) {
            await _migrateProductsCategory(db);
          }
          if (oldVersion < 4) {
            await _migrateOrdersPayment(db);
          }
        },
      ),
    );
    return AppDatabase._(db);
  }

  static Future<void> _createSchema(DatabaseExecutor db) async {
    await _createCatalogSchema(db);
    await _createCommerceSchema(db);
  }

  static Future<void> _createCatalogSchema(DatabaseExecutor db) async {
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
        category TEXT NOT NULL DEFAULT 'Outros',
        price_cents INTEGER NOT NULL CHECK (price_cents >= 0),
        stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
        is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
      )
    ''');
  }

  static Future<void> _migrateProductsCategory(DatabaseExecutor db) async {
    await db.execute(
      "ALTER TABLE products ADD COLUMN category TEXT NOT NULL DEFAULT 'Outros'",
    );
    await db.execute(
      "UPDATE products SET category = 'TVs' WHERE name LIKE 'Smart TV%'",
    );
    await db.execute(
      "UPDATE products SET category = 'Áudio' "
      "WHERE name LIKE 'Fone%' OR name LIKE 'Caixa%'",
    );
    await db.execute(
      "UPDATE products SET category = 'Tablets' WHERE name LIKE 'Tablet%'",
    );
    await db.execute(
      "UPDATE products SET category = 'Periféricos' WHERE name LIKE 'Mouse%'",
    );
  }

  static Future<void> _migrateOrdersPayment(DatabaseExecutor db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'orders'",
    );
    if (tables.isEmpty) return;

    final cols = await db.rawQuery('PRAGMA table_info(orders)');
    final names = cols.map((c) => c['name'] as String).toSet();
    if (!names.contains('payment_method')) {
      await db.execute('ALTER TABLE orders ADD COLUMN payment_method TEXT');
    }
    if (!names.contains('payment_last4')) {
      await db.execute('ALTER TABLE orders ADD COLUMN payment_last4 TEXT');
    }
  }

  static Future<void> _createCommerceSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE cart_items (
        user_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        PRIMARY KEY (user_id, product_id),
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        total_cents INTEGER NOT NULL CHECK (total_cents >= 0),
        created_at TEXT NOT NULL,
        payment_method TEXT,
        payment_last4 TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_orders_user_id ON orders (user_id)
    ''');
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        unit_price_cents INTEGER NOT NULL CHECK (unit_price_cents >= 0),
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        FOREIGN KEY (order_id) REFERENCES orders (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_order_items_order_id ON order_items (order_id)
    ''');
    // Auditoria mínima (SEC-001): tipo do evento, ator e id do recurso.
    // Sem senha, e-mail, itens ou dados do dono do pedido.
    await db.execute('''
      CREATE TABLE security_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type TEXT NOT NULL,
        actor_user_id INTEGER,
        resource_type TEXT NOT NULL,
        resource_id INTEGER,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() => db.close();
}
