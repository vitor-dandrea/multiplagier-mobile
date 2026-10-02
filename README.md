# Multiplagier Mobile

Versão mobile (Flutter) do **Multiplagier**, e-commerce acadêmico de eletrônicos e acessórios da disciplina **ISG022 — Segurança no Desenvolvimento de Aplicações** (FATEC Mauá, 2026/2).

O web (Laravel) fica em [vitor-dandrea/multiplagier](https://github.com/vitor-dandrea/multiplagier) e serve apenas como referência de domínio: perfis, backlog e critérios de aceite.

## Status

MVP em construção. Escopo atual:

| Funcionalidade | Status |
|----------------|--------|
| Configuração inicial (Flutter + SQLite + seed) | Concluído |
| Login local (login, logout, restauração de sessão) | Concluído |
| Catálogo (lista e detalhe de produtos ativos) | Concluído |
| Cadastro, carrinho, pedidos, sincronização com API | Não iniciado |

## Stack

- Flutter / Dart
- SQLite local: `sqflite` (Android) e `sqflite_common_ffi` (desktop e testes)
- `crypto` para hash de senha (PBKDF2-HMAC-SHA256 com salt)
- `shared_preferences` para a sessão

## Como executar

Pré-requisito: [Flutter SDK](https://docs.flutter.dev/get-started/install) estável, em um caminho **sem espaços** (o build nativo do `sqlite3` falha com espaços no caminho do SDK).

```bash
flutter pub get
flutter run            # dispositivo/emulador Android ou Windows
flutter test           # testes unitários e de widget
flutter analyze
```

No Windows, o suporte a plugins exige o **Modo de Desenvolvedor** ativo (`start ms-settings:developers`).

## Usuário de demonstração

O banco é criado e populado na primeira execução.

| Campo | Valor |
|-------|-------|
| E-mail | `cliente@multiplagier.local` |
| Senha | `Multiplagier@2026` |

São semeados 5 produtos ativos e 1 inativo (usado para provar o filtro do catálogo).

## Arquitetura

```text
lib/
  main.dart            # bootstrap (factory SQLite por plataforma)
  app.dart             # MaterialApp
  core/                # tema e segurança (hash de senha)
  data/db/             # AppDatabase, schema e seed
  features/            # auth e catalog (por funcionalidade)
```

## Relatório de status e evidências

- Relatório em Word: `docs/Relatorio_Status_Multiplagier_Mobile.docx` (gerado por `docs/gerar-relatorio-status.mjs`; use `cd docs && npm install && npm run relatorio`).
- Capturas de tela em `docs/evidencias/`, geradas por `flutter test tool/screenshots/capture_screens_test.dart` (renderização do app via teste de widget, não é print de emulador).

## Fluxo de Git

- `main`: branch estável, **não recebe commits de trabalho nesta fase**.
- `dev`: integração; todo o desenvolvimento entra aqui.
- Branches de trabalho (`feat/`, `fix/`, `imp/`, `chore/`, `refac/`, `docs/`) são criadas a partir de `dev` e voltam apenas para `dev`.
- Commits atômicos, uma preocupação por commit.
