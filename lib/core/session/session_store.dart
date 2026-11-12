import 'package:shared_preferences/shared_preferences.dart';

/// Persistência mínima da sessão: apenas o id do usuário logado.
/// Nunca guarda e-mail, senha ou hash.
abstract class SessionStore {
  Future<int?> readUserId();
  Future<void> saveUserId(int id);
  Future<void> clear();
}

class PrefsSessionStore implements SessionStore {
  PrefsSessionStore(this._prefs);

  static const _key = 'session_user_id';

  final SharedPreferences _prefs;

  @override
  Future<int?> readUserId() async => _prefs.getInt(_key);

  @override
  Future<void> saveUserId(int id) => _prefs.setInt(_key, id);

  @override
  Future<void> clear() => _prefs.remove(_key);
}
