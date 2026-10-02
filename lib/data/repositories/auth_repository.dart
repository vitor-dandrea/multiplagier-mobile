import '../../core/security/password_hasher.dart';
import '../db/app_database.dart';
import '../models/user.dart';

/// Contrato de autenticação (US-002 do backlog do Multiplagier).
abstract class AuthRepository {
  /// Retorna o usuário se as credenciais forem válidas; `null` caso contrário.
  ///
  /// Não distingue "e-mail inexistente" de "senha incorreta".
  Future<User?> authenticate(String email, String password);

  Future<User?> findById(int id);
}

class SqliteAuthRepository implements AuthRepository {
  SqliteAuthRepository(this._database, this._hasher);

  final AppDatabase _database;
  final PasswordHasher _hasher;

  // Hash usado quando o e-mail não existe, para que o custo da verificação
  // seja o mesmo e a resposta não revele se a conta existe.
  late final String _dummyHash = _hasher.hash('senha-inexistente');

  @override
  Future<User?> authenticate(String email, String password) async {
    final rows = await _database.db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );

    if (rows.isEmpty) {
      _hasher.verify(password, _dummyHash);
      return null;
    }

    final row = rows.single;
    final valid = _hasher.verify(password, row['password_hash'] as String);
    return valid ? User.fromRow(row) : null;
  }

  @override
  Future<User?> findById(int id) async {
    final rows = await _database.db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : User.fromRow(rows.single);
  }
}
