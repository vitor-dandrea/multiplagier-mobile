# Segurança

Controles de segurança implementados no MVP **local** (SQLite). A sincronização com API **não foi iniciada**; as medidas abaixo protegem dados e fluxos no dispositivo.

## Hash de senha (PBKDF2)

- Classe: `PasswordHasher` (`lib/core/security/password_hasher.dart`).
- Algoritmo: **PBKDF2-HMAC-SHA256**, salt aleatório de 16 bytes por senha.
- Iterações padrão: **10 000**.
- Formato armazenado: `pbkdf2$<iterações>$<salt base64>$<hash base64>`.
- A senha em texto claro **nunca** é persistida nem logada.
- Comparação com tempo constante (`_constantTimeEquals`).

## Sessão: apenas o id

`SessionStore` / `PrefsSessionStore` gravam em `SharedPreferences` **somente** `session_user_id` (inteiro).

Não são armazenados e-mail, senha nem hash na sessão. No logout o id é removido; na restauração o usuário é recarregado do SQLite pelo id.

## SEC-001 — Isolamento de pedidos

- Listagem e detalhe filtram por `userId` do cliente autenticado.
- Em `OrderRepository.findForUser`: se o pedido existir mas pertencer a outro usuário, o acesso é **negado** (retorno `null`, mesmo comportamento de “não encontrado”).
- Tentativas de acesso indevido são registradas em `security_events` (`event_type` de acesso negado, ator, tipo/id do recurso).
- Falha ao gravar auditoria **não** libera o pedido.

Na UI, pedido inexistente e pedido de outro usuário produzem o mesmo estado, sem vazar dados.

## SEC-003 — Limite de tentativas de login

`LoginThrottle`:

| Parâmetro | Valor |
|-----------|-------|
| Tentativas máximas | **5** falhas por e-mail |
| Bloqueio | **1 minuto** |
| Escopo | Em memória (enquanto o app estiver aberto) |

Após o bloqueio, a UI exibe mensagem de muitas tentativas. Sucesso limpa o contador daquele e-mail.

## Regras de senha

Definidas em `InputRules` (UI e repositório usam as mesmas funções):

- Mínimo **8** e máximo **128** caracteres.
- Deve conter **letras** e **números**.
- Validação também no `AuthRepository.register` (não basta ocultar o botão na UI).

## Erros genéricos de login

- `authenticate` **não** distingue “e-mail inexistente” de “senha incorreta” (retorna `null` nos dois casos).
- Quando o e-mail não existe, ainda assim roda verificação contra um hash dummy, para aproximar o custo da resposta.
- Mensagem ao usuário: **"E-mail ou senha inválidos."** (`AuthController.invalidCredentialsMessage`).

Isso reduz enumeração de contas válidas pela interface.

## Checkout e perfil

Pagamento e endereço **não** alteram PBKDF2 / SEC-001 / SEC-003; acrescentam estas regras:

| Tema | Comportamento |
|------|----------------|
| Pagamento simulado | Formulário de cartão/Pix é só UX offline; **não** há gateway |
| Dados de cartão | PAN e CVV **não** são persistidos; no pedido grava-se `payment_method` e, se cartão, só `payment_last4` |
| Endereço no pedido | Snapshot `shipping_*` no `placeOrder` — histórico não muda se o perfil for editado depois |
| Perfil | E-mail **somente leitura** nesta entrega; nome e endereço editáveis via `updateProfile` |
| Validação de endereço | Regras locais (CEP 8 dígitos, UF 2 letras, campos obrigatórios); sem ViaCEP/rede |

Checkout exige endereço completo no usuário; incompleto bloqueia a UI e falha tipada no repositório (`PlaceOrderFailure.missingAddress`).

## Outros pontos

| Tema | Comportamento |
|------|----------------|
| Papel no cadastro | Sempre `customer`; o cliente não escolhe papel |
| Carrinho / pedidos | Sempre escopados por `userId` |
| API remota | Não iniciada — sem tokens HTTP nem sync ainda |

## Referência rápida de código

| Controle | Local |
|----------|-------|
| PBKDF2 | `lib/core/security/password_hasher.dart` |
| Sessão (id) | `lib/core/session/session_store.dart` |
| SEC-001 + `security_events` | `lib/data/repositories/order_repository.dart`, schema em `app_database.dart` |
| SEC-003 | `lib/core/security/login_throttle.dart` |
| Regras de senha | `lib/core/validation/input_rules.dart` |
| Endereço | `lib/core/validation/address_rules.dart` |
| Pagamento (persistência) | `lib/data/models/payment_info.dart`, `order_repository.dart` |
| Mensagens genéricas | `lib/features/auth/auth_controller.dart` |
