// Gera as capturas de tela usadas como evidência no relatório de status.
//
// Renderiza as telas reais do app (SQLite real em memória, tema real) em
// tamanho de celular e grava PNGs em docs/evidencias/.
//
// Uso (a partir da raiz do projeto):
//   flutter test tool/screenshots/capture_screens_test.dart
//
// Observação: não é um print de emulador; é a renderização do app via
// flutter_test. Não faz parte da suíte regular (`flutter test` não a executa).
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/app.dart';
import 'package:multiplagier_mobile/core/security/password_hasher.dart';
import 'package:multiplagier_mobile/core/session/session_store.dart';
import 'package:multiplagier_mobile/data/db/app_database.dart';
import 'package:multiplagier_mobile/data/db/seed.dart';
import 'package:multiplagier_mobile/data/repositories/auth_repository.dart';
import 'package:multiplagier_mobile/data/repositories/catalog_repository.dart';
import 'package:multiplagier_mobile/features/auth/auth_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _fontsDir = r'C:\flutter\bin\cache\artifacts\material_fonts';
const _outDir = 'docs/evidencias';

class _MemorySession implements SessionStore {
  int? id;
  @override
  Future<void> clear() async => id = null;
  @override
  Future<int?> readUserId() async => id;
  @override
  Future<void> saveUserId(int value) async => id = value;
}

void _loadFont(String family, List<String> files) {
  final loader = FontLoader(family);
  for (final file in files) {
    final bytes = File('$_fontsDir/$file').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
  }
  loader.load();
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 60; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Widget não apareceu a tempo: $finder');
}

void main() {
  sqfliteFfiInit();

  testWidgets('captura telas de evidência', (tester) async {
    _loadFont('Roboto', ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf', 'roboto-black.ttf']);
    _loadFont('MaterialIcons', ['materialicons-regular.otf']);
    Directory(_outDir).createSync(recursive: true);

    tester.view
      ..physicalSize = const Size(1080, 2160)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final hasher = PasswordHasher(iterations: 100);
    late AppDatabase database;
    late AuthController controller;

    await tester.runAsync(() async {
      database = await AppDatabase.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
        hasher: hasher,
      );
      controller = AuthController(
        repository: SqliteAuthRepository(database, hasher),
        sessionStore: _MemorySession(),
      );
      await controller.restoreSession();
    });

    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MultiplagierApp(
          authController: controller,
          catalogRepository: SqliteCatalogRepository(database),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    Future<void> capture(String name) async {
      await tester.pump(const Duration(milliseconds: 700));
      await tester.runAsync(() async {
        final boundary = boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 3);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$_outDir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    // 1. Login vazio
    await capture('01-login');

    // 2. Login com credenciais inválidas
    await tester.enterText(find.byKey(const Key('login_email')), demoUserEmail);
    await tester.enterText(find.byKey(const Key('login_password')), 'senha-errada');
    await tester.tap(find.byKey(const Key('login_submit')));
    await _pumpUntilFound(tester, find.byKey(const Key('login_error')));
    await capture('02-login-erro');

    // 3. Catálogo após login válido
    await tester.enterText(find.byKey(const Key('login_password')), demoUserPassword);
    await tester.tap(find.byKey(const Key('login_submit')));
    await _pumpUntilFound(tester, find.byKey(const Key('catalog_list')));
    await capture('03-catalogo');

    // 4. Detalhe do produto
    await tester.tap(find.byKey(const Key('product_tile_1')));
    await tester.pump();
    await _pumpUntilFound(tester, find.byKey(const Key('detail_name')));
    await capture('04-detalhe');

    await tester.runAsync(() => database.close());
  });
}
