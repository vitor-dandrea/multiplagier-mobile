import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/app.dart';

void main() {
  testWidgets('app inicia exibindo a marca Multiplagier', (tester) async {
    await tester.pumpWidget(const MultiplagierApp());
    expect(find.text('Multiplagier'), findsOneWidget);
  });
}
