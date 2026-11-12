import 'package:sqflite/sqflite.dart';

import '../../core/security/password_hasher.dart';
import '../../core/validation/address_rules.dart';
import '../../core/validation/input_rules.dart';
import '../db/app_database.dart';
import '../models/shipping_address.dart';
import '../models/user.dart';

enum RegistrationFailure { invalidName, invalidEmail, weakPassword, emailTaken }

enum ProfileUpdateFailure { invalidName, invalidAddress, notFound }

/// Resultado de [AuthRepository.register]. Falhas esperadas não são exceção.
class RegistrationOutcome {
  const RegistrationOutcome.success(this.user) : failure = null;

  const RegistrationOutcome.failure(this.failure) : user = null;

  final User? user;
  final RegistrationFailure? failure;
}

class ProfileUpdateOutcome {
  const ProfileUpdateOutcome.success(this.user) : failure = null;

  const ProfileUpdateOutcome.failure(this.failure) : user = null;

  final User? user;
  final ProfileUpdateFailure? failure;
}

/// Contrato de autenticação e cadastro (US-001 e US-002).
abstract class AuthRepository {
  /// Cria um cliente. O papel é sempre `customer` — o chamador não escolhe.
  Future<RegistrationOutcome> register({
    required String name,
    required String email,
    required String password,
  });

  /// Retorna o usuário se as credenciais forem válidas; `null` caso contrário.
  ///
  /// Não distingue "e-mail inexistente" de "senha incorreta".
  Future<User?> authenticate(String email, String password);

  Future<User?> findById(int id);

  /// Atualiza nome e endereço. E-mail e senha não mudam nesta operação.
  Future<ProfileUpdateOutcome> updateProfile({
    required int userId,
    required String name,
    required ShippingAddress address,
  });
}

class SqliteAuthRepository implements AuthRepository {
  SqliteAuthRepository(this._database, this._hasher);

  final AppDatabase _database;
  final PasswordHasher _hasher;

  // Hash usado quando o e-mail não existe, para que o custo da verificação
  // seja o mesmo e a resposta não revele se a conta existe.
  late final String _dummyHash = _hasher.hash('senha-inexistente');

  @override
  Future<RegistrationOutcome> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmedName = name.trim();
    if (!InputRules.isValidName(trimmedName)) {
      return const RegistrationOutcome.failure(RegistrationFailure.invalidName);
    }

    final normalizedEmail = email.trim().toLowerCase();
    if (!InputRules.isValidEmail(normalizedEmail)) {
      return const RegistrationOutcome.failure(
        RegistrationFailure.invalidEmail,
      );
    }

    if (!InputRules.isValidPassword(password)) {
      return const RegistrationOutcome.failure(
        RegistrationFailure.weakPassword,
      );
    }

    try {
      final id = await _database.db.insert('users', {
        'name': trimmedName,
        'email': normalizedEmail,
        'password_hash': _hasher.hash(password),
        'role': 'customer',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      return RegistrationOutcome.success(
        User(
          id: id,
          name: trimmedName,
          email: normalizedEmail,
          role: 'customer',
        ),
      );
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        return const RegistrationOutcome.failure(
          RegistrationFailure.emailTaken,
        );
      }
      rethrow;
    }
  }

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

  @override
  Future<ProfileUpdateOutcome> updateProfile({
    required int userId,
    required String name,
    required ShippingAddress address,
  }) async {
    final trimmedName = name.trim();
    if (!InputRules.isValidName(trimmedName)) {
      return const ProfileUpdateOutcome.failure(
        ProfileUpdateFailure.invalidName,
      );
    }
    if (!_isValidAddress(address)) {
      return const ProfileUpdateOutcome.failure(
        ProfileUpdateFailure.invalidAddress,
      );
    }

    final updated = await _database.db.update(
      'users',
      {
        'name': trimmedName,
        ...address.toUserColumns(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (updated != 1) {
      return const ProfileUpdateOutcome.failure(ProfileUpdateFailure.notFound);
    }
    final user = await findById(userId);
    if (user == null) {
      return const ProfileUpdateOutcome.failure(ProfileUpdateFailure.notFound);
    }
    return ProfileUpdateOutcome.success(user);
  }

  bool _isValidAddress(ShippingAddress address) {
    return AddressRules.isNonEmpty(address.street) &&
        AddressRules.isNonEmpty(address.number) &&
        AddressRules.isNonEmpty(address.district) &&
        AddressRules.isNonEmpty(address.city) &&
        AddressRules.isValidState(address.state) &&
        AddressRules.isValidZip(address.zip);
  }
}
