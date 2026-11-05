/// Limite de tentativas de login (SEC-003).
///
/// Após [maxAttempts] falhas para o mesmo e-mail, bloqueia novas tentativas
/// por [lockDuration]. O estado fica em memória enquanto o app estiver aberto.
class LoginThrottle {
  LoginThrottle({
    this.maxAttempts = 5,
    this.lockDuration = const Duration(minutes: 1),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final int maxAttempts;
  final Duration lockDuration;
  final DateTime Function() _clock;

  final Map<String, _AttemptState> _byEmail = {};

  /// `null` se o e-mail puder tentar; senão, o tempo restante do bloqueio.
  Duration? remainingLock(String email) {
    final state = _byEmail[_normalize(email)];
    if (state == null || state.lockedUntil == null) return null;
    final left = state.lockedUntil!.difference(_clock());
    if (left <= Duration.zero) {
      _byEmail.remove(_normalize(email));
      return null;
    }
    return left;
  }

  bool isLocked(String email) => remainingLock(email) != null;

  void registerFailure(String email) {
    final key = _normalize(email);
    final now = _clock();
    final current = _byEmail[key];
    if (current?.lockedUntil != null && current!.lockedUntil!.isAfter(now)) {
      return;
    }

    final failures = (current?.failures ?? 0) + 1;
    if (failures >= maxAttempts) {
      _byEmail[key] = _AttemptState(
        failures: failures,
        lockedUntil: now.add(lockDuration),
      );
    } else {
      _byEmail[key] = _AttemptState(failures: failures);
    }
  }

  void registerSuccess(String email) {
    _byEmail.remove(_normalize(email));
  }

  static String _normalize(String email) => email.trim().toLowerCase();
}

class _AttemptState {
  const _AttemptState({required this.failures, this.lockedUntil});

  final int failures;
  final DateTime? lockedUntil;
}
