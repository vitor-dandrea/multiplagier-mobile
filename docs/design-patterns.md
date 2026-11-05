# Padrões de projeto

Padrões usados de forma deliberada no **Multiplagier Mobile**, alinhados ao escopo local (sem API).

## Repository

Cada domínio expõe um contrato (`AuthRepository`, `CatalogRepository`, `CartRepository`, `OrderRepository`) e uma implementação SQLite.

- A UI e os controllers dependem da abstração.
- Facilita testes com fakes (`test/support/`).
- Quando a sincronização com API existir, a troca de implementação fica isolada nesta camada.

## Observer / ChangeNotifier

`AuthController` e `CartController` estendem `ChangeNotifier`:

- Mantêm estado observável (`status`, `user`, linhas do carrinho, mensagens de erro).
- Após mutações (login, add ao carrinho, checkout), chamam `notifyListeners()`.
- As telas reagem sem acoplamento direto ao repositório.

É o padrão Observer adaptado ao Flutter (`Listenable`).

## Factory (banco de dados)

`AppDatabase.open` concentra a criação do banco:

- Aceita `DatabaseFactory` (nativa no Android; FFI no desktop/testes).
- Aceita caminho (`path`) e `PasswordHasher` injetáveis.
- No `main.dart`, a plataforma decide se usa `databaseFactoryFfi` antes de abrir o banco.

Isso evita espalhar detalhes de plataforma pelas features.

## Tipos de resultado (`RegistrationOutcome` e afins)

Falhas esperadas de negócio não são exceções:

| Tipo | Uso |
|------|-----|
| `RegistrationOutcome` / `RegistrationFailure` | Cadastro: nome inválido, e-mail inválido, senha fraca, e-mail já usado |
| `PlaceOrderOutcome` | Checkout: carrinho vazio, estoque insuficiente, sucesso |

A UI mapeia o resultado para mensagens; erros inesperados (I/O) continuam como exceção e viram mensagem genérica.

## LoginThrottle

Objeto de domínio em `core/security/login_throttle.dart` (SEC-003):

- Conta falhas por e-mail (normalizado).
- Após **5** tentativas inválidas, bloqueia por **1 minuto** (estado em memória enquanto o app estiver aberto).
- Sucesso limpa o contador daquele e-mail.

Usado pelo `AuthController` antes/depois de `authenticate`.

## Filtro de catálogo

`filterCatalog` e `catalogCategories` em `features/catalog/catalog_filter.dart` (US-009):

- Funções puras sobre `List<Product>`.
- Filtro por texto (nome/descrição) e categoria.
- Sem I/O: fáceis de testar unitariamente (`catalog_filter_test.dart`).

## Resumo

| Padrão | Onde aparece |
|--------|--------------|
| Repository | `lib/data/repositories/` |
| Observer | `AuthController`, `CartController` |
| Factory | `AppDatabase.open` + bootstrap em `main.dart` |
| Result / Outcome | `RegistrationOutcome`, `PlaceOrderOutcome` |
| Throttle | `LoginThrottle` |
| Filtro puro | `filterCatalog` |
