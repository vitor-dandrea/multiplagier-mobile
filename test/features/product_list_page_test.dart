import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiplagier_mobile/data/models/product.dart';
import 'package:multiplagier_mobile/features/catalog/product_list_page.dart';

import '../support/fake_catalog.dart';

void main() {
  Future<void> pumpList(
    WidgetTester tester,
    FakeCatalogRepository repository, {
    ValueChanged<Product>? onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductListPage(
            repository: repository,
            onProductTap: onTap ?? (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('exibe nome, preço e disponibilidade dos produtos',
      (tester) async {
    await pumpList(tester, FakeCatalogRepository());

    expect(find.text('Fone Bluetooth'), findsOneWidget);
    expect(find.text('R\$ 189,90'), findsOneWidget);
    expect(find.textContaining('Em estoque'), findsOneWidget);
    expect(find.text('Tablet 10"'), findsOneWidget);
    expect(find.textContaining('Indisponível'), findsOneWidget);
    expect(find.byKey(const Key('catalog_search')), findsOneWidget);
    expect(find.byKey(const Key('catalog_category_Áudio')), findsOneWidget);
  });

  testWidgets('busca e categoria restringem a lista', (tester) async {
    await pumpList(tester, FakeCatalogRepository());

    await tester.enterText(find.byKey(const Key('catalog_search')), 'tablet');
    await tester.pump();

    expect(find.text('Tablet 10"'), findsOneWidget);
    expect(find.text('Fone Bluetooth'), findsNothing);

    await tester.tap(find.byKey(const Key('catalog_search_clear')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('catalog_category_Áudio')));
    await tester.pump();

    expect(find.text('Fone Bluetooth'), findsOneWidget);
    expect(find.text('Tablet 10"'), findsNothing);

    await tester.enterText(find.byKey(const Key('catalog_search')), 'xyz');
    await tester.pump();
    expect(find.byKey(const Key('catalog_no_match')), findsOneWidget);
    expect(find.text(ProductListPage.noMatchMessage), findsOneWidget);
  });

  testWidgets('não exibe produtos inativos', (tester) async {
    final repository = FakeCatalogRepository(products: [
      ...sampleProducts,
      const Product(
        id: 9,
        name: 'Produto Oculto',
        description: 'x',
        category: 'Outros',
        priceCents: 100,
        stock: 1,
        isActive: false,
      ),
    ]);

    await pumpList(tester, repository);

    expect(find.text('Produto Oculto'), findsNothing);
    expect(find.byKey(const Key('product_tile_9')), findsNothing);
  });

  testWidgets('catálogo vazio mostra estado compreensível', (tester) async {
    await pumpList(tester, FakeCatalogRepository(products: const []));

    expect(find.byKey(const Key('catalog_empty')), findsOneWidget);
    expect(find.text(ProductListPage.emptyMessage), findsOneWidget);
  });

  testWidgets('erro mostra mensagem genérica sem vazar detalhes e permite retry',
      (tester) async {
    final repository = FakeCatalogRepository(failTimes: 1);
    await pumpList(tester, repository);

    expect(find.byKey(const Key('catalog_error')), findsOneWidget);
    expect(find.text(ProductListPage.errorMessage), findsOneWidget);
    expect(find.textContaining('sensíveis'), findsNothing);

    await tester.tap(find.byKey(const Key('catalog_retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('catalog_error')), findsNothing);
    expect(find.text('Fone Bluetooth'), findsOneWidget);
    expect(repository.listCalls, 2);
  });

  testWidgets('tocar em um produto dispara onProductTap', (tester) async {
    Product? tapped;
    await pumpList(tester, FakeCatalogRepository(), onTap: (p) => tapped = p);

    await tester.tap(find.byKey(const Key('product_tile_2')));

    expect(tapped?.id, 2);
  });
}
