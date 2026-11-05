import 'package:flutter/material.dart';

import '../../core/format/date_time_br.dart';
import '../../core/format/money.dart';
import '../../data/models/customer_order.dart';
import '../../data/repositories/order_repository.dart';
import 'order_detail_page.dart';

/// Lista somente os pedidos do usuário autenticado (US-007).
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, required this.repository, required this.userId});

  static const emptyMessage = 'Você ainda não fez pedidos.';
  static const errorMessage = 'Não foi possível carregar os pedidos.';

  final OrderRepository repository;
  final int userId;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<OrderSummary>> _future = _load();

  Future<List<OrderSummary>> _load() async =>
      widget.repository.listForUser(widget.userId);

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _refresh() async {
    _reload();
    try {
      await _future;
    } catch (_) {
      // O erro é exibido pelo FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      body: FutureBuilder<List<OrderSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _OrdersMessage(
              key: const Key('orders_error'),
              icon: Icons.error_outline,
              message: OrdersPage.errorMessage,
              actionLabel: 'Tentar novamente',
              onAction: _reload,
            );
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const _OrdersMessage(
              key: Key('orders_empty'),
              icon: Icons.receipt_long_outlined,
              message: OrdersPage.emptyMessage,
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              key: const Key('orders_list'),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final order = orders[index];
                return ListTile(
                  key: Key('order_tile_${order.id}'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  title: Text('Pedido #${order.id}'),
                  subtitle: Text(
                    '${formatDateTimeBr(order.createdAt)} · ${order.statusLabel}',
                  ),
                  trailing: Text(
                    formatBrl(order.totalCents),
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OrderDetailPage(
                          repository: widget.repository,
                          userId: widget.userId,
                          orderId: order.id,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _OrdersMessage extends StatelessWidget {
  const _OrdersMessage({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                key: const Key('orders_retry'),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
