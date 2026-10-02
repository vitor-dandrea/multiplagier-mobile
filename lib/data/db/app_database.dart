import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/security/password_hasher.dart';
import 'seed.dart';

/// Acesso ao banco SQLite local do app.
///
/// O schema espelha, de forma reduzida, o domínio do Multiplagier web
/// (usuários e produtos com flag `is_active`).
class AppDatabase {
  AppDatabase._(this.db);

  static const _schemaVersion = 1;
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
        onCreate: (db, version) async {
          await _createSchema(db);
          await seedDatabase(db, passwordHasher);
        },
      ),
    );
    return AppDatabase._(db);
  }

  static Future<void> _createSchema(Database db) async {
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
  }

  Future<void> close() => db.close();
}
