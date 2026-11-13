import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/format/money.dart';
import '../../data/models/cart_line.dart';
import '../../data/repositories/order_repository.dart';
import '../auth/auth_controller.dart';
import '../payment/payment_page.dart';
import 'cart_controller.dart';

class CartPage extends StatelessWidget {
  const CartPage({
    super.key,
    required this.controller,
    required this.orderRepository,
    required this.authController,
    required this.onOrderPlaced,
  });

  final CartController controller;
  final OrderRepository orderRepository;
  final AuthController authController;
  final VoidCallback onOrderPlaced;

  Future<void> _checkout(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaymentPage(
          controller: controller,
          orderRepository: orderRepository,
          authController: authController,
          onOrderPlaced: onOrderPlaced,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carrinho')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.loading && controller.lines.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.lines.isEmpty && controller.errorMessage != null) {
            return _CartMessage(
              key: const Key('cart_error'),
              icon: Icons.error_outline,
              message: controller.errorMessage!,
              actionLabel: 'Tentar novamente',
              onAction: controller.load,
            );
          }
          if (controller.lines.isEmpty) {
            return const _CartMessage(
              key: Key('cart_empty'),
              icon: Icons.shopping_cart_outlined,
              message: CartController.emptyCartMessage,
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  key: const Key('cart_list'),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: controller.lines.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _CartTile(
                    line: controller.lines[index],
                    enabled: !controller.busy,
                    onDecrease: () {
                      final line = controller.lines[index];
                      if (line.quantity <= 1) {
                        controller.remove(line.productId);
                      } else {
                        controller.setQuantity(
                          line.productId,
                          line.quantity - 1,
                        );
                      }
                    },
                    onIncrease: () {
                      final line = controller.lines[index];
                      controller.setQuantity(line.productId, line.quantity + 1);
                    },
                  ),
                ),
              ),
              _CheckoutBar(
                totalCents: controller.totalCents,
                errorMessage: controller.errorMessage,
                busy: controller.busy,
                onCheckout: () => _checkout(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({
    required this.line,
    required this.enabled,
    required this.onDecrease,
    required this.onIncrease,
  });

  final CartLine line;
  final bool enabled;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final warning = !line.canCheckout;

    return Material(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(line.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              formatBrl(line.unitPriceCents),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (warning)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  line.isActive ? 'Estoque insuficiente' : 'Indisponível',
                  style: TextStyle(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                IconButton(
                  key: Key('cart_dec_${line.productId}'),
                  tooltip: line.quantity <= 1 ? 'Remover' : 'Diminuir',
                  onPressed: enabled ? onDecrease : null,
                  icon: Icon(
                    line.quantity <= 1 ? Icons.delete_outline : Icons.remove,
                  ),
                ),
                Text(
                  '${line.quantity}',
                  key: Key('cart_qty_${line.productId}'),
                  style: theme.textTheme.titleMedium,
                ),
                IconButton(
                  key: Key('cart_inc_${line.productId}'),
                  tooltip: 'Aumentar',
                  onPressed: enabled ? onIncrease : null,
                  icon: const Icon(Icons.add),
                ),
                const Spacer(),
                Text(
                  formatBrl(line.lineTotalCents),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.totalCents,
    required this.errorMessage,
    required this.busy,
    required this.onCheckout,
  });

  final int totalCents;
  final String? errorMessage;
  final bool busy;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: AppColors.surfaceContainer,
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Total: ${formatBrl(totalCents)}',
                key: const Key('cart_total'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  key: const Key('cart_error'),
                  style: TextStyle(color: scheme.error),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('cart_checkout'),
                onPressed: busy ? null : onCheckout,
                child: busy
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : const Text('Finalizar pedido'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartMessage extends StatelessWidget {
  const _CartMessage({
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
                key: const Key('cart_retry'),
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
