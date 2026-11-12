// Gera o Guia de Teste Manual (Word) — PC / USB / Wi-Fi bem separados.
// Uso: cd docs && npm install && npm run guia:manual
import fs from "fs";
import {
  Document,
  Packer,
  Paragraph,
  TextRun,
  HeadingLevel,
  AlignmentType,
  BorderStyle,
  Table,
  TableRow,
  TableCell,
  WidthType,
  ShadingType,
  Footer,
  Header,
  PageNumber,
  PageBreak,
} from "docx";

const FONT = "Calibri";
const ACCENT = "0F4C81";
const MUTED = "5B6773";
const PAGE = { width: 11906, height: 16838 };
const MARGIN = 900;
const CONTENT_WIDTH = PAGE.width - MARGIN * 2;
const OUT = "./Guia_Teste_Manual_Multiplagier_Mobile.docx";

const BORDER = { style: BorderStyle.SINGLE, size: 4, color: "B8C2CC" };
const BORDERS = { top: BORDER, bottom: BORDER, left: BORDER, right: BORDER };

function run(text, opts = {}) {
  return new TextRun({ text, font: FONT, size: opts.size ?? 21, ...opts });
}

function h1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 280, after: 120 },
    border: { bottom: { style: BorderStyle.SINGLE, size: 12, color: ACCENT, space: 4 } },
    children: [run(text, { bold: true, size: 28, color: ACCENT })],
  });
}

function h2(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 220, after: 80 },
    children: [run(text, { bold: true, size: 24, color: ACCENT })],
  });
}

function h3(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_3,
    spacing: { before: 160, after: 60 },
    children: [run(text, { bold: true, size: 22, color: "1F3A5F" })],
  });
}

function p(text, opts = {}) {
  return new Paragraph({
    spacing: { after: opts.after ?? 80, line: 276 },
    alignment: opts.align ?? AlignmentType.JUSTIFIED,
    children: [run(text, opts)],
  });
}

function note(text) {
  return new Paragraph({
    spacing: { after: 100, line: 260 },
    shading: { type: ShadingType.CLEAR, color: "auto", fill: "FFF2C6" },
    children: [run("Atenção: ", { bold: true, size: 20 }), run(text, { size: 20 })],
  });
}

function bullet(text) {
  return new Paragraph({
    spacing: { after: 50, line: 260 },
    indent: { left: 360 },
    children: [run("• " + text, { size: 20 })],
  });
}

function code(text) {
  return new Paragraph({
    spacing: { after: 40, before: 20, line: 240 },
    shading: { type: ShadingType.CLEAR, color: "auto", fill: "F0F3F6" },
    children: [run(text, { font: "Consolas", size: 17 })],
  });
}

function spacer(after = 120) {
  return new Paragraph({ spacing: { after }, children: [] });
}

function cell(text, width, opts = {}) {
  return new TableCell({
    width: { size: width, type: WidthType.DXA },
    borders: BORDERS,
    shading: opts.fill
      ? { type: ShadingType.CLEAR, color: "auto", fill: opts.fill }
      : undefined,
    margins: { top: 60, bottom: 60, left: 80, right: 80 },
    children: [
      new Paragraph({
        spacing: { after: 20, line: 230 },
        children: [
          run(String(text), {
            size: opts.size ?? 18,
            bold: opts.bold,
            color: opts.color,
          }),
        ],
      }),
    ],
  });
}

function table(widths, rows) {
  return new Table({
    width: { size: widths.reduce((a, b) => a + b, 0), type: WidthType.DXA },
    columnWidths: widths,
    rows,
  });
}

function kv(rows) {
  const w = [3200, CONTENT_WIDTH - 3200];
  return table(
    w,
    rows.map(
      ([k, v]) =>
        new TableRow({
          children: [
            cell(k, w[0], { bold: true, fill: "EAF1F8" }),
            cell(v, w[1]),
          ],
        }),
    ),
  );
}

function checkTable(headers, rows) {
  const n = headers.length;
  const widths =
    n === 3
      ? [900, Math.floor((CONTENT_WIDTH - 900) * 0.55), Math.floor((CONTENT_WIDTH - 900) * 0.45)]
      : n === 4
        ? [700, 2800, CONTENT_WIDTH - 700 - 2800 - 900, 900]
        : [CONTENT_WIDTH];
  return table(widths, [
    new TableRow({
      tableHeader: true,
      children: headers.map((h, i) =>
        cell(h, widths[i], { bold: true, fill: ACCENT, color: "FFFFFF" }),
      ),
    }),
    ...rows.map(
      (r) =>
        new TableRow({
          children: r.map((c, i) => cell(c, widths[i])),
        }),
    ),
  ]);
}

function channelBanner(title, subtitle) {
  return [
    new Paragraph({
      spacing: { before: 80, after: 60 },
      shading: { type: ShadingType.CLEAR, color: "auto", fill: ACCENT },
      children: [run(title, { bold: true, size: 26, color: "FFFFFF" })],
    }),
    new Paragraph({
      spacing: { after: 140 },
      shading: { type: ShadingType.CLEAR, color: "auto", fill: "EAF1F8" },
      children: [run(subtitle, { size: 20, color: MUTED })],
    }),
  ];
}

function pageBreak() {
  return new Paragraph({ children: [new PageBreak()] });
}

const children = [
  // CAPA
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 800, after: 80 },
    children: [run("Multiplagier Mobile", { bold: true, size: 40, color: ACCENT })],
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 200 },
    children: [run("Guia de Teste Manual de Interface", { bold: true, size: 30 })],
  }),
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 80 },
    children: [run("Documento offline — use no PC sem internet", { size: 22, color: MUTED })],
  }),
  spacer(200),
  kv([
    ["Projeto", "Multiplagier Mobile (Flutter + SQLite local)"],
    ["Pacote Android", "br.edu.fatec.multiplagier.multiplagier_mobile"],
    ["Canais cobertos", "1) Emulador no PC  ·  2) Celular USB  ·  3) Celular Wi‑Fi"],
    ["Como digitar login", "SEMPRE na tela do app (não use adb input text)"],
    ["Atualizado em", "11/11/2026"],
  ]),
  spacer(200),
  p(
    "Este guia está organizado em blocos separados. Faça primeiro a Parte 0 (comum). Depois escolha APENAS UM canal: Parte A (PC/emulador), Parte B (USB) ou Parte C (Wi‑Fi). Em seguida execute a Parte D (checklist de telas) e preencha a folha de resultado.",
  ),
  pageBreak(),

  // PARTE 0
  h1("Parte 0 — Preparação comum (sempre)"),
  h2("0.1 Onde abrir o terminal"),
  bullet("Abra o PowerShell (Windows Terminal ou terminal do Cursor)."),
  bullet("Entre na pasta do projeto:"),
  code('cd "C:\\Users\\Vitor Aletto\\Desktop\\multiplagier-mobile"'),
  h2("0.2 Ambiente desta sessão (cole em toda janela nova)"),
  code('$env:JAVA_HOME = "C:\\Program Files\\Android\\Android Studio\\jbr"'),
  code('$env:ANDROID_HOME = "C:\\Android\\Sdk"'),
  code('$env:ANDROID_SDK_ROOT = "C:\\Android\\Sdk"'),
  code(
    '$env:Path = "$env:JAVA_HOME\\bin;C:\\Android\\Sdk\\platform-tools;C:\\Android\\Sdk\\emulator;C:\\flutter\\bin;" + $env:Path',
  ),
  h2("0.3 Conferir ferramentas"),
  code("java -version"),
  code("adb version"),
  code("flutter --version"),
  h2("0.4 Caminhos deste PC"),
  kv([
    ["Flutter", "C:\\flutter"],
    ["Android SDK", "C:\\Android\\Sdk"],
    ["adb", "C:\\Android\\Sdk\\platform-tools\\adb.exe"],
    ["JAVA_HOME", "C:\\Program Files\\Android\\Android Studio\\jbr"],
    ["AVD", "Pixel_6_API_35"],
    ["Projeto", "C:\\Users\\Vitor Aletto\\Desktop\\multiplagier-mobile"],
  ]),
  h2("0.5 Credenciais"),
  h3("Conta demo (seed)"),
  kv([
    ["E-mail", "cliente@multiplagier.local"],
    ["Senha", "Multiplagier@2026"],
    ["Nome na UI", "Cliente Demo"],
  ]),
  h3("Conta nova (cadastro — exemplo)"),
  kv([
    ["Nome", "Ana Silva"],
    ["E-mail", "ana.silva.teste@multiplagier.local"],
    ["Senha / confirmação", "SenhaForte1"],
  ]),
  p("Regra de senha: mínimo 8 caracteres, com letra e número."),
  note(
    "Digite e-mail e senha tocados nos campos da tela. Não use adb shell input text — o texto pode ir para a busca do sistema ou concatenar no mesmo campo.",
  ),
  h2("0.6 Mensagens esperadas"),
  kv([
    ["Login errado", "E-mail ou senha inválidos."],
    ["SEC-003 (após 5 falhas)", "Muitas tentativas. Aguarde 1 minuto e tente novamente."],
    ["E-mail duplicado", "Este e-mail já está cadastrado."],
    ["Senha fraca", "A senha deve ter pelo menos 8 caracteres, com letras e números."],
  ]),
  p(
    "SEC-003 fica só na memória do app. Se fechar o app, der force-stop ou limpar dados, o bloqueio zera.",
  ),
  pageBreak(),

  // PARTE A
  ...channelBanner(
    "PARTE A — Rodar no PC (emulador Android)",
    "Use esta parte se NÃO for testar no celular. Ignore as Partes B e C.",
  ),
  h1("Parte A — Emulador no PC"),
  h2("A.1 Subir o emulador"),
  code("flutter emulators"),
  code("flutter emulators --launch Pixel_6_API_35"),
  p("Alternativa:"),
  code("emulator -avd Pixel_6_API_35"),
  bullet("Espere a home do Android carregar."),
  bullet("Arraste a janela do emulador para a direita da tela (centro-direita), para ver o app com conforto."),
  h2("A.2 Confirmar que o adb vê o emulador"),
  code("adb devices"),
  p('Deve aparecer uma linha como: emulator-5554    device'),
  h2("A.3 Instalar e abrir o app no emulador"),
  code("cd \"C:\\Users\\Vitor Aletto\\Desktop\\multiplagier-mobile\""),
  code("flutter pub get"),
  code("flutter devices"),
  code("flutter run -d emulator-5554"),
  note(
    "Se o ID do emulador for outro (ex.: emulator-5556), use o ID mostrado em flutter devices / adb devices.",
  ),
  p('Espere a mensagem "Flutter run key commands." A tela Entrar deve abrir no emulador.'),
  h2("A.4 (Opcional) Zerar dados do app no emulador"),
  code("adb shell am force-stop br.edu.fatec.multiplagier.multiplagier_mobile"),
  code("adb shell pm clear br.edu.fatec.multiplagier.multiplagier_mobile"),
  p("Depois rode novamente: flutter run -d emulator-5554"),
  h2("A.5 Atalhos no terminal do flutter run"),
  kv([
    ["r", "Hot reload"],
    ["R", "Hot restart (zera throttle SEC-003 em memória)"],
    ["q", "Encerrar flutter run"],
  ]),
  p("Quando o app estiver aberto no emulador, vá para a Parte D (checklist de telas)."),
  pageBreak(),

  // PARTE B
  ...channelBanner(
    "PARTE B — Celular por cabo USB",
    "Use esta parte para aparelho físico com cabo. Ignore as Partes A e C.",
  ),
  h1("Parte B — Celular via USB"),
  h2("B.1 No celular (uma vez)"),
  bullet("Configurações → Sobre o telefone → toque 7 vezes em Número da versão (ativa Opções do desenvolvedor)."),
  bullet("Opções do desenvolvedor → ative Depuração USB."),
  bullet("Conecte o cabo USB ao PC."),
  bullet("No celular, aceite Permitir depuração USB (marque Confiar neste computador se aparecer)."),
  h2("B.2 No PC — ver o aparelho"),
  code("adb devices"),
  p("Esperado: uma linha com o serial do aparelho e a palavra device (não unauthorized)."),
  p("Se aparecer unauthorized: desbloqueie a tela, aceite o diálogo, depois:"),
  code("adb kill-server"),
  code("adb start-server"),
  code("adb devices"),
  h2("B.3 Rodar o app no celular USB"),
  code("cd \"C:\\Users\\Vitor Aletto\\Desktop\\multiplagier-mobile\""),
  code("flutter pub get"),
  code("flutter devices"),
  p("Anote o Device ID do celular (não use windows nem edge)."),
  code("flutter run -d COLE_AQUI_O_ID_DO_CELULAR"),
  note(
    "Exemplo de ID USB: um código tipo R58MXXXX. Sempre passe -d para não abrir no Windows por engano.",
  ),
  h2("B.4 (Opcional) Limpar dados no celular"),
  code("adb shell am force-stop br.edu.fatec.multiplagier.multiplagier_mobile"),
  code("adb shell pm clear br.edu.fatec.multiplagier.multiplagier_mobile"),
  code("flutter run -d COLE_AQUI_O_ID_DO_CELULAR"),
  p("Com o app na tela Entrar, vá para a Parte D."),
  pageBreak(),

  // PARTE C
  ...channelBanner(
    "PARTE C — Celular por Wi‑Fi (ADB wireless)",
    "Use esta parte sem cabo (mesma rede Wi‑Fi). Ignore as Partes A e B.",
  ),
  h1("Parte C — Celular via Wi‑Fi"),
  h2("C.1 Pré-requisitos"),
  bullet("Celular e PC na mesma rede Wi‑Fi."),
  bullet("Opções do desenvolvedor ativas."),
  bullet("Depuração sem fio ligada no celular."),
  bullet("adb no PATH desta sessão (Parte 0)."),
  h2("C.2 Parear (só quando pedir código novo)"),
  p(
    "No celular: Opções do desenvolvedor → Depuração sem fio → Parear dispositivo com código de pareamento.",
  ),
  bullet("Anote IP:PORTA de pareamento (ex.: 192.168.15.16:42715)."),
  bullet("Anote o código de 6 dígitos."),
  code("adb pair 192.168.15.16:42715"),
  p("Digite o código quando o PowerShell pedir."),
  h2("C.3 Conectar (porta de conexão ≠ porta de pareamento)"),
  p(
    "Na tela Depuração sem fio, use o endereço IP:porta do dispositivo (porta de conexão, geralmente outra).",
  ),
  code("adb connect 192.168.15.16:37829"),
  code("adb devices"),
  p("Esperado: 192.168.15.16:37829    device"),
  note(
    "Substitua IP e portas pelos valores da SUA tela. A porta muda com frequência após reiniciar o celular.",
  ),
  h2("C.4 Rodar o app no celular Wi‑Fi"),
  code("cd \"C:\\Users\\Vitor Aletto\\Desktop\\multiplagier-mobile\""),
  code("flutter pub get"),
  code("flutter devices"),
  code("flutter run -d 192.168.15.16:37829"),
  h2("C.5 Se cair a conexão (Lost connection)"),
  code("adb disconnect"),
  code("adb connect IP:PORTA_CONEXAO"),
  code("adb devices"),
  code("flutter run -d IP:PORTA_CONEXAO"),
  p("Com o app na tela Entrar, vá para a Parte D."),
  pageBreak(),

  // PARTE D
  h1("Parte D — Checklist de telas (igual para os 3 canais)"),
  p(
    "Execute depois que o app estiver aberto (Parte A, B ou C). Digite sempre na UI. Marque OK à mão.",
  ),
  h2("D.1 Login demo"),
  checkTable(
    ["#", "Ação", "Esperado", "OK"],
    [
      ["1", "E-mail cliente@multiplagier.local", "Campo preenchido", "☐"],
      ["2", "Senha Multiplagier@2026", "Campo preenchido", "☐"],
      ["3", "Tocar Entrar", "Catálogo; Olá, Cliente Demo", "☐"],
      ["4", "Ver lista", "5 produtos ativos; sem Descontinuado", "☐"],
      ["5", "Topo", "Pedidos, Carrinho, Sair", "☐"],
    ],
  ),
  h2("D.2 Login inválido"),
  checkTable(
    ["#", "Ação", "Esperado", "OK"],
    [
      ["1", "Sair", "Tela Entrar", "☐"],
      ["2", "Senha errada no e-mail demo", "E-mail ou senha inválidos.", "☐"],
      ["3", "E-mail inexistente + qualquer senha", "Mesma mensagem genérica", "☐"],
    ],
  ),
  h2("D.3 SEC-003 (5 falhas / 1 min)"),
  p("Não feche o app e não use hot restart (R) durante este teste."),
  checkTable(
    ["#", "Ação", "Esperado", "OK"],
    [
      ["1", "5× senha errada no mesmo e-mail demo", "Mensagem de inválido nas primeiras", "☐"],
      ["2", "6ª tentativa ainda no bloqueio", "Muitas tentativas. Aguarde 1 minuto...", "☐"],
      ["3", "Esperar 1 minuto", "—", "☐"],
      ["4", "Login demo correto", "Entra no Catálogo", "☐"],
    ],
  ),
  h2("D.4 Busca e filtro"),
  checkTable(
    ["#", "Ação", "Esperado", "OK"],
    [
      ["1", "Chip Todas", "Lista completa", "☐"],
      ["2", "Chip Áudio", "Fone + Caixa de Som", "☐"],
      ["3", "Chip TVs / Tablets / Periféricos", "Só a categoria", "☐"],
      ["4", "Busca: Fone", "Filtra pelo nome", "☐"],
    ],
  ),
  h2("D.5 Carrinho e pedido"),
  checkTable(
    ["#", "Ação", "Esperado", "OK"],
    [
      ["1", "Abrir Fone de Ouvido Bluetooth", "Detalhe com preço R$ 189,90", "☐"],
      ["2", "Adicionar ao carrinho", "Feedback de sucesso", "☐"],
      ["3", "Abrir Carrinho", "Item + total", "☐"],
      ["4", "Finalizar pedido → Confirmar", "Pedido #… Pendente", "☐"],
      ["5", "Menu Pedidos", "Lista com o pedido", "☐"],
    ],
  ),
  h2("D.6 Cadastro"),
  checkTable(
    ["#", "Ação", "Esperado", "OK"],
    [
      ["1", "Sair → Criar conta", "Tela de cadastro", "☐"],
      ["2", "Senha fraca (ex.: abcdef)", "Erro de regra de senha", "☐"],
      ["3", "Conta nova válida (SenhaForte1)", "Entra no Catálogo", "☐"],
      ["4", "Recadastrar mesmo e-mail", "Este e-mail já está cadastrado.", "☐"],
    ],
  ),
  h2("D.7 Isolamento de pedidos (sanidade)"),
  checkTable(
    ["#", "Ação", "Esperado", "OK"],
    [
      ["1", "Conta A cria pedido", "Aparece em Pedidos de A", "☐"],
      ["2", "Sair e entrar conta B", "Pedidos de B não mostra o de A", "☐"],
    ],
  ),
  pageBreak(),

  h1("Parte E — Folha de resultado"),
  checkTable(
    ["Item", "PC/Emulador", "USB", "Wi‑Fi"],
    [
      ["Conectou / subiu", "☐", "☐", "☐"],
      ["flutter run no device certo", "☐", "☐", "☐"],
      ["Login demo", "☐", "☐", "☐"],
      ["Login inválido", "☐", "☐", "☐"],
      ["SEC-003", "☐", "☐", "☐"],
      ["Busca/filtro", "☐", "☐", "☐"],
      ["Carrinho/pedido", "☐", "☐", "☐"],
      ["Cadastro", "☐", "☐", "☐"],
      ["Isolamento pedidos", "☐", "☐", "☐"],
    ],
  ),
  spacer(160),
  p("Data: ____/____/________     Testador: ______________________________"),
  p("Canal usado nesta sessão:  ☐ PC/Emulador   ☐ USB   ☐ Wi‑Fi"),
  p("Device ID: ________________________________________________"),
  p("Observações:"),
  p("________________________________________________________________"),
  p("________________________________________________________________"),
  pageBreak(),

  h1("Parte F — Problemas comuns"),
  h2("adb não reconhecido"),
  code("$env:Path = \"C:\\Android\\Sdk\\platform-tools;\" + $env:Path"),
  code("C:\\Android\\Sdk\\platform-tools\\adb.exe devices"),
  h2("JAVA_HOME / Gradle"),
  code('$env:JAVA_HOME = "C:\\Program Files\\Android\\Android Studio\\jbr"'),
  code('$env:Path = "$env:JAVA_HOME\\bin;" + $env:Path'),
  h2("Abriu Windows em vez do Android"),
  code("flutter devices"),
  code("flutter run -d <id-android>"),
  h2("Wi‑Fi caiu"),
  code("adb connect IP:PORTA"),
  h2("App/banco estranho"),
  code("adb shell pm clear br.edu.fatec.multiplagier.multiplagier_mobile"),
  code("flutter run -d <id>"),
  spacer(200),
  p(
    "Fim do guia. Produtos ativos do seed: Smart TV 50\" 4K; Fone de Ouvido Bluetooth; Tablet 10\" 64GB (sem estoque); Caixa de Som Portátil; Mouse Gamer RGB. Não deve aparecer: Produto Descontinuado.",
    { color: MUTED, size: 18 },
  ),
];

const doc = new Document({
  creator: "Equipe Multiplagier",
  title: "Guia de Teste Manual — Multiplagier Mobile",
  description: "Instruções separadas: emulador PC, celular USB e celular Wi-Fi",
  styles: { default: { document: { run: { font: FONT, size: 21 } } } },
  sections: [
    {
      properties: {
        page: {
          size: PAGE,
          margin: { top: MARGIN, bottom: MARGIN, left: MARGIN, right: MARGIN },
        },
      },
      headers: {
        default: new Header({
          children: [
            new Paragraph({
              alignment: AlignmentType.RIGHT,
              children: [
                run("Multiplagier Mobile — Guia de Teste Manual", {
                  size: 16,
                  color: "8A949E",
                }),
              ],
            }),
          ],
        }),
      },
      footers: {
        default: new Footer({
          children: [
            new Paragraph({
              alignment: AlignmentType.CENTER,
              children: [
                run("Offline  ·  Página ", { size: 16, color: "8A949E" }),
                new TextRun({
                  children: [PageNumber.CURRENT],
                  font: FONT,
                  size: 16,
                  color: "8A949E",
                }),
              ],
            }),
          ],
        }),
      },
      children,
    },
  ],
});

fs.writeFileSync(new URL(OUT, import.meta.url), await Packer.toBuffer(doc));
console.log("Gerado:", OUT);
