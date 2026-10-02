import 'package:flutter/foundation.dart';

import '../../core/session/session_store.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// Estado de autenticação do app (login, logout e restauração da sessão).
class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository repository,
    required SessionStore sessionStore,
  })  : _repository = repository,
        _sessionStore = sessionStore;

  /// Mensagem genérica: não revela se o e-mail existe.
  static const invalidCredentialsMessage = 'E-mail ou senha inválidos.';
  static const unexpectedErrorMessage =
      'Não foi possível entrar. Tente novamente.';

  final AuthRepository _repository;
  final SessionStore _sessionStore;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _errorMessage;
  bool _busy = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _busy;

  /// Restaura a sessão salva, se o usuário ainda existir.
  Future<void> restoreSession() async {
    try {
      final id = await _sessionStore.readUserId();
      final user = id == null ? null : await _repository.findById(id);
      if (user == null) {
        await _sessionStore.clear();
        _setSession(null);
      } else {
        _setSession(user);
      }
    } catch (_) {
      _setSession(null);
    }
  }

  /// Retorna `true` em caso de sucesso.
  Future<bool> login(String email, String password) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _repository.authenticate(email, password);
      if (user == null) {
        _errorMessage = invalidCredentialsMessage;
        return false;
      }
      await _sessionStore.saveUserId(user.id);
      _setSession(user);
      return true;
    } catch (_) {
      _errorMessage = unexpectedErrorMessage;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _sessionStore.clear();
    _errorMessage = null;
    _setSession(null);
  }

  void _setSession(User? user) {
    _user = user;
    _status =
        user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    notifyListeners();
  }
}
