---
name: multiplagier-qa-adb
description: >-
  Runs step-by-step ADB UI QA for Multiplagier Mobile on the Android emulator
  (login success, conta/endereço, carrinho, pagamento, pedidos, logout). Use when
  the user asks for QA no emulador, teste ADB, smoke manual, etapa login/conta/
  carrinho/pagamento, or MCP/emulator screen walkthrough for this project only.
  Does not run SEC-003 lockout or the 1-minute wait.
---

# Multiplagier QA ADB (por etapa)

Projeto-only. Prefer **uma etapa por vez**. Não rode e2e longo nem SEC-003.

## Setup (antes da 1ª etapa)

1. Emulador `Pixel_6_API_35` online (`adb devices` → `device`).
2. Posicione a janela do emulador no **centro-direita** da tela do notebook.
3. APK debug instalado (reuse build existente se houver):

```powershell
$env:Path = "C:\Android\Sdk\platform-tools;C:\flutter\bin;" + $env:Path
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

4. Confirme foco no app (`mCurrentFocus` contém `multiplagier_mobile`) antes de digitar.

## Como executar

Rode o script da skill (cwd = raiz do repo):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".cursor\skills\multiplagier-qa-adb\scripts\qa_step.ps1" -Step <nome>
```

Steps válidos: `setup` | `login` | `conta` | `carrinho` | `pagamento` | `logout`

Ordem sugerida: `setup` → `login` → `conta` → `carrinho` → `pagamento` → `logout`.

Após cada step: reporte OK/FAIL + caminho do PNG. Pare se falhar; não encadeie o resto sem o usuário pedir.

## Credenciais (login bem-sucedido apenas)

| Campo | Valor |
|-------|-------|
| E-mail | `cliente@multiplagier.local` |
| Senha | `Multiplagier@2026` |

**Proibido nesta skill:** 5+ logins errados, throttle SEC-003, `Start-Sleep` de ~60s.

## Prints

Salvar em `%USERPROFILE%\Desktop\multiplagier-e2e-mcp\`.

## Pacote

`br.edu.fatec.multiplagier.multiplagier_mobile` / `.MainActivity`

## Semântica útil (content-desc)

`Entrar`, `Criar conta`, `Minha conta`, `Pedidos`, `Carrinho` (com item vira o número do badge, ex. `1`), `Salvar`, `Sair`, `Adicionar`, `Finalizar`, `Pix`, `Confirmar`, filtros `Áudio`/`udio`.

## Falhas comuns

- Digitar na busca do Google → `am start -W` de novo e esperar `Entrar`.
- Emulador `offline` / sumiu no install → religar AVD, **não** rebuildar se o APK já existe.
- Step assume tela prévia: `conta`/`carrinho` precisam login; `pagamento` precisa item no carrinho.
