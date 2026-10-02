/// Usuário autenticado. Nunca carrega o hash da senha.
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory User.fromRow(Map<String, Object?> row) {
    return User(
      id: row['id'] as int,
      name: row['name'] as String,
      email: row['email'] as String,
      role: row['role'] as String,
    );
  }

  final int id;
  final String name;
  final String email;
  final String role;
}
