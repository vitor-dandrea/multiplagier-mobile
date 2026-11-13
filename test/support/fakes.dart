import 'package:multiplagier_mobile/core/session/session_store.dart';
import 'package:multiplagier_mobile/core/validation/address_rules.dart';
import 'package:multiplagier_mobile/core/validation/input_rules.dart';
import 'package:multiplagier_mobile/data/models/shipping_address.dart';
import 'package:multiplagier_mobile/data/models/user.dart';
import 'package:multiplagier_mobile/data/repositories/auth_repository.dart';

const demoShippingAddress = ShippingAddress(
  street: 'Rua das Flores',
  number: '100',
  complement: 'Apto 12',
  district: 'Centro',
  city: 'Mauá',
  state: 'SP',
  zip: '09310000',
);

class MemorySessionStore implements SessionStore {
  int? id;

  @override
  Future<void> clear() async => id = null;

  @override
  Future<int?> readUserId() async => id;

  @override
  Future<void> saveUserId(int value) async => id = value;
}

class _Account {
  _Account(this.user, this.password);

  User user;
  final String password;
}

/// Repositório em memória. Começa com o usuário de demonstração.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.email = 'cliente@multiplagier.local',
    this.password = 'Multiplagier@2026',
    ShippingAddress? address,
  }) {
    final initialAddress = address ?? demoShippingAddress;
    _accounts.add(
      _Account(
        User(
          id: 1,
          name: 'Cliente Demo',
          email: 'cliente@multiplagier.local',
          role: 'customer',
          address: initialAddress,
        ),
        password,
      ),
    );
    if (email != user.email) {
      _accounts[0] = _Account(
        User(
          id: 1,
          name: 'Cliente Demo',
          email: email,
          role: 'customer',
          address: initialAddress,
        ),
        password,
      );
    }
  }

  final String email;
  final String password;
  int registerCalls = 0;
  int authenticateCalls = 0;
  int updateProfileCalls = 0;
  int _nextId = 2;
  final List<_Account> _accounts = [];

  static final user = User(
    id: 1,
    name: 'Cliente Demo',
    email: 'cliente@multiplagier.local',
    role: 'customer',
    address: demoShippingAddress,
  );

  @override
  Future<RegistrationOutcome> register({
    required String name,
    required String email,
    required String password,
  }) async {
    registerCalls++;
    final trimmedName = name.trim();
    if (!InputRules.isValidName(trimmedName)) {
      return const RegistrationOutcome.failure(RegistrationFailure.invalidName);
    }
    final normalizedEmail = email.trim().toLowerCase();
    if (!InputRules.isValidEmail(normalizedEmail)) {
      return const RegistrationOutcome.failure(
        RegistrationFailure.invalidEmail,
      );
    }
    if (!InputRules.isValidPassword(password)) {
      return const RegistrationOutcome.failure(
        RegistrationFailure.weakPassword,
      );
    }
    for (final account in _accounts) {
      if (account.user.email == normalizedEmail) {
        return const RegistrationOutcome.failure(
          RegistrationFailure.emailTaken,
        );
      }
    }
    final created = User(
      id: _nextId++,
      name: trimmedName,
      email: normalizedEmail,
      role: 'customer',
    );
    _accounts.add(_Account(created, password));
    return RegistrationOutcome.success(created);
  }

  @override
  Future<User?> authenticate(String inputEmail, String inputPassword) async {
    authenticateCalls++;
    final normalized = inputEmail.trim().toLowerCase();
    for (final account in _accounts) {
      if (account.user.email == normalized &&
          account.password == inputPassword) {
        return account.user;
      }
    }
    return null;
  }

  @override
  Future<User?> findById(int id) async {
    for (final account in _accounts) {
      if (account.user.id == id) return account.user;
    }
    return null;
  }

  @override
  Future<ProfileUpdateOutcome> updateProfile({
    required int userId,
    required String name,
    required ShippingAddress address,
  }) async {
    updateProfileCalls++;
    final trimmedName = name.trim();
    if (!InputRules.isValidName(trimmedName)) {
      return const ProfileUpdateOutcome.failure(
        ProfileUpdateFailure.invalidName,
      );
    }
    if (!_isValidAddress(address)) {
      return const ProfileUpdateOutcome.failure(
        ProfileUpdateFailure.invalidAddress,
      );
    }
    for (final account in _accounts) {
      if (account.user.id != userId) continue;
      final updated = account.user.copyWith(
        name: trimmedName,
        address: ShippingAddress(
          street: address.street.trim(),
          number: address.number.trim(),
          complement: address.complement?.trim().isEmpty ?? true
              ? null
              : address.complement?.trim(),
          district: address.district.trim(),
          city: address.city.trim(),
          state: address.state.trim().toUpperCase(),
          zip: AddressRules.digitsOnly(address.zip),
        ),
      );
      account.user = updated;
      return ProfileUpdateOutcome.success(updated);
    }
    return const ProfileUpdateOutcome.failure(ProfileUpdateFailure.notFound);
  }

  bool _isValidAddress(ShippingAddress address) {
    return AddressRules.isNonEmpty(address.street) &&
        AddressRules.isNonEmpty(address.number) &&
        AddressRules.isNonEmpty(address.district) &&
        AddressRules.isNonEmpty(address.city) &&
        AddressRules.isValidState(address.state) &&
        AddressRules.isValidZip(address.zip);
  }
}
