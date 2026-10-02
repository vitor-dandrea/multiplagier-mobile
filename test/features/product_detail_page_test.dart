import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/data/models/product.dart';
import 'package:multiplagier_mobile/data/repositories/catalog_repository.dart';
import 'package:multiplagier_mobile/features/catalog/product_detail_page.dart';

import '../support/fake_catalog.dart';

class _FailingRepository extends FakeCatalogRepository {
  @override
  Future<Product?> findActiveById(int id) =>
      throw StateError('detalhe interno sensível');
}

void main() {
  Future<void> pumpDetail(
    WidgetTester tester,
    CatalogRepository repository,
    int id,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailPage(repository: repository, productId: id),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('exibe nome, descrição, preço e disponibilidade', (tester) async {
    await pumpDetail(tester, FakeCatalogRepository(), 1);

    expect(find.text('Fone Bluetooth'), findsOneWidget);
    expect(find.text('R\$ 189,90'), findsOneWidget);
    expect(find.text('Em estoque'), findsOneWidget);
    expect(
      find.text('Headphone sem fio com 30 horas de bateria.'),
      findsOneWidget,
    );
  });

  testWidgets('produto sem estoque aparece como indisponível', (tester) async {
    await pumpDetail(tester, FakeCatalogRepository(), 2);

    expect(find.text('Indisponível'), findsOneWidget);
  });

  testWidgets('produto inexistente mostra "não encontrado"', (tester) async {
    await pumpDetail(tester, FakeCatalogRepository(), 999);

    expect(find.byKey(const Key('detail_not_found')), findsOneWidget);
    expect(find.text(ProductDetailPage.notFoundMessage), findsOneWidget);
  });

  testWidgets('produto inativo é tratado como não encontrado', (tester) async {
    final repository = FakeCatalogRepository(products: const [
      Product(
        id: 5,
        name: 'Oculto',
        description: 'x',
        priceCents: 100,
        stock: 1,
        isActive: false,
      ),
    ]);

    await pumpDetail(tester, repository, 5);

    expect(find.byKey(const Key('detail_not_found')), findsOneWidget);
    expect(find.text('Oculto'), findsNothing);
  });

  testWidgets('erro mostra mensagem genérica sem vazar detalhes',
      (tester) async {
    await pumpDetail(tester, _FailingRepository(), 1);

    expect(find.byKey(const Key('detail_error')), findsOneWidget);
    expect(find.textContaining('sensível'), findsNothing);
  });
}
