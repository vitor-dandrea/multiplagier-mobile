import 'package:flutter/foundation.dart';

import '../../core/session/session_store.dart';
import '../../core/validation/input_rules.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// Estado de autenticação do app (login, logout e restauração da sessão).
class AuthController extends ChangeNotifier {
  AuthController({required this._repository, required this._sessionStore});

  /// Mensagem genérica: não revela se o e-mail existe.
  static const invalidCredentialsMessage = 'E-mail ou senha inválidos.';
  static const unexpectedErrorMessage =
      'Não foi possível entrar. Tente novamente.';
  static const emailTakenMessage = 'Este e-mail já está cadastrado.';
  static const unexpectedRegistrationMessage =
      'Não foi possível criar a conta. Tente novamente.';

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

  /// Cria a conta e abre a sessão. Retorna `true` em caso de sucesso.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final outcome = await _repository.register(
        name: name,
        email: email,
        password: password,
      );
      final user = outcome.user;
      if (user == null) {
        _errorMessage = _registrationMessage(outcome.failure);
        return false;
      }
      await _sessionStore.saveUserId(user.id);
      _setSession(user);
      return true;
    } catch (_) {
      _errorMessage = unexpectedRegistrationMessage;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
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

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  String _registrationMessage(RegistrationFailure? failure) {
    switch (failure) {
      case RegistrationFailure.emailTaken:
        return emailTakenMessage;
      case RegistrationFailure.weakPassword:
        return InputRules.weakPasswordMessage;
      case RegistrationFailure.invalidEmail:
        return InputRules.invalidEmailMessage;
      case RegistrationFailure.invalidName:
        return InputRules.invalidNameMessage;
      case null:
        return unexpectedRegistrationMessage;
    }
  }

  void _setSession(User? user) {
    _user = user;
    _status = user == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    notifyListeners();
  }
}
