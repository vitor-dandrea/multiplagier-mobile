# Instalação e execução

Guia para rodar o **Multiplagier Mobile** no Windows com emulador Android. Ambiente validado em **05/11/2026**.

## Pré-requisitos

### Flutter SDK (caminho sem espaços)

Instale o Flutter em um caminho **sem espaços**, por exemplo:

```text
C:\flutter
```

Caminhos com espaços (ex.: `C:\Users\Vitor Aletto\...`) quebram o build nativo do `sqlite3`.

Adicione `C:\flutter\bin` ao `PATH` e confira:

```bash
flutter doctor
```

### Android Studio e SDK

1. Instale o **Android Studio**.
2. Configure o Android SDK em:

```text
C:\Android\Sdk
```

3. Variáveis úteis (PowerShell / variáveis de ambiente do sistema):

| Variável | Valor |
|----------|-------|
| `ANDROID_HOME` / `ANDROID_SDK_ROOT` | `C:\Android\Sdk` |
| `PATH` | incluir `%ANDROID_HOME%\platform-tools` |

### Emulador (AVD)

Crie/use o AVD **`Pixel_6_API_35`**.

Esse emulador foi validado com o app em **05/11/2026**.

### Modo de Desenvolvedor (Windows)

Necessário para o suporte a plugins Flutter no Windows:

```bash
start ms-settings:developers
```

Ative **Modo de Desenvolvedor**.

### Node.js (opcional)

Só é necessário para gerar relatórios Word em `docs/`:

```bash
cd docs
npm install
npm run relatorio
```

### Git / gh

Git para versionamento; [GitHub CLI (`gh`)](https://cli.github.com/) para PRs e issues.

## Clonar e instalar dependências

```bash
git clone https://github.com/vitor-dandrea/multiplagier-mobile.git
cd multiplagier-mobile
flutter pub get
```

## Executar

1. Inicie o AVD `Pixel_6_API_35` (ou conecte um dispositivo).
2. Confira dispositivos:

```bash
flutter devices
```

3. Rode o app:

```bash
flutter run
```

Na primeira execução o SQLite é criado com seed (produtos e usuário demo).

## Conta de demonstração

| Campo | Valor |
|-------|-------|
| E-mail | `cliente@multiplagier.local` |
| Senha | `Multiplagier@2026` |

## Testes

```bash
flutter test
```

Capturas em `docs/evidencias/` podem ser regeneradas com:

```bash
flutter test tool/screenshots/capture_screens_test.dart
```

## Checklist rápido

- [ ] Flutter em `C:\flutter` (sem espaços)
- [ ] SDK Android em `C:\Android\Sdk`
- [ ] AVD `Pixel_6_API_35` disponível
- [ ] Modo de Desenvolvedor ativo no Windows
- [ ] `flutter pub get` ok
- [ ] `flutter run` no emulador
- [ ] Login com a conta demo
- [ ] `flutter test` verde
