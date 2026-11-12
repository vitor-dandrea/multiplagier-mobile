// Gera docs/Documentacao_Final_Dispositivos_Moveis_Multiplagier.docx
// Estrutura baseada em "Documentação Projeto - Final.docx"
// Uso: cd docs && npm install && npm run doc:final
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
} from "docx";

const DATA_DOC = "05/11/2026";
const REPO = "https://github.com/vitor-dandrea/multiplagier-mobile";
const FONT = "Calibri";
const HEADING_COLOR = "0F4C81";
const CONTENT_WIDTH = 9638; // A4 com margens de 2 cm, em DXA
const BORDER = { style: BorderStyle.SINGLE, size: 4, color: "B8C2CC" };
const BORDERS = { top: BORDER, bottom: BORDER, left: BORDER, right: BORDER };

function run(text, opts = {}) {
  return new TextRun({ text, font: FONT, size: opts.size ?? 22, ...opts });
}

function h1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 360, after: 160 },
    children: [run(text, { bold: true, size: 30, color: HEADING_COLOR })],
  });
}

function h2(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 240, after: 120 },
    children: [run(text, { bold: true, size: 24, color: HEADING_COLOR })],
  });
}

function p(text, opts = {}) {
  return new Paragraph({
    spacing: { after: 120, line: 276 },
    alignment: opts.align ?? AlignmentType.JUSTIFIED,
    children: [run(text, opts)],
  });
}

function bullet(text) {
  return new Paragraph({
    spacing: { after: 80, line: 270 },
    indent: { left: 360, hanging: 240 },
    alignment: AlignmentType.JUSTIFIED,
    children: [run("• "), run(text)],
  });
}

function mono(text) {
  return new Paragraph({
    spacing: { after: 40, line: 240 },
    indent: { left: 200 },
    children: [run(text, { font: "Consolas", size: 18, color: "334155" })],
  });
}

function cell(content, width, opts = {}) {
  const paragraphs = (Array.isArray(content) ? content : [content]).map((c) =>
    typeof c === "string"
      ? new Paragraph({
          spacing: { after: 40, line: 252 },
          alignment: opts.align ?? AlignmentType.LEFT,
          children: [
            run(c, {
              size: opts.size ?? 20,
              bold: opts.bold,
              color: opts.color,
            }),
          ],
        })
      : c,
  );
  return new TableCell({
    width: { size: width, type: WidthType.DXA },
    borders: opts.borders ?? BORDERS,
    shading: opts.fill
      ? { type: ShadingType.CLEAR, color: "auto", fill: opts.fill }
      : undefined,
    margins: { top: 80, bottom: 80, left: 100, right: 100 },
    children: paragraphs,
  });
}

function headerRow(labels, widths) {
  return new TableRow({
    tableHeader: true,
    cantSplit: true,
    children: labels.map((label, i) =>
      cell(label, widths[i], { bold: true, fill: HEADING_COLOR, color: "FFFFFF" }),
    ),
  });
}

function table(widths, rows) {
  return new Table({
    width: { size: widths.reduce((a, b) => a + b, 0), type: WidthType.DXA },
    columnWidths: widths,
    rows,
  });
}

function spacer(after = 120) {
  return new Paragraph({ spacing: { after }, children: [] });
}

// ---------------------------------------------------------------------------
// Seções (espelham o modelo "Documentação Projeto - Final")
// ---------------------------------------------------------------------------
function capa() {
  return [
    new Paragraph({
      spacing: { after: 60 },
      children: [
        run("Documento de Projeto de Software — Dispositivos Móveis", {
          size: 20,
          color: "5B6773",
        }),
      ],
    }),
    new Paragraph({
      spacing: { after: 80 },
      children: [run("Multiplagier Mobile", { bold: true, size: 52, color: HEADING_COLOR })],
    }),
    new Paragraph({
      spacing: { after: 200 },
      border: {
        bottom: { style: BorderStyle.SINGLE, size: 12, color: HEADING_COLOR, space: 6 },
      },
      children: [
        run(`ISG022 | FATEC Mauá | DSM | 2026/2 | ${DATA_DOC}`, {
          size: 22,
          color: "5B6773",
        }),
      ],
    }),
    p(
      "Documentação final do aplicativo mobile acadêmico Multiplagier, alinhada ao roteiro “Documentação Projeto - Final”. Grupo Multiplagier — Vitor Aletto, Marco Machado e Mauro Junior.",
    ),
  ];
}

function secaoIntroducao() {
  return [
    h1("1. Introdução"),
    h2("Objetivo"),
    p(
      "O Multiplagier Mobile é o aplicativo de e-commerce acadêmico da loja Multiplagier (eletrônicos e acessórios). O propósito é permitir que o cliente consulte o catálogo, monte um carrinho e finalize pedidos pelo celular, com autenticação local e práticas básicas de segurança (hash de senha, sessão, isolamento de pedidos por usuário e limite de tentativas de login).",
    ),
    p(
      "O problema que resolve, no escopo acadêmico, é oferecer um canal mobile completo do fluxo de compra sem depender ainda da API do projeto web Laravel — toda a persistência atual é SQLite local, atrás de repositórios, para permitir sincronização futura.",
    ),
    h2("Público-alvo"),
    p(
      "Consumidores de eletrônicos e acessórios no perfil Cliente do backlog do Multiplagier. São usuários finais que desejam buscar e filtrar produtos, ver detalhes, adicionar itens ao carrinho e acompanhar apenas os próprios pedidos. O perfil Administrador não faz parte do escopo mobile atual.",
    ),
    h2("Tecnologia escolhida"),
    p(
      "A tecnologia escolhida foi Flutter (Dart 3.x), com validação principal no Android (emulador Pixel_6_API_35). Flutter foi adotado por permitir um único código multiplataforma, integração nativa com SQLite (sqflite) e alinhamento à stack já usada pela equipe no projeto acadêmico.",
    ),
  ];
}

function secaoArquitetura() {
  const widths = [2400, 7238];
  return [
    h1("2. Arquitetura do Software"),
    h2("Visão geral da arquitetura"),
    p(
      "O aplicativo segue uma arquitetura em três camadas principais: apresentação (widgets e pages em features/), negócios (controllers com ChangeNotifier) e dados (repositórios + SQLite). Há ainda o núcleo transversal core/ (hash de senha, sessão, throttle de login, validação e formatação).",
    ),
    p(
      "Compatibilidade entre plataformas: o código Dart é compartilhado; no Android a persistência usa o plugin nativo sqflite. Em desktop e testes automatizados usa-se sqflite_common_ffi, com factory injetada no bootstrap (main.dart). A entrega e a validação manual deste documento priorizam Android via Flutter; iOS não foi o alvo de execução nesta etapa.",
    ),
    h2("Componentes principais"),
    p("Interface (UI):", { bold: true }),
    p(
      "Telas Material construídas com widgets Flutter (formulários de login/cadastro, listas do catálogo, detalhe do produto, carrinho e pedidos). A navegação parte do AuthGate (sessão) para a home autenticada; ListenableBuilder/AnimatedBuilder reagem aos controllers.",
    ),
    p("Lógica de negócios:", { bold: true }),
    p(
      "AuthController e CartController (ChangeNotifier) orquestram casos de uso: autenticação, cadastro, sessão, itens do carrinho e checkout. Não há chamadas de API remota ainda; o estado reflete o SQLite e SharedPreferences.",
    ),
    p("Acesso a recursos nativos:", { bold: true }),
    p(
      "Câmera, GPS e notificações push não são utilizados neste MVP. O único recurso nativo relevante é o armazenamento SQLite no dispositivo (e SharedPreferences para o id da sessão). Demais recursos nativos constam como N/A.",
    ),
    h2("Tecnologias e ferramentas utilizadas"),
    p(
      "Stack Flutter: Material, ChangeNotifier (estado), sqflite / sqflite_common_ffi (persistência), SharedPreferences (sessão), crypto para PBKDF2-HMAC-SHA256. Ferramentas de ambiente: Flutter SDK (caminho sem espaços, ex.: C:\\flutter), Android Studio, Android SDK e AVD Pixel_6_API_35. Relatórios Word auxiliares são gerados com Node.js e o pacote docx em docs/.",
    ),
    spacer(80),
    table(widths, [
      headerRow(["Camada", "Responsabilidade"], widths),
      new TableRow({
        children: [
          cell("Apresentação", widths[0], { bold: true }),
          cell("features/: pages, widgets e navegação", widths[1]),
        ],
      }),
      new TableRow({
        children: [
          cell("Negócios", widths[0], { bold: true }),
          cell("Controllers ChangeNotifier (Auth, Cart) e regras em core/", widths[1]),
        ],
      }),
      new TableRow({
        children: [
          cell("Dados", widths[0], { bold: true }),
          cell("Repositórios + AppDatabase (SQLite) e modelos", widths[1]),
        ],
      }),
    ]),
  ];
}

function secaoJustificativa() {
  const widths = [2200, 3719, 3719];
  return [
    h1("3. Justificativa para a Escolha da Tecnologia"),
    h2("Comparação de tecnologias"),
    p(
      "Para um e-commerce acadêmico multiplataforma, a equipe comparou Flutter com desenvolvimento nativo (Kotlin no Android e Swift no iOS) e com React Native.",
    ),
    table(widths, [
      headerRow(["Opção", "Vantagens", "Limitações no contexto"], widths),
      new TableRow({
        cantSplit: true,
        children: [
          cell("Flutter", widths[0], { bold: true }),
          cell(
            "Um código para Android/iOS; UI consistente; boa produtividade; SQLite maduro; alinhado à stack do time.",
            widths[1],
          ),
          cell(
            "Exige toolchain Flutter/Android; plugins nativos sensíveis a caminho do SDK com espaços.",
            widths[2],
          ),
        ],
      }),
      new TableRow({
        cantSplit: true,
        children: [
          cell("Kotlin / Swift", widths[0], { bold: true }),
          cell(
            "Acesso direto a APIs nativas e desempenho máximo por plataforma.",
            widths[1],
          ),
          cell(
            "Dois códigos e duas equipes de UI; custo alto para o prazo acadêmico.",
            widths[2],
          ),
        ],
      }),
      new TableRow({
        cantSplit: true,
        children: [
          cell("React Native", widths[0], { bold: true }),
          cell(
            "Multiplataforma e ecossistema JavaScript conhecido.",
            widths[1],
          ),
          cell(
            "A equipe já estava em Dart/Flutter; trocar a stack atrasaria o MVP e a documentação de segurança.",
            widths[2],
          ),
        ],
      }),
    ]),
    spacer(120),
    p(
      "Considerações: desempenho é suficiente para catálogo e pedidos locais; a facilidade de desenvolvimento com hot reload e testes flutter_test acelerou o ciclo; a comunidade Flutter e a documentação oficial cobrem SQLite, Material e padrões de estado. A escolha prioriza entrega acadêmica cross-platform e continuidade da stack existente, não integração nativa avançada (câmera/GPS).",
    ),
  ];
}

function secaoDiagrama() {
  const widths = [2400, 7238];
  return [
    h1("4. Diagrama de Arquitetura"),
    p(
      "A arquitetura pode ser lida de cima para baixo: a interface (features) conversa com controllers ChangeNotifier; estes chamam repositórios; os repositórios persistem em SQLite (AppDatabase). Serviços de core (PasswordHasher, SessionStore, LoginThrottle) apoiam autenticação e segurança. Não há camada de recursos nativos de câmera/GPS neste MVP.",
    ),
    p(
      "Descrição textual no estilo Mermaid (flowchart TB): UI (Login/Cadastro, Catálogo, Carrinho, Pedidos) → State (AuthController, CartController) → Data (AuthRepository, CatalogRepository, CartRepository, OrderRepository) → SQLite AppDatabase; AuthController também usa SessionStore (SharedPreferences) e LoginThrottle; AuthRepository usa PasswordHasher.",
    ),
    spacer(40),
    mono("features/ (UI)"),
    mono("    ↓"),
    mono("ChangeNotifier (AuthController, CartController)"),
    mono("    ↓"),
    mono("data/repositories (Auth, Catalog, Cart, Order)"),
    mono("    ↓"),
    mono("SQLite AppDatabase  +  SharedPreferences (sessão)"),
    spacer(120),
    table(widths, [
      headerRow(["Bloco", "Elementos"], widths),
      new TableRow({
        children: [
          cell("Interface", widths[0], { bold: true }),
          cell("Login, cadastro, catálogo, detalhe, carrinho, pedidos", widths[1]),
        ],
      }),
      new TableRow({
        children: [
          cell("Negócios", widths[0], { bold: true }),
          cell("AuthController, CartController, regras em core/", widths[1]),
        ],
      }),
      new TableRow({
        children: [
          cell("Dados", widths[0], { bold: true }),
          cell("Repositórios SQLite e modelos (users, products, cart, orders)", widths[1]),
        ],
      }),
      new TableRow({
        children: [
          cell("Nativos", widths[0], { bold: true }),
          cell("SQLite no dispositivo; câmera/GPS N/A", widths[1]),
        ],
      }),
    ]),
    spacer(120),
    p(
      "O diagrama Mermaid completo, a árvore de pastas e o detalhamento dos repositórios estão em docs/arquitetura.md no repositório do projeto.",
    ),
  ];
}

function secaoFluxoUsuario() {
  const widths = [1400, 8238];
  const passo = (n, texto) =>
    new TableRow({
      cantSplit: true,
      children: [
        cell(String(n), widths[0], {
          bold: true,
          fill: "EAF1F8",
          align: AlignmentType.CENTER,
        }),
        cell(texto, widths[1]),
      ],
    });

  return [
    h1("5. Fluxo do Usuário"),
    p(
      "Fluxo principal, da abertura do app até o acompanhamento do pedido. Os dados são capturados por formulários (login/cadastro) e gestos na UI (busca, filtro, adicionar ao carrinho, finalizar). As informações são apresentadas em listas e telas de detalhe lidas do SQLite local.",
    ),
    table(widths, [
      headerRow(["Etapa", "Descrição"], widths),
      passo(
        "1",
        "Login ou cadastro: na ausência de sessão, o AuthGate exibe login; o cliente pode criar conta (US-001) ou autenticar-se. Senha armazenada com PBKDF2; falhas genéricas; limite de tentativas (SEC-003).",
      ),
      passo(
        "2",
        "Catálogo: lista de produtos ativos; busca e filtro por categoria (US-009); toque abre o detalhe (nome, descrição, preço, disponibilidade).",
      ),
      passo(
        "3",
        "Carrinho: o cliente adiciona itens, ajusta quantidades e revisa o total no Carrinho local.",
      ),
      passo(
        "4",
        "Pedido: finalização gera o pedido no SQLite; o cliente consulta a lista e o detalhe somente dos próprios pedidos (US-006, US-007, SEC-001).",
      ),
    ]),
    spacer(120),
    p("Navegação resumida (fluxograma textual):", { bold: true }),
    mono("Abertura → AuthGate"),
    mono("  ├─ sem sessão → Login ⇄ Cadastro → (sucesso) → Home"),
    mono("  └─ com sessão → Home"),
    mono("Home → Catálogo (busca/filtro) → Detalhe → Carrinho → Pedido"),
    mono("Home → Meus pedidos (somente do usuário logado)"),
    spacer(80),
    p(
      "Capturas das telas principais estão em docs/evidencias/ (login, erro de login, catálogo, detalhe, cadastro, carrinho e pedido).",
    ),
  ];
}

function secaoConclusao() {
  return [
    h1("6. Conclusão"),
    h2("Desafios e considerações"),
    bullet(
      "Caminho do Flutter SDK com espaços (ex.: pasta do usuário “Vitor Aletto”): o build nativo do sqlite3 falhava até o SDK ser instalado em C:\\flutter, restrição documentada no README.",
    ),
    bullet(
      "Configuração do emulador Android (Android Studio, SDK, AVD, modo de desenvolvedor do Windows): por um período a validação dependeu só de flutter_test; em 05/11/2026 o fluxo foi validado no AVD Pixel_6_API_35.",
    ),
    bullet(
      "Ausência de API web: o backend Laravel do Multiplagier ainda não expõe autenticação/catálogo para o mobile; o app permanece 100% local via repositórios, o que adiou a sincronização remota.",
    ),
    h2("Melhorias futuras"),
    bullet(
      "Sincronização com a API do projeto web (login/catálogo/pedidos), substituindo ou complementando o SQLite local sem quebrar as interfaces de repositório.",
    ),
    bullet(
      "Expansão iOS e, se necessário, recursos nativos (notificações, deep links) quando o domínio exigir.",
    ),
    bullet(
      "Remoção do usuário demo de seed quando cadastro + API forem a única entrada de clientes.",
    ),
    spacer(80),
    p(
      `Documento gerado em ${DATA_DOC}. Repositório: ${REPO}. Detalhes de arquitetura: docs/arquitetura.md.`,
    ),
  ];
}

const doc = new Document({
  creator: "Equipe Multiplagier",
  title: "Documentação Final — Dispositivos Móveis — Multiplagier",
  description:
    "Documentação de projeto de software para dispositivos móveis (Flutter) — Multiplagier Mobile",
  styles: { default: { document: { run: { font: FONT, size: 22 } } } },
  sections: [
    {
      properties: {
        page: {
          size: { width: 11906, height: 16838 }, // A4
          margin: { top: 1134, bottom: 1134, left: 1134, right: 1134 },
        },
      },
      headers: {
        default: new Header({
          children: [
            new Paragraph({
              alignment: AlignmentType.RIGHT,
              children: [
                run("Multiplagier Mobile – Documentação Final (Dispositivos Móveis)", {
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
                run("Página ", { size: 16, color: "8A949E" }),
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
      children: [
        ...capa(),
        ...secaoIntroducao(),
        ...secaoArquitetura(),
        ...secaoJustificativa(),
        ...secaoDiagrama(),
        ...secaoFluxoUsuario(),
        ...secaoConclusao(),
      ],
    },
  ],
});

const out = new URL("./Documentacao_Final_Dispositivos_Moveis_Multiplagier.docx", import.meta.url);
fs.writeFileSync(out, await Packer.toBuffer(doc));
console.log("Gerado:", out.pathname);
