# Guia de teste manual de interface — Multiplagier Mobile

Documento **offline** para executar o teste de UI você mesmo (emulador, celular USB ou Wi‑Fi).  
Não depende de internet na hora do teste (desde que Flutter, SDK e o projeto já estejam no PC).

**Data de referência:** 11/11/2026  
**App:** Flutter + SQLite local (sem API)  
**Pacote Android:** `br.edu.fatec.multiplagier.multiplagier_mobile`

---

## 1. O que este guia cobre

| Canal | Quando usar |
|-------|-------------|
| Emulador `Pixel_6_API_35` | Teste no PC sem aparelho |
| Celular por **USB** | Mais estável que Wi‑Fi |
| Celular por **Wi‑Fi (ADB wireless)** | Sem cabo, mesma rede |

**Importante:** digite e-mail/senha **na tela do app** (teclado do emulador/celular).  
**Não** use `adb shell input text` para credenciais — isso já falhou (texto foi para outro campo / busca do sistema).

---

## 2. Onde executar os comandos

1. Abra o **PowerShell** (Windows Terminal ou terminal do Cursor).
2. Vá para a pasta do projeto:

```powershell
cd "C:\Users\Vitor Aletto\Desktop\multiplagier-mobile"
```

3. Em **toda** sessão nova, carregue o ambiente (copie e cole):

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:ANDROID_HOME = "C:\Android\Sdk"
$env:ANDROID_SDK_ROOT = "C:\Android\Sdk"
$env:Path = "$env:JAVA_HOME\bin;C:\Android\Sdk\platform-tools;C:\Android\Sdk\emulator;C:\flutter\bin;" + $env:Path
```

4. Confira:

```powershell
java -version
adb version
flutter --version
```

Se `adb` ou `java` falharem, o bloco do passo 3 não foi aplicado nesta janela — rode de novo e **não feche** o terminal.

### Caminhos fixos deste PC

| Ferramenta | Caminho |
|------------|---------|
| Flutter | `C:\flutter` |
| Android SDK | `C:\Android\Sdk` |
| `adb` | `C:\Android\Sdk\platform-tools\adb.exe` |
| Emulador | `C:\Android\Sdk\emulator\emulator.exe` |
| JAVA_HOME (JBR do Android Studio) | `C:\Program Files\Android\Android Studio\jbr` |
| Projeto | `C:\Users\Vitor Aletto\Desktop\multiplagier-mobile` |
| AVD | `Pixel_6_API_35` |

---

## 3. Credenciais e dados de teste

### Conta demo (seed na 1ª abertura do banco)

| Campo | Valor |
|-------|-------|
| E-mail | `cliente@multiplagier.local` |
| Senha | `Multiplagier@2026` |
| Nome exibido | Cliente Demo |
| Endereço (seed) | Rua das Flores, 100 — Centro — Mauá/SP — CEP 09310-000 |

### Conta nova (cadastro — invente um e-mail único)

| Campo | Exemplo válido |
|-------|----------------|
| Nome | `Ana Silva` |
| E-mail | `ana.silva.teste@multiplagier.local` |
| Senha | `SenhaForte1` |
| Confirmar senha | `SenhaForte1` |

**Regras de senha:** mínimo 8 caracteres, com **letra** e **número** (máx. 128).

### Produtos do seed (catálogo)

Devem aparecer (ativos):

| Produto | Categoria | Preço | Estoque |
|---------|-----------|-------|---------|
| Smart TV 50" 4K | TVs | R$ 2.499,00 | 12 |
| Fone de Ouvido Bluetooth | Áudio | R$ 189,90 | 40 |
| Tablet 10" 64GB | Tablets | R$ 899,00 | 0 (sem estoque) |
| Caixa de Som Portátil | Áudio | R$ 159,90 | 25 |
| Mouse Gamer RGB | Periféricos | R$ 129,90 | 30 |

**Não** deve aparecer: `Produto Descontinuado` (inativo).

### Mensagens esperadas

| Situação | Mensagem / efeito |
|----------|-------------------|
| Login errado | `E-mail ou senha inválidos.` |
| SEC-003 (após 5 falhas no **mesmo** e-mail) | `Muitas tentativas. Aguarde 1 minuto e tente novamente.` |
| E-mail já cadastrado | `Este e-mail já está cadastrado.` |
| Senha fraca | `A senha deve ter pelo menos 8 caracteres, com letras e números.` |
| Senhas diferentes | `As senhas não coincidem.` |
| Pedido de outro usuário / id inválido | UI de “não encontrado” (sem dados do pedido) |

**SEC-003:** o bloqueio fica **só na memória**. Se fechar o app / `force-stop` / limpar dados, o contador zera.

---

## 4. Preparar o dispositivo

Escolha **uma** opção (A, B ou C). Depois vá à seção 5.

### A) Emulador Android

```powershell
# Listar AVDs
flutter emulators

# Subir o AVD validado
flutter emulators --launch Pixel_6_API_35
```

Alternativa:

```powershell
emulator -avd Pixel_6_API_35
```

Espere o emulador carregar a home. Depois:

```powershell
adb devices
```

Deve aparecer algo como:

```text
emulator-5554    device
```

**Dica de janela:** arraste o emulador para a **direita** da tela (centro-direita) para ver o app enquanto usa o PC.

### B) Celular por cabo USB

No celular:

1. **Configurações → Sobre o telefone** → toque 7× em “Número da versão” (ativa Opções do desenvolvedor).
2. **Opções do desenvolvedor** → ative **Depuração USB**.
3. Conecte o cabo USB ao PC.
4. Aceite “Permitir depuração USB” no celular.

No PC:

```powershell
adb devices
```

Deve listar o aparelho com `device` (não `unauthorized`).  
Se estiver `unauthorized`, desbloqueie a tela, aceite o diálogo e rode `adb devices` de novo.

### C) Celular por Wi‑Fi (ADB wireless)

Pré-requisitos: celular e PC na **mesma rede Wi‑Fi**; Depuração USB já usada pelo menos uma vez (ou Depuração sem fio disponível).

#### C.1 — Parear (só na 1ª vez / quando o código mudar)

No celular: **Opções do desenvolvedor → Depuração sem fio** → **Parear dispositivo com código de pareamento**.  
Anote **IP:porta de pareamento** e o **código de 6 dígitos**.

No PC:

```powershell
adb pair IP:PORTA_PAREAMENTO
```

Exemplo:

```powershell
adb pair 192.168.15.16:42715
```

Digite o código quando pedir.

#### C.2 — Conectar (porta de conexão ≠ porta de pareamento)

Na tela de Depuração sem fio, use o **IP:porta** mostrado como endereço do dispositivo (não o de pareamento).

```powershell
adb connect IP:PORTA_CONEXAO
adb devices
```

Exemplo:

```powershell
adb connect 192.168.15.16:37829
```

Deve aparecer `IP:porta    device`.

**Se cair a conexão** (`Lost connection` / some da lista):

```powershell
adb disconnect
adb connect IP:PORTA_CONEXAO
adb devices
```

A porta pode mudar depois de reiniciar o celular — confira de novo na tela de Depuração sem fio.

---

## 5. Rodar o app

Com o dispositivo já em `adb devices`:

```powershell
cd "C:\Users\Vitor Aletto\Desktop\multiplagier-mobile"
flutter pub get
flutter devices
```

Anote o **Device ID** (coluna do meio), por exemplo:

- Emulador: `emulator-5554`
- USB: um serial tipo `R58M...`
- Wi‑Fi: `192.168.15.16:37829`

### Escolher o device (obrigatório se houver Windows/Edge na lista)

```powershell
flutter run -d emulator-5554
```

ou

```powershell
flutter run -d 192.168.15.16:37829
```

ou (USB — use o id que `flutter devices` mostrou):

```powershell
flutter run -d COLE_O_ID_AQUI
```

Espere até aparecer:

```text
Flutter run key commands.
```

O app deve abrir na tela **Entrar**.

### Atalhos úteis (terminal do `flutter run`)

| Tecla | Ação |
|-------|------|
| `r` | Hot reload |
| `R` | Hot restart (reinicia o Dart; sessão/throttle em memória somem) |
| `q` | Encerra o `flutter run` |

### Limpar dados do app (banco demo “do zero”)

Útil antes do checklist completo:

```powershell
adb shell am force-stop br.edu.fatec.multiplagier.multiplagier_mobile
adb shell pm clear br.edu.fatec.multiplagier.multiplagier_mobile
```

Depois rode de novo `flutter run -d ...` **ou** abra o ícone do app se o APK já estiver instalado.

---

## 6. Checklist de teste de interface

Marque cada item. Digite **sempre na UI** (não por `adb input text`).

### Preparação

| # | Ação | Resultado esperado | OK? |
|---|------|--------------------|-----|
| P1 | Ambiente carregado (`java`, `adb`, `flutter`) | Comandos respondem | ☐ |
| P2 | Device em `adb devices` como `device` | Aparelho/emulador listado | ☐ |
| P3 | `flutter run -d <id>` | Tela **Entrar** | ☐ |
| P4 | (Opcional) `pm clear` antes | Banco reseeds na 1ª abertura | ☐ |

---

### T1 — Login com conta demo

| # | Ação | Resultado esperado | OK? |
|---|------|--------------------|-----|
| T1.1 | E-mail: `cliente@multiplagier.local` | Campo preenchido | ☐ |
| T1.2 | Senha: `Multiplagier@2026` | Campo preenchido | ☐ |
| T1.3 | Toque **Entrar** | Vai para **Catálogo**; “Olá, Cliente Demo” | ☐ |
| T1.4 | Conferir lista | 5 produtos ativos; sem “Produto Descontinuado” | ☐ |
| T1.5 | Ícones no topo | **Pedidos**, **Carrinho**, **Sair** | ☐ |

---

### T2 — Login inválido (mensagem genérica)

| # | Ação | Resultado esperado | OK? |
|---|------|--------------------|-----|
| T2.1 | **Sair** | Volta para Entrar | ☐ |
| T2.2 | E-mail demo + senha `errada123` → **Entrar** | `E-mail ou senha inválidos.` | ☐ |
| T2.3 | E-mail `naoexiste@x.local` + qualquer senha | Mesma mensagem genérica (não diz “e-mail não cadastrado”) | ☐ |

---

### T3 — SEC-003 (limite de tentativas)

Faça **sem fechar o app** e **sem** hot restart.

| # | Ação | Resultado esperado | OK? |
|---|------|--------------------|-----|
| T3.1 | No mesmo e-mail `cliente@multiplagier.local`, erre a senha **5 vezes** (ex.: `WrongPass99`) | Nas primeiras: `E-mail ou senha inválidos.` | ☐ |
| T3.2 | 6ª tentativa (ainda errada ou até certa, ainda no bloqueio) | `Muitas tentativas. Aguarde 1 minuto e tente novamente.` | ☐ |
| T3.3 | Espere **1 minuto** (cronômetro) | — | ☐ |
| T3.4 | Login correto demo | Entra no Catálogo de novo | ☐ |

Se o bloqueio “não acontecer”: confirme que era o **mesmo** e-mail, que o app não reiniciou, e que limpou o campo senha entre tentativas (sem concatenar texto).

---

### T4 — Busca e filtro (US-009)

Partindo do Catálogo logado:

| # | Ação | Resultado esperado | OK? |
|---|------|--------------------|-----|
| T4.1 | Chip **Todas** | Lista completa de ativos | ☐ |
| T4.2 | Chip **Áudio** | Só Fone e Caixa de Som | ☐ |
| T4.3 | Chip **TVs** | Só Smart TV | ☐ |
| T4.4 | Chip **Tablets** | Só Tablet (sem estoque) | ☐ |
| T4.5 | Chip **Periféricos** | Só Mouse | ☐ |
| T4.6 | Busca: digite `Fone` | Filtra pelo nome | ☐ |
| T4.7 | Limpar busca (X) + **Todas** | Lista completa de novo | ☐ |

---

### T5 — Conta, endereço, carrinho e pedido

| # | Ação | Resultado esperado | OK? |
|---|------|--------------------|-----|
| T5.1 | Ícone de **conta** (AppBar) | Tela **Minha conta** com nome, e-mail (somente leitura) e endereço | ☐ |
| T5.2 | Altere o nome ou o endereço → **Salvar** | Mensagem `Dados salvos.`; cumprimento no Home atualiza o nome | ☐ |
| T5.3 | Abra **Fone de Ouvido Bluetooth** → **Adicionar ao carrinho** | Feedback de sucesso | ☐ |
| T5.4 | **Carrinho** → **Finalizar pedido** | Tela **Pagamento** com card **Entregar em** (endereço do perfil) | ☐ |
| T5.5 | Pix ou Cartão → **Confirmar** / **Pagar** | Detalhe do pedido com pagamento **e** bloco **Entrega** | ☐ |
| T5.6 | Conta **nova** sem endereço: tente pagar | Botão bloqueado / pede cadastrar endereço; após salvar, libera | ☐ |
| T5.7 | **Pedidos** → abrir o pedido | Itens, total, pagamento e endereço congelados | ☐ |

---

### T6 — Cadastro de nova conta

| # | Ação | Resultado esperado | OK? |
|---|------|--------------------|-----|
| T6.1 | Conta → **Sair** → **Criar conta** | Tela Criar conta | ☐ |
| T6.2 | Senha só `abcdef` → Cadastrar | Erro de senha fraca | ☐ |
| T6.3 | Preencha nome, e-mail **novo**, senha `SenhaForte1` (e confirmação) | Entra no Catálogo já logado | ☐ |
| T6.4 | Conta → **Sair** e tente cadastrar o **mesmo** e-mail | `Este e-mail já está cadastrado.` | ☐ |
| T6.5 | Login com a conta nova | Catálogo; carrinho/pedidos dessa conta (não mistura com demo) | ☐ |

---

### T7 — Sessão e logout

| # | Ação | Resultado esperado | OK? |
|---|------|--------------------|-----|
| T7.1 | Logado → fechar o app pelo botão recentes e reabrir o ícone | Se a sessão persistiu: volta logado (id salvo); senão: tela Entrar | ☐ |
| T7.2 | Ícone **conta** → **Sair** | Tela Entrar; não vê catálogo | ☐ |

(Com `flutter run` ativo, preferir testar logout pela UI; `R` no terminal zera throttle em memória.)

---

### T8 — Isolamento visual de pedidos (SEC-001 — sanidade)

No MVP local não há segundo aparelho fácil; sanidade mínima:

| # | Ação | Resultado esperado | OK? |
|---|------|--------------------|-----|
| T8.1 | Conta A cria pedido | Aparece em **Pedidos** da conta A | ☐ |
| T8.2 | **Sair**, entrar conta B (outra) | **Pedidos** de B não lista o pedido de A (vazio ou só os de B) | ☐ |

---

## 7. Folha de resultado (preencha na hora)

| Item | Emulador | USB | Wi‑Fi |
|------|----------|-----|-------|
| Subiu / conectou | ☐ | ☐ | ☐ |
| `flutter run` no device certo | ☐ | ☐ | ☐ |
| T1 Login demo | ☐ | ☐ | ☐ |
| T2 Login inválido | ☐ | ☐ | ☐ |
| T3 SEC-003 | ☐ | ☐ | ☐ |
| T4 Busca/filtro | ☐ | ☐ | ☐ |
| T5 Carrinho/pedido | ☐ | ☐ | ☐ |
| T6 Cadastro | ☐ | ☐ | ☐ |
| T7 Logout/sessão | ☐ | ☐ | ☐ |
| T8 Isolamento pedidos | ☐ | ☐ | ☐ |

**Data:** ____/____/________  
**Testador:** ________________  
**Device ID usado:** ________________  
**Observações:**

_________________________________________________________________

_________________________________________________________________

---

## 8. Problemas comuns (offline)

### `adb` não é reconhecido

```powershell
$env:Path = "C:\Android\Sdk\platform-tools;" + $env:Path
# ou use o caminho completo:
C:\Android\Sdk\platform-tools\adb.exe devices
```

### `JAVA_HOME is not set` / Gradle falha

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:Path = "$env:JAVA_HOME\bin;" + $env:Path
```

Feche e abra o terminal se a variável de usuário já foi gravada antes, **ou** use o bloco da seção 2 sempre.

### `flutter run` abre Windows em vez do celular

Sempre passe `-d` com o id Android:

```powershell
flutter devices
flutter run -d <id-android>
```

### Celular `unauthorized`

Desbloqueie o aparelho, aceite o diálogo de depuração, `adb kill-server` → `adb start-server` → `adb devices`.

### Wi‑Fi: device some

```powershell
adb connect IP:PORTA
```

Confira IP/porta na tela **Depuração sem fio** (pode ter mudado).

### App “preso” / banco estranho

```powershell
adb shell am force-stop br.edu.fatec.multiplagier.multiplagier_mobile
adb shell pm clear br.edu.fatec.multiplagier.multiplagier_mobile
flutter run -d <id>
```

### SEC-003 não bloqueia

- Mesmo e-mail nas 5 falhas  
- App não reiniciou  
- Campo senha **substituído**, não concatenado  
- Esperou a 6ª tentativa ainda dentro da janela de bloqueio  

### Emulador lento / 1ª build

A primeira `assembleDebug` pode levar vários minutos. Espere; builds seguintes são mais rápidas.

---

## 9. Sequência mínima “tudo em 15–20 min”

1. Carregar env (seção 2).  
2. Subir emulador **ou** conectar USB/Wi‑Fi.  
3. `pm clear` + `flutter run -d <id>`.  
4. T1 → T2 → T3 → T4 → T5 → T6 → T8.  
5. Preencher a folha da seção 7.

---

## 10. O que este teste **não** cobre

- API / sincronização com o Multiplagier web (ainda não iniciada)  
- iOS  
- Painel admin  
- Automatização por `adb input text` (de propósito — use a UI)

---

## 11. Referências no repositório (já locais)

| Arquivo | Conteúdo |
|---------|----------|
| `README.md` | Status, demo user, quick start |
| `docs/instalacao.md` | Ambiente Flutter/Android |
| `docs/seguranca.md` | PBKDF2, SEC-001, SEC-003 |
| `lib/data/db/seed.dart` | Produtos e usuário demo |

Fim do guia.
