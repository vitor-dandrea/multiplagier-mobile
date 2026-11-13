import 'package:flutter/material.dart';

import '../../core/format/date_time_br.dart';
import '../../core/format/money.dart';
import '../../data/models/customer_order.dart';
import '../../data/repositories/order_repository.dart';

/// Detalhe de um pedido do usuário logado. Id de outra pessoa ou
/// inexistente produz o mesmo estado, sem dados do pedido (SEC-001).
class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.repository,
    required this.userId,
    required this.orderId,
  });

  static const notFoundMessage = 'Pedido não encontrado.';
  static const errorMessage = 'Não foi possível carregar o pedido.';

  final OrderRepository repository;
  final int userId;
  final int orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late final Future<OrderDetail?> _future = _load();

  Future<OrderDetail?> _load() async =>
      widget.repository.findForUser(widget.userId, widget.orderId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedido')),
      body: FutureBuilder<OrderDetail?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _OrderMessage(
              key: Key('order_error'),
              text: OrderDetailPage.errorMessage,
            );
          }
          final order = snapshot.data;
          if (order == null) {
            return const _OrderMessage(
              key: Key('order_not_found'),
              text: OrderDetailPage.notFoundMessage,
            );
          }
          return _OrderBody(order: order);
        },
      ),
    );
  }
}

class _OrderBody extends StatelessWidget {
  const _OrderBody({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Pedido #${order.id}',
          key: const Key('order_id'),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(formatDateTimeBr(order.createdAt), key: const Key('order_date')),
        const SizedBox(height: 8),
        Text(
          order.statusLabel,
          key: const Key('order_status'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.tertiary,
          ),
        ),
        if (order.paymentLabel != null) ...[
          const SizedBox(height: 8),
          Text(
            'Pagamento: ${order.paymentLabel}',
            key: const Key('order_payment'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (order.shippingAddress != null) ...[
          const SizedBox(height: 16),
          Text('Entrega', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final line in order.shippingAddress!.formattedLines)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                line,
                key: line == order.shippingAddress!.formattedLines.first
                    ? const Key('order_shipping')
                    : null,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
        const SizedBox(height: 24),
        Text('Itens', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final item in order.items) ...[
          ListTile(
            key: Key('order_item_${item.productId}'),
            contentPadding: EdgeInsets.zero,
            title: Text(item.productName),
            subtitle: Text(
              '${item.quantity} × ${formatBrl(item.unitPriceCents)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Text(
              formatBrl(item.lineTotalCents),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1),
        ],
        const SizedBox(height: 16),
        Text(
          'Total: ${formatBrl(order.totalCents)}',
          key: const Key('order_total'),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _OrderMessage extends StatelessWidget {
  const _OrderMessage({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
