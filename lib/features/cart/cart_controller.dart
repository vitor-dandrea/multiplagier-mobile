import 'package:flutter/foundation.dart';

import '../../data/models/cart_line.dart';
import '../../data/models/payment_info.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/repositories/order_repository.dart';

/// Carrinho do usuário autenticado e fechamento do pedido (US-006).
class CartController extends ChangeNotifier {
  CartController({
    required this._cartRepository,
    required this._orderRepository,
    required this.userId,
  });

  static const unavailableMessage = 'Produto indisponível.';
  static const exceedsStockMessage =
      'Quantidade maior que o estoque disponível.';
  static const invalidQuantityMessage = 'Informe uma quantidade válida.';
  static const emptyCartMessage = 'Seu carrinho está vazio.';
  static const unavailableCheckoutMessage =
      'Um ou mais itens não estão mais disponíveis.';
  static const missingAddressMessage =
      'Cadastre um endereço completo na sua conta para finalizar.';
  static const loadErrorMessage = 'Não foi possível carregar o carrinho.';
  static const unexpectedMessage =
      'Não foi possível concluir a operação. Tente novamente.';

  final CartRepository _cartRepository;
  final OrderRepository _orderRepository;
  final int userId;

  List<CartLine> lines = const [];
  bool loading = true;
  bool busy = false;
  String? errorMessage;
  bool _disposed = false;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  int get totalCents => lines.fold(0, (sum, line) => sum + line.lineTotalCents);

  Future<void> load() async {
    try {
      final items = await _cartRepository.listForUser(userId);
      if (!_disposed) {
        lines = items;
        errorMessage = null;
      }
    } catch (_) {
      if (!_disposed) {
        lines = const [];
        errorMessage = loadErrorMessage;
      }
    }
    if (_disposed) return;
    loading = false;
    notifyListeners();
  }

  /// `true` quando o item entrou no carrinho.
  Future<bool> add(int productId, {int quantity = 1}) {
    return _mutate(
      () => _cartRepository.add(userId, productId, quantity: quantity),
    );
  }

  Future<bool> setQuantity(int productId, int quantity) {
    return _mutate(
      () => _cartRepository.setQuantity(userId, productId, quantity),
    );
  }

  Future<bool> remove(int productId) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _cartRepository.remove(userId, productId);
      if (_disposed) return true;
      lines = await _cartRepository.listForUser(userId);
      return true;
    } catch (_) {
      if (!_disposed) errorMessage = unexpectedMessage;
      return false;
    } finally {
      _finishBusy();
    }
  }

  /// Id do pedido criado, ou `null` se a compra não foi concluída.
  Future<int?> checkout(PaymentInfo payment) async {
    if (lines.isEmpty) {
      errorMessage = emptyCartMessage;
      notifyListeners();
      return null;
    }

    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final outcome = await _orderRepository.placeOrder(userId, payment);
      final order = outcome.order;
      if (order == null) {
        if (!_disposed) {
          errorMessage = _checkoutMessage(outcome.failure);
        }
        return null;
      }
      if (!_disposed) {
        lines = await _cartRepository.listForUser(userId);
      }
      return order.id;
    } catch (_) {
      if (!_disposed) errorMessage = unexpectedMessage;
      return null;
    } finally {
      _finishBusy();
    }
  }

  Future<bool> _mutate(Future<CartChange> Function() action) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final change = await action();
      if (!change.isOk) {
        if (!_disposed) errorMessage = _cartMessage(change.failure);
        return false;
      }
      if (!_disposed) {
        lines = await _cartRepository.listForUser(userId);
      }
      return true;
    } catch (_) {
      if (!_disposed) errorMessage = unexpectedMessage;
      return false;
    } finally {
      _finishBusy();
    }
  }

  void _finishBusy() {
    if (_disposed) return;
    busy = false;
    notifyListeners();
  }

  String _cartMessage(CartFailure? failure) {
    switch (failure) {
      case CartFailure.unavailable:
        return unavailableMessage;
      case CartFailure.exceedsStock:
        return exceedsStockMessage;
      case CartFailure.invalidQuantity:
        return invalidQuantityMessage;
      case null:
        return unexpectedMessage;
    }
  }

  String _checkoutMessage(PlaceOrderFailure? failure) {
    switch (failure) {
      case PlaceOrderFailure.emptyCart:
        return emptyCartMessage;
      case PlaceOrderFailure.unavailable:
        return unavailableCheckoutMessage;
      case PlaceOrderFailure.missingAddress:
        return missingAddressMessage;
      case null:
        return unexpectedMessage;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
