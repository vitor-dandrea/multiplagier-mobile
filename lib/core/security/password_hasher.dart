import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Hash de senha com PBKDF2-HMAC-SHA256 e salt aleatório por senha.
///
/// Formato armazenado: `pbkdf2$<iterações>$<salt base64>$<hash base64>`.
/// A senha nunca é guardada nem logada em texto claro.
class PasswordHasher {
  PasswordHasher({this.iterations = 10000, Random? random})
      : _random = random ?? Random.secure();

  static const _scheme = 'pbkdf2';
  static const _saltLength = 16;

  final int iterations;
  final Random _random;

  String hash(String password) {
    final salt = Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => _random.nextInt(256)),
    );
    final derived = _pbkdf2(password, salt, iterations);
    return '$_scheme\$$iterations\$${base64.encode(salt)}\$${base64.encode(derived)}';
  }

  bool verify(String password, String stored) {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != _scheme) return false;

    final storedIterations = int.tryParse(parts[1]);
    if (storedIterations == null || storedIterations <= 0) return false;

    final Uint8List salt;
    final Uint8List expected;
    try {
      salt = base64.decode(parts[2]);
      expected = base64.decode(parts[3]);
    } on FormatException {
      return false;
    }

    final actual = _pbkdf2(password, salt, storedIterations);
    return _constantTimeEquals(actual, expected);
  }

  /// PBKDF2 com um único bloco de 32 bytes (tamanho do SHA-256).
  Uint8List _pbkdf2(String password, List<int> salt, int rounds) {
    final hmac = Hmac(sha256, utf8.encode(password));
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = List<int>.from(u);
    for (var i = 1; i < rounds; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return Uint8List.fromList(result);
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
