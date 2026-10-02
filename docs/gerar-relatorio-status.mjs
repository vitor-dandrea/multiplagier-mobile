// Gera docs/Relatorio_Status_Multiplagier_Mobile.docx
// Uso: cd docs && npm install && npm run relatorio
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
  ImageRun,
  ExternalHyperlink,
  Footer,
  Header,
  PageNumber,
  PageBreak,
} from "docx";

// ---------------------------------------------------------------------------
// Dados do relatório
// ---------------------------------------------------------------------------
const DATA_RELATORIO = "02/10/2026";
const REPO = "https://github.com/vitor-dandrea/multiplagier-mobile";
const TESTES_TOTAL = 55;

const integrantes = [
  "Vitor Aletto (Tech Lead)",
  "Marco Machado (Product Manager)",
  "Mauro Junior (Team Member)",
];

const funcionalidades = [
  {
    nome: "Configuração inicial (Flutter, estrutura em camadas, SQLite e seed)",
    status: "Concluído",
    detalhe:
      "Realizado: projeto Flutter (Android e Windows), AppDatabase com tabelas users e products, seed com usuário demo, 5 produtos ativos e 1 inativo, README e fluxo de branches main/dev. Verificado por 4 testes de banco. Falta: nada nesta etapa.",
    resp: "Vitor Aletto",
  },
  {
    nome: "Login local (US-002)",
    status: "Concluído",
    detalhe:
      "Realizado: tela de login com validação, autenticação contra o SQLite com senha em PBKDF2-HMAC-SHA256 + salt, mensagem genérica de falha, sessão persistida (somente o id do usuário), restauração de sessão e logout. Verificado por testes unitários, de widget e de fluxo ponta a ponta. Falta: limite de tentativas (item abaixo).",
    resp: "Vitor Aletto",
  },
  {
    nome: "Catálogo: lista de produtos (US-003)",
    status: "Concluído",
    detalhe:
      "Realizado: lista somente produtos ativos, ordenada por nome, com nome, preço e disponibilidade; estados de carregamento, vazio e erro (sem expor detalhes internos), com nova tentativa. Verificado por testes de repositório e de widget. Falta: busca/filtro por categoria (US-009, fora do escopo atual).",
    resp: "Vitor Aletto",
  },
  {
    nome: "Catálogo: detalhe do produto (US-004)",
    status: "Concluído",
    detalhe:
      "Realizado: tela com nome, descrição, preço e disponibilidade; produto inexistente ou inativo mostra “Produto não encontrado”. Verificado por testes de widget e do repositório. Falta: nada nesta etapa.",
    resp: "Vitor Aletto",
  },
  {
    nome: "Limite de tentativas de login (SEC-003)",
    status: "Não iniciado",
    detalhe:
      "Falta definir a regra (número de tentativas e tempo de bloqueio), implementar no AuthController e cobrir com testes.",
    resp: "Mauro Junior",
  },
  {
    nome: "Cadastro de cliente (US-001)",
    status: "Não iniciado",
    detalhe:
      "Falta a tela, a validação de campos e o tratamento de e-mail duplicado (o banco já impede duplicidade com UNIQUE e o hash de senha já está pronto).",
    resp: "Vitor Aletto",
  },
  {
    nome: "Carrinho local",
    status: "Não iniciado",
    detalhe:
      "Falta modelar a tabela de itens do carrinho, a tela e os testes. Critérios de aceite a refinar a partir do backlog do web.",
    resp: "Vitor Aletto e Marco Machado",
  },
  {
    nome: "Pedidos do cliente (US-006 e US-007)",
    status: "Não iniciado",
    detalhe:
      "Depende do carrinho. Falta criar o pedido, listar somente os pedidos do próprio usuário (SEC-001) e testar a regra de acesso.",
    resp: "Vitor Aletto e Mauro Junior",
  },
  {
    nome: "Execução em emulador ou dispositivo Android",
    status: "Bloqueado",
    detalhe:
      "O app ainda não foi executado em emulador/dispositivo: o ambiente não tem Android toolchain nem Visual Studio (Windows) instalados. Hoje a validação é feita por testes automatizados e por renderização das telas via flutter_test.",
    resp: "Vitor Aletto",
  },
  {
    nome: "Integração com API do Multiplagier web",
    status: "Bloqueado",
    detalhe:
      "O backend Laravel ainda está em estágio inicial e não expõe API de produtos ou autenticação para o mobile. Enquanto isso o app usa SQLite local atrás de interfaces (AuthRepository e CatalogRepository), o que permite trocar a origem dos dados depois.",
    resp: "Vitor Aletto e Marco Machado",
  },
];

const evidencias = [
  {
    arquivo: "01-login.png",
    titulo: "Evidência 1: tela de login",
    descricao: "Tela inicial exibida a quem não tem sessão.",
  },
  {
    arquivo: "02-login-erro.png",
    titulo: "Evidência 2: login recusado",
    descricao: "Senha incorreta gera mensagem genérica.",
  },
  {
    arquivo: "03-catalogo.png",
    titulo: "Evidência 3: catálogo",
    descricao: "Produtos ativos lidos do SQLite após o login.",
  },
  {
    arquivo: "04-detalhe.png",
    titulo: "Evidência 4: detalhe do produto",
    descricao: "Nome, preço, disponibilidade e descrição.",
  },
];

const dificuldades = [
  {
    problema: "Backend do web sem API disponível para o mobile",
    impacto:
      "A integração fica bloqueada; o app funciona apenas com dados locais (SQLite).",
    acao:
      "Manter o acesso a dados atrás de interfaces e alinhar com o time do web quais endpoints serão expostos (login via Sanctum e catálogo).",
  },
  {
    problema:
      "Ambiente sem Android toolchain e sem Visual Studio; modo de desenvolvedor do Windows desativado",
    impacto:
      "O app não foi executado em emulador ou dispositivo. As capturas de tela foram geradas por teste de widget (flutter_test), não por emulador.",
    acao:
      "Instalar o Android Studio e criar um emulador; substituir as capturas por prints do app em execução.",
  },
  {
    problema:
      "Build nativo do sqlite3 falhou com o Flutter SDK em caminho com espaço (C:\\Users\\Vitor Aletto)",
    impacto: "Os testes que usam SQLite não rodavam até o SDK ser movido.",
    acao:
      "Resolvido: SDK movido para C:\\flutter. A restrição foi documentada no README.",
  },
  {
    problema: "Segurança ainda parcial no mobile",
    impacto:
      "Não há limite de tentativas de login e a senha do usuário demo está documentada no README (dado de demonstração).",
    acao:
      "Implementar SEC-003 nas próximas etapas e remover o seed demo quando houver cadastro e API.",
  },
];

const proximosPassos = [
  {
    tarefa: "Executar o app em emulador Android e substituir as capturas por prints reais",
    resp: "Vitor Aletto",
    prazo: "09/10/2026",
  },
  {
    tarefa: "Limite de tentativas de login (SEC-003): regra, implementação e testes",
    resp: "Mauro Junior",
    prazo: "16/10/2026",
  },
  {
    tarefa: "Cadastro de cliente (US-001) com validação e testes",
    resp: "Vitor Aletto",
    prazo: "16/10/2026",
  },
  {
    tarefa: "Definir com o time do web os endpoints de autenticação e catálogo",
    resp: "Marco Machado",
    prazo: "16/10/2026",
  },
  {
    tarefa: "Carrinho local (tabela, tela e testes)",
    resp: "Vitor Aletto e Marco Machado",
    prazo: "23/10/2026",
  },
  {
    tarefa: "Pedidos do cliente com autorização por dono (US-006, US-007 e SEC-001)",
    resp: "Vitor Aletto e Mauro Junior",
    prazo: "30/10/2026",
  },
];

// ---------------------------------------------------------------------------
// Helpers de layout
// ---------------------------------------------------------------------------
const FONT = "Calibri";
const CONTENT_WIDTH = 9638; // A4 com margens de 2 cm, em DXA
const BORDER = { style: BorderStyle.SINGLE, size: 4, color: "B8C2CC" };
const BORDERS = { top: BORDER, bottom: BORDER, left: BORDER, right: BORDER };
const NO_BORDER = { style: BorderStyle.NONE, size: 0, color: "FFFFFF" };
const NO_BORDERS = {
  top: NO_BORDER,
  bottom: NO_BORDER,
  left: NO_BORDER,
  right: NO_BORDER,
};

const STATUS_COLORS = {
  "Concluído": "D5F0DD",
  "Em andamento": "FFF2C6",
  "Não iniciado": "E6E9ED",
  "Bloqueado": "F8D7D3",
};

function run(text, opts = {}) {
  return new TextRun({ text, font: FONT, size: opts.size ?? 22, ...opts });
}

function h1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 360, after: 160 },
    children: [run(text, { bold: true, size: 30, color: "0F4C81" })],
  });
}

function p(text, opts = {}) {
  return new Paragraph({
    spacing: { after: 120, line: 276 },
    alignment: opts.align ?? AlignmentType.LEFT,
    children: [run(text, opts)],
  });
}

function link(text, url) {
  return new ExternalHyperlink({
    link: url,
    children: [run(text, { color: "0F4C81", underline: {} })],
  });
}

function bullet(children) {
  return new Paragraph({
    spacing: { after: 80, line: 270 },
    indent: { left: 360, hanging: 240 },
    children: [run("• "), ...(Array.isArray(children) ? children : [run(children)])],
  });
}

function cell(content, width, opts = {}) {
  const paragraphs = (Array.isArray(content) ? content : [content]).map((c) =>
    typeof c === "string"
      ? new Paragraph({
          spacing: { after: 40, line: 252 },
          alignment: opts.align ?? AlignmentType.LEFT,
          children: [run(c, { size: opts.size ?? 20, bold: opts.bold, color: opts.color })],
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
    verticalAlign: opts.valign,
    children: paragraphs,
  });
}

function headerRow(labels, widths) {
  return new TableRow({
    tableHeader: true,
    cantSplit: true,
    children: labels.map((label, i) =>
      cell(label, widths[i], { bold: true, fill: "0F4C81", color: "FFFFFF" }),
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
// Seções
// ---------------------------------------------------------------------------
function secaoIdentificacao() {
  const widths = [2300, 7338];
  const kv = (k, v) =>
    new TableRow({
      children: [
        cell(k, widths[0], { bold: true, fill: "EAF1F8" }),
        cell(v, widths[1]),
      ],
    });

  return [
    h1("1. Identificação do projeto"),
    table(widths, [
      kv("Aplicativo", "Multiplagier Mobile (versão Flutter do Multiplagier)"),
      kv("Turma", "ISG022 – Segurança no Desenvolvimento de Aplicações, DSM, FATEC Mauá, 2026/2"),
      kv("Integrantes", integrantes),
      kv("Data do relatório", DATA_RELATORIO),
      new TableRow({
        children: [
          cell("Repositório", widths[0], { bold: true, fill: "EAF1F8" }),
          cell(
            [
              new Paragraph({
                spacing: { after: 40 },
                children: [link(REPO, REPO), run("  (branch de trabalho: dev)", { size: 20 })],
              }),
            ],
            widths[1],
          ),
        ],
      }),
    ]),
    spacer(),
    p(
      "Objetivo: oferecer ao cliente do Multiplagier, e-commerce de eletrônicos e acessórios, um aplicativo para consultar o catálogo de produtos pelo celular, com acesso protegido por login. Esta primeira etapa entrega o fluxo de login seguido do catálogo (lista e detalhe), com dados em SQLite local.",
      { align: AlignmentType.JUSTIFIED },
    ),
    p(
      "Público-alvo: consumidores de eletrônicos e acessórios (perfil Cliente do backlog do projeto web). O perfil Administrador não faz parte do escopo mobile atual.",
      { align: AlignmentType.JUSTIFIED },
    ),
  ];
}

function secaoSituacao() {
  const widths = [2300, 1300, 4438, 1600];
  const rows = funcionalidades.map(
    (f) =>
      new TableRow({
        cantSplit: true,
        children: [
          cell(f.nome, widths[0], { bold: true }),
          cell(f.status, widths[1], {
            bold: true,
            fill: STATUS_COLORS[f.status],
            align: AlignmentType.CENTER,
          }),
          cell(f.detalhe, widths[2]),
          cell(f.resp, widths[3]),
        ],
      }),
  );

  const total = funcionalidades.length;
  const count = (s) => funcionalidades.filter((f) => f.status === s).length;

  return [
    h1("2. Situação atual do desenvolvimento"),
    p(
      `Resumo: ${count("Concluído")} de ${total} itens concluídos, ${count("Em andamento")} em andamento, ${count("Não iniciado")} não iniciados e ${count("Bloqueado")} bloqueados. Um item só consta como concluído quando está implementado e verificado por testes automatizados (${TESTES_TOTAL} testes passando, flutter analyze sem alertas).`,
      { align: AlignmentType.JUSTIFIED },
    ),
    table(widths, [
      headerRow(
        ["Funcionalidade ou etapa", "Status atual", "O que já foi realizado e o que falta", "Responsável(is)"],
        widths,
      ),
      ...rows,
    ]),
  ];
}

function secaoEvidencias() {
  // 4 capturas lado a lado (proporção 1080x2160 = 1:2).
  const imgW = 128;
  const imgH = 256;
  const colW = Math.floor(CONTENT_WIDTH / evidencias.length);
  const widths = evidencias.map(() => colW);

  const imagens = new TableRow({
    cantSplit: true,
    children: evidencias.map((e, i) =>
      cell(
        [
          new Paragraph({
            alignment: AlignmentType.CENTER,
            spacing: { after: 60 },
            children: [
              new ImageRun({
                type: "png",
                data: fs.readFileSync(new URL(`./evidencias/${e.arquivo}`, import.meta.url)),
                transformation: { width: imgW, height: imgH },
                altText: { title: e.titulo, description: e.descricao, name: e.arquivo },
              }),
            ],
          }),
        ],
        widths[i],
        { borders: NO_BORDERS, align: AlignmentType.CENTER },
      ),
    ),
  });

  const legendas = new TableRow({
    children: evidencias.map((e, i) =>
      cell(e.titulo, widths[i], {
        borders: NO_BORDERS,
        align: AlignmentType.CENTER,
        bold: true,
        size: 17,
      }),
    ),
  });

  const tw = [2300, 5338, 2000];
  const detalhes = [
    ["Evidência 1: login", "Tela de entrada com e-mail e senha, validação de campos e botão de acesso.", "Funcionalidade implementada"],
    ["Evidência 2: login recusado", "Resposta a senha incorreta com a mensagem genérica “E-mail ou senha inválidos.”, sem revelar se o e-mail existe.", "Funcionalidade implementada"],
    ["Evidência 3: catálogo", "Lista dos 5 produtos ativos lidos do SQLite após o login; o produto inativo semeado não aparece.", "Funcionalidade implementada"],
    ["Evidência 4: detalhe", "Detalhe de um produto com nome, preço, disponibilidade e descrição.", "Funcionalidade implementada"],
    ["Repositório e histórico", "Código-fonte, commits atômicos e 4 pull requests (scaffold, login, catálogo e este relatório) integrados na branch dev.", "Registro do trabalho"],
    ["Resultado dos testes", `flutter test: ${TESTES_TOTAL} testes passando (34 unitários, 20 de widget e 1 de fluxo ponta a ponta com SQLite real); flutter analyze: sem problemas.`, "Verificação automatizada"],
  ];

  return [
    new Paragraph({ children: [new PageBreak()] }),
    h1("3. Evidências do progresso"),
    p(
      "Todas as telas abaixo correspondem a funcionalidades implementadas (não são protótipos). As imagens foram geradas renderizando o app real, com SQLite real, por um teste de widget (tool/screenshots/capture_screens_test.dart). Não são prints de emulador, pois o ambiente ainda não tem Android toolchain instalado (ver seção 4).",
      { align: AlignmentType.JUSTIFIED },
    ),
    table(widths, [imagens, legendas]),
    spacer(200),
    table(tw, [
      headerRow(["Evidência", "O que apresenta", "Natureza"], tw),
      ...detalhes.map(
        ([a, b, c]) =>
          new TableRow({
            cantSplit: true,
            children: [cell(a, tw[0], { bold: true }), cell(b, tw[1]), cell(c, tw[2])],
          }),
      ),
    ]),
    spacer(120),
    new Paragraph({
      spacing: { after: 80 },
      children: [
        run("Links: ", { bold: true }),
        link("repositório", REPO),
        run(" | "),
        link("histórico de commits (dev)", `${REPO}/commits/dev`),
        run(" | "),
        link("pull requests", `${REPO}/pulls?q=is%3Apr`),
      ],
    }),
  ];
}

function secaoDificuldades() {
  const widths = [2900, 3300, 3438];
  return [
    h1("4. Dificuldades e pendências"),
    table(widths, [
      headerRow(["Dificuldade", "Como afeta o andamento", "Ação da equipe"], widths),
      ...dificuldades.map(
        (d) =>
          new TableRow({
            cantSplit: true,
            children: [
              cell(d.problema, widths[0], { bold: true }),
              cell(d.impacto, widths[1]),
              cell(d.acao, widths[2]),
            ],
          }),
      ),
    ]),
    spacer(160),
    p("Apoio necessário dos professores:", { bold: true }),
    bullet(
      "Confirmar se o aplicativo mobile deve consumir a API do projeto web ou se, nesta fase, pode operar de forma independente com SQLite local.",
    ),
    bullet(
      "Confirmar se capturas geradas por teste de widget são aceitas como evidência enquanto o emulador Android não estiver configurado.",
    ),
  ];
}

function secaoProximosPassos() {
  const widths = [5638, 2300, 1700];
  return [
    h1("5. Próximos passos"),
    table(widths, [
      headerRow(["Tarefa", "Responsável(is)", "Prazo previsto"], widths),
      ...proximosPassos.map(
        (s) =>
          new TableRow({
            cantSplit: true,
            children: [cell(s.tarefa, widths[0]), cell(s.resp, widths[1]), cell(s.prazo, widths[2])],
          }),
      ),
    ]),
    spacer(160),
    p("Situação em relação ao cronograma:", { bold: true }),
    p(
      "O projeto está dentro do cronograma para o escopo definido nesta etapa (configuração inicial, login e catálogo, todos concluídos e testados). Não há atraso a justificar. Os dois itens bloqueados (execução em emulador e integração com a API) não impedem o avanço das demais tarefas, mas são os principais riscos: o primeiro depende de configurar o ambiente e o segundo depende de o backend web disponibilizar a API. Os prazos acima são propostos pela equipe, pois o backlog ainda não traz datas para a versão mobile.",
      { align: AlignmentType.JUSTIFIED },
    ),
  ];
}

// ---------------------------------------------------------------------------
// Documento
// ---------------------------------------------------------------------------
const capa = [
  new Paragraph({
    spacing: { after: 60 },
    children: [run("Relatório de Status do Projeto Interdisciplinar", { size: 20, color: "5B6773" })],
  }),
  new Paragraph({
    spacing: { after: 80 },
    children: [run("Multiplagier Mobile", { bold: true, size: 52, color: "0F4C81" })],
  }),
  new Paragraph({
    spacing: { after: 200 },
    border: { bottom: { style: BorderStyle.SINGLE, size: 12, color: "0F4C81", space: 6 } },
    children: [run(`ISG022 | FATEC Mauá | 2026/2 | ${DATA_RELATORIO}`, { size: 22, color: "5B6773" })],
  }),
];

const doc = new Document({
  creator: "Equipe Multiplagier",
  title: "Relatório de Status – Multiplagier Mobile",
  styles: { default: { document: { run: { font: FONT, size: 22 } } } },
  sections: [
    {
      properties: {
        page: {
          size: { width: 11906, height: 16838 },
          margin: { top: 1134, bottom: 1134, left: 1134, right: 1134 },
        },
      },
      headers: {
        default: new Header({
          children: [
            new Paragraph({
              alignment: AlignmentType.RIGHT,
              children: [run("Multiplagier Mobile – Relatório de Status", { size: 16, color: "8A949E" })],
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
                new TextRun({ children: [PageNumber.CURRENT], font: FONT, size: 16, color: "8A949E" }),
              ],
            }),
          ],
        }),
      },
      children: [
        ...capa,
        ...secaoIdentificacao(),
        ...secaoSituacao(),
        ...secaoEvidencias(),
        ...secaoDificuldades(),
        ...secaoProximosPassos(),
      ],
    },
  ],
});

const out = new URL("./Relatorio_Status_Multiplagier_Mobile.docx", import.meta.url);
fs.writeFileSync(out, await Packer.toBuffer(doc));
console.log("Gerado:", out.pathname);
