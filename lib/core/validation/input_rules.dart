/// Regras de entrada do cadastro. A UI e o repositório usam as mesmas
/// funções: ocultar o botão não substitui a validação na persistência.
class InputRules {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _controlChars = RegExp(r'[\u0000-\u001F\u007F]');
  static final _letter = RegExp(r'[A-Za-z]');
  static final _digit = RegExp(r'\d');

  static const emptyNameMessage = 'Informe seu nome.';
  static const invalidNameMessage =
      'Informe um nome válido (entre 2 e 80 caracteres).';
  static const emptyEmailMessage = 'Informe seu e-mail.';
  static const invalidEmailMessage = 'Informe um e-mail válido.';
  static const emptyPasswordMessage = 'Informe sua senha.';
  static const emptyNewPasswordMessage = 'Informe uma senha.';
  static const weakPasswordMessage =
      'A senha deve ter pelo menos 8 caracteres, com letras e números.';
  static const passwordMismatchMessage = 'As senhas não coincidem.';

  static const minNameLength = 2;
  static const maxNameLength = 80;
  static const maxEmailLength = 254;

  /// Teto do PBKDF2: senhas enormes só aumentam o custo da verificação.
  static const minPasswordLength = 8;
  static const maxPasswordLength = 128;

  static bool isValidName(String name) {
    final trimmed = name.trim();
    if (trimmed.length < minNameLength || trimmed.length > maxNameLength) {
      return false;
    }
    return !_controlChars.hasMatch(trimmed);
  }

  static bool isValidEmail(String email) {
    final value = email.trim();
    if (value.isEmpty || value.length > maxEmailLength) return false;
    return _email.hasMatch(value);
  }

  static bool isValidPassword(String password) {
    if (password.length < minPasswordLength ||
        password.length > maxPasswordLength) {
      return false;
    }
    return _letter.hasMatch(password) && _digit.hasMatch(password);
  }
}
