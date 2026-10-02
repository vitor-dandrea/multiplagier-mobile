import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';

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

  runApp(const MultiplagierApp());
}
