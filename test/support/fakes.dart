import 'package:multiplagier_mobile/core/session/session_store.dart';
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

/// Repositório em memória com um único usuário válido.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.email = 'cliente@multiplagier.local',
    this.password = 'Multiplagier@2026',
  });

  final String email;
  final String password;

  static const user = User(
    id: 1,
    name: 'Cliente Demo',
    email: 'cliente@multiplagier.local',
    role: 'customer',
  );

  @override
  Future<User?> authenticate(String inputEmail, String inputPassword) async {
    final ok = inputEmail.trim().toLowerCase() == email &&
        inputPassword == password;
    return ok ? user : null;
  }

  @override
  Future<User?> findById(int id) async => id == user.id ? user : null;
}
