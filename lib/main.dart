import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'core/security/password_hasher.dart';
import 'core/session/session_store.dart';
import 'data/db/app_database.dart';
import 'data/repositories/auth_repository.dart';
import 'features/auth/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android usa o plugin nativo do sqflite; desktop usa SQLite via FFI.
  const desktopPlatforms = {
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  };
  if (desktopPlatforms.contains(defaultTargetPlatform)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final hasher = PasswordHasher();
  final database = await AppDatabase.open(hasher: hasher);
  final prefs = await SharedPreferences.getInstance();

  final authController = AuthController(
    repository: SqliteAuthRepository(database, hasher),
    sessionStore: PrefsSessionStore(prefs),
  );
  await authController.restoreSession();

  runApp(MultiplagierApp(authController: authController));
}
