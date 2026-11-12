import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/core/session/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late PrefsSessionStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = PrefsSessionStore(await SharedPreferences.getInstance());
  });

  test('começa sem sessão', () async {
    expect(await store.readUserId(), isNull);
  });

  test('salva e lê o id do usuário', () async {
    await store.saveUserId(7);
    expect(await store.readUserId(), 7);
  });

  test('clear remove a sessão', () async {
    await store.saveUserId(7);
    await store.clear();
    expect(await store.readUserId(), isNull);
  });
}
