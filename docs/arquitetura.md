# Arquitetura

Visão geral da organização do código do **Multiplagier Mobile** (Flutter + SQLite local). A sincronização com API **não foi iniciada**; toda persistência é local.

## Camadas

```text
lib/
  main.dart            # bootstrap (factory SQLite por plataforma)
  app.dart             # MaterialApp e composição das telas
  core/                # tema, validação, formato, sessão e segurança
  data/
    db/                # AppDatabase, schema e seed
    models/            # User, Product, ShippingAddress, PaymentInfo, pedidos, carrinho
    repositories/      # contratos e implementações SQLite
  features/            # UI + controllers por funcionalidade
    auth/
    account/           # perfil (nome + endereço) e logout
    catalog/           # lista, detalhe e fotos offline
    cart/
    payment/           # checkout simulado (cartão / Pix)
    orders/
    home/
```

| Camada | Responsabilidade |
|--------|------------------|
| **features/** | Telas, navegação e `ChangeNotifier` (estado de UI) |
| **data/** | Modelos, schema SQLite, seed e repositórios |
| **core/** | Regras transversais: hash de senha, throttle de login, validação (incl. endereço), formatação, sessão |

As features dependem de repositórios (interfaces), não do `Database` diretamente. Controllers orquestram casos de uso e notificam a UI.

## Repositórios

| Repositório | Papel |
|-------------|-------|
| `AuthRepository` | Cadastro, autenticação, busca por id e `updateProfile` (nome + endereço; e-mail não muda) |
| `CatalogRepository` | Produtos ativos (lista e detalhe) |
| `CartRepository` | Itens do carrinho por `userId` |
| `OrderRepository` | Checkout com `PaymentInfo`, snapshot de entrega, listagem e detalhe isolados por usuário (SEC-001) |

Implementações atuais: `Sqlite*Repository`, usando `AppDatabase`.

## Estado (ChangeNotifier)

- `AuthController` — sessão, login, cadastro, `updateProfile` e logout.
- `CartController` — carrinho e `checkout(PaymentInfo)` (cria o pedido após pagamento simulado).

A UI escuta via `ListenableBuilder` / `AnimatedBuilder`. Não há sincronização remota: o estado reflete apenas o SQLite e a sessão em `SharedPreferences`.

## Persistência (SQLite)

- Arquivo: `multiplagier.db` (schema versionado em `AppDatabase`; versão atual **5**).
- Android: plugin nativo `sqflite`.
- Desktop / testes: `sqflite_common_ffi` (factory injetada no bootstrap).
- Tabelas principais: `users`, `products`, `cart_items`, `orders`, `order_items`, `security_events`.
- Evoluções relevantes:
  - **v4:** `orders.payment_method` e `orders.payment_last4` (sem PAN/CVV).
  - **v5:** endereço no perfil (`users.address_*`) e snapshot no pedido (`orders.shipping_*`).
- Fotos de produto: assets offline em `assets/products/` (`ProductImage`), não no banco.

## Diagrama

```mermaid
flowchart TB
  subgraph UI["features/"]
    AuthPages[Login / Cadastro]
    AccountPage[Conta]
    CatalogPages[Catálogo]
    CartPage[Carrinho]
    PaymentPage[Pagamento]
    OrdersPages[Pedidos]
  end

  subgraph State["ChangeNotifier"]
    AuthCtrl[AuthController]
    CartCtrl[CartController]
  end

  subgraph Data["data/repositories"]
    AuthRepo[AuthRepository]
    CatalogRepo[CatalogRepository]
    CartRepo[CartRepository]
    OrderRepo[OrderRepository]
  end

  subgraph Core["core/"]
    Hasher[PasswordHasher]
    Session[SessionStore]
    Throttle[LoginThrottle]
  end

  DB[(SQLite AppDatabase)]

  AuthPages --> AuthCtrl
  AccountPage --> AuthCtrl
  CartPage --> CartCtrl
  PaymentPage --> CartCtrl
  PaymentPage --> AuthCtrl
  OrdersPages --> OrderRepo
  CatalogPages --> CatalogRepo

  AuthCtrl --> AuthRepo
  AuthCtrl --> Session
  AuthCtrl --> Throttle
  CartCtrl --> CartRepo
  CartCtrl --> OrderRepo

  AuthRepo --> Hasher
  AuthRepo --> DB
  CatalogRepo --> DB
  CartRepo --> DB
  OrderRepo --> DB
  Session --> Prefs[(SharedPreferences)]
```

## Fluxo resumido

1. `main.dart` escolhe a factory SQLite, abre o banco, monta repositórios e restaura a sessão.
2. `AuthGate` decide entre login/cadastro e a home autenticada.
3. Catálogo, conta, carrinho, pagamento e pedidos leem/escrevem apenas dados do usuário logado.
4. Checkout: carrinho → `PaymentPage` (exige endereço completo) → `placeOrder` grava pagamento + snapshot de entrega → detalhe do pedido.
