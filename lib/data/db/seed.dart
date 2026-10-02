import 'package:sqflite/sqflite.dart';

import '../../core/security/password_hasher.dart';

/// Credenciais do usuário de demonstração (documentadas no README).
const demoUserEmail = 'cliente@multiplagier.local';
const demoUserPassword = 'Multiplagier@2026';

/// Popula o banco com dados de demonstração: um cliente e um catálogo
/// de eletrônicos, incluindo um produto inativo para provar o filtro.
Future<void> seedDatabase(DatabaseExecutor db, PasswordHasher hasher) async {
  final now = DateTime.now().toUtc().toIso8601String();

  await db.insert('users', {
    'name': 'Cliente Demo',
    'email': demoUserEmail,
    'password_hash': hasher.hash(demoUserPassword),
    'role': 'customer',
    'created_at': now,
  });

  const products = <Map<String, Object>>[
    {
      'name': 'Smart TV 50" 4K',
      'description':
          'Smart TV LED 50 polegadas com resolução 4K, HDR e aplicativos de streaming integrados.',
      'price_cents': 249900,
      'stock': 12,
      'is_active': 1,
    },
    {
      'name': 'Fone de Ouvido Bluetooth',
      'description':
          'Headphone sem fio com cancelamento de ruído e até 30 horas de bateria.',
      'price_cents': 18990,
      'stock': 40,
      'is_active': 1,
    },
    {
      'name': 'Tablet 10" 64GB',
      'description':
          'Tablet com tela de 10 polegadas, 64GB de armazenamento e Wi-Fi.',
      'price_cents': 89900,
      'stock': 0,
      'is_active': 1,
    },
    {
      'name': 'Caixa de Som Portátil',
      'description':
          'Caixa de som Bluetooth resistente à água, com 12 horas de reprodução.',
      'price_cents': 15990,
      'stock': 25,
      'is_active': 1,
    },
    {
      'name': 'Mouse Gamer RGB',
      'description':
          'Mouse óptico com 6 botões programáveis e sensor de até 7200 DPI.',
      'price_cents': 12990,
      'stock': 30,
      'is_active': 1,
    },
    {
      'name': 'Produto Descontinuado',
      'description': 'Item fora de linha; não deve aparecer no catálogo público.',
      'price_cents': 9990,
      'stock': 3,
      'is_active': 0,
    },
  ];

  for (final product in products) {
    await db.insert('products', product);
  }
}
