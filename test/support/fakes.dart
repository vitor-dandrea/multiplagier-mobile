import 'package:multiplagier_mobile/core/session/session_store.dart';
import 'package:multiplagier_mobile/core/validation/input_rules.dart';
import 'package:multiplagier_mobile/data/models/user.dart';
import 'package:multiplagier_mobile/data/repositories/auth_repository.dart';

class MemorySessionStore implements SessionStore {
  int? id;

  @override
  Future<void> clear() async => id = null;

  @override
  Future<int?> readUserId() async => id;

  @override
  Future<void> saveUserId(int value) async => id = value;
}

class _Account {
  _Account(this.user, this.password);

  final User user;
  final String password;
}

/// Repositório em memória. Começa com o usuário de demonstração.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.email = 'cliente@multiplagier.local',
    this.password = 'Multiplagier@2026',
  }) {
    _accounts.add(
      _Account(
        const User(
          id: 1,
          name: 'Cliente Demo',
          email: 'cliente@multiplagier.local',
          role: 'customer',
        ),
        password,
      ),
    );
    if (email != user.email) {
      _accounts[0] = _Account(
        User(id: 1, name: 'Cliente Demo', email: email, role: 'customer'),
        password,
      );
    }
  }

  final String email;
  final String password;
  int registerCalls = 0;
  int authenticateCalls = 0;
  int _nextId = 2;
  final List<_Account> _accounts = [];

  static const user = User(
    id: 1,
    name: 'Cliente Demo',
    email: 'cliente@multiplagier.local',
    role: 'customer',
  );

  @override
  Future<RegistrationOutcome> register({
    required String name,
    required String email,
    required String password,
  }) async {
    registerCalls++;
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
    for (final account in _accounts) {
      if (account.user.email == normalizedEmail) {
        return const RegistrationOutcome.failure(
          RegistrationFailure.emailTaken,
        );
      }
    }
    final created = User(
      id: _nextId++,
      name: trimmedName,
      email: normalizedEmail,
      role: 'customer',
    );
    _accounts.add(_Account(created, password));
    return RegistrationOutcome.success(created);
  }

  @override
  Future<User?> authenticate(String inputEmail, String inputPassword) async {
    authenticateCalls++;
    final normalized = inputEmail.trim().toLowerCase();
    for (final account in _accounts) {
      if (account.user.email == normalized &&
          account.password == inputPassword) {
        return account.user;
      }
    }
    return null;
  }

  @override
  Future<User?> findById(int id) async {
    for (final account in _accounts) {
      if (account.user.id == id) return account.user;
    }
    return null;
  }
}
