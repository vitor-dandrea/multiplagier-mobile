import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/core/security/login_throttle.dart';

void main() {
  test('bloqueia após o máximo de falhas e libera quando o tempo passa', () {
    var now = DateTime(2026, 11, 5, 15);
    final throttle = LoginThrottle(
      maxAttempts: 3,
      lockDuration: const Duration(minutes: 1),
      clock: () => now,
    );

    throttle.registerFailure('User@Mail.com');
    throttle.registerFailure('user@mail.com');
    expect(throttle.isLocked('user@mail.com'), isFalse);

    throttle.registerFailure('user@mail.com');
    expect(throttle.isLocked('USER@mail.com'), isTrue);
    expect(
      throttle.remainingLock('user@mail.com'),
      const Duration(minutes: 1),
    );

    now = now.add(const Duration(minutes: 1, seconds: 1));
    expect(throttle.isLocked('user@mail.com'), isFalse);
  });

  test('sucesso limpa as falhas do e-mail', () {
    final throttle = LoginThrottle(maxAttempts: 2);
    throttle.registerFailure('a@b.com');
    throttle.registerSuccess('a@b.com');
    throttle.registerFailure('a@b.com');
    expect(throttle.isLocked('a@b.com'), isFalse);
  });

  test('falhas extras durante o bloqueio não estendem o prazo', () {
    var now = DateTime(2026, 11, 5, 12);
    final throttle = LoginThrottle(
      maxAttempts: 2,
      lockDuration: const Duration(minutes: 5),
      clock: () => now,
    );

    throttle.registerFailure('x@y.com');
    throttle.registerFailure('x@y.com');
    final first = throttle.remainingLock('x@y.com');
    now = now.add(const Duration(minutes: 1));
    throttle.registerFailure('x@y.com');
    expect(throttle.remainingLock('x@y.com'), first! - const Duration(minutes: 1));
  });
}
