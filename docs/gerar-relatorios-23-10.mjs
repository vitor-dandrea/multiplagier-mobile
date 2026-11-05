// Gera a continuação do relatório de status e o relatório de acompanhamento
// da atividade de 23/10/2026. Não altera o docx de 02/10/2026.
// Uso: cd docs && npm install && npm run relatorio:23-10
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
} from "docx";

const DATA = "23/10/2026";
const REPO = "https://github.com/vitor-dandrea/multiplagier-mobile";
const BRANCH = "feat/cadastro-carrinho-pedidos";
const TESTES_TOTAL = 111;
const FONT = "Calibri";
const PAGE = { width: 11906, height: 16838 };
const MARGIN = 1000;
const CONTENT_WIDTH = PAGE.width - MARGIN * 2;

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
  Concluído: "D5F0DD",
  "Em andamento": "FFF2C6",
  "Não iniciado": "E6E9ED",
  Bloqueado: "F8D7D3",
};

const integrantes = [
  "Vitor Aletto (Tech Lead)",
  "Marco Machado (Product Manager)",
  "Mauro Junior (Team Member)",
];

function run(text, opts = {}) {
  return new TextRun({ text, font: FONT, size: opts.size ?? 21, ...opts });
}

function h1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 280, after: 100 },
    children: [run(text, { bold: true, size: 28, color: "0F4C81" })],
  });
}

function p(text, opts = {}) {
  return new Paragraph({
    spacing: { after: opts.after ?? 80, line: 260 },
    alignment: opts.align ?? AlignmentType.JUSTIFIED,
    children: [run(text, opts)],
  });
}

function link(text, url) {
  return new ExternalHyperlink({
    link: url,
    children: [run(text, { color: "0F4C81", underline: {} })],
  });
}

function cell(content, width, opts = {}) {
  const paragraphs = (Array.isArray(content) ? content : [content]).map((c) =>
    typeof c === "string"
      ? new Paragraph({
          spacing: { after: 20, line: 240 },
          alignment: opts.align ?? AlignmentType.LEFT,
          children: [
            run(c, {
              size: opts.size ?? 18,
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
    margins: { top: 50, bottom: 50, left: 80, right: 80 },
    children: paragraphs,
  });
}

function headerRow(labels, widths) {
  return new TableRow({
    tableHeader: true,
    cantSplit: true,
    children: labels.map((label, i) =>
      cell(label, widths[i], { bold: true, fill: "0F4C81", color: "FFFFFF", size: 18 }),
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

function png(name, title, description, width, height) {
  return new ImageRun({
    type: "png",
    data: fs.readFileSync(new URL(`./evidencias/${name}`, import.meta.url)),
    transformation: { width, height },
    altText: { title, description, name },
  });
}

function footer(label) {
  return new Footer({
    children: [
      new Paragraph({
        alignment: AlignmentType.CENTER,
        children: [
          run(`${label}  ·  Página `, { size: 16, color: "8A949E" }),
          new TextRun({
            children: [PageNumber.CURRENT],
            font: FONT,
            size: 16,
            color: "8A949E",
          }),
        ],
      }),
    ],
  });
}

function statusTable(items) {
  const widths = [2500, 1400, CONTENT_WIDTH - 2500 - 1400 - 1700, 1700];
  const rows = items.map(
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
  return table(widths, [
    headerRow(["Funcionalidade", "Status", "Situação real", "Responsável"], widths),
    ...rows,
  ]);
}

const funcionalidades = [
  {
    nome: "Configuração inicial, login e catálogo",
    status: "Concluído",
    detalhe:
      "Já no relatório de 02/10. Continua funcionando: seed, login com hash, sessão só com o id do usuário, logout, lista e detalhe de produtos ativos.",
    resp: "Vitor Aletto",
  },
  {
    nome: "Cadastro de cliente (US-001)",
    status: "Concluído",
    detalhe:
      "Tela Criar conta, validação de nome, e-mail e senha (8 a 128 caracteres, letra e número), e-mail duplicado recusado e senha só como hash. Depois do cadastro a sessão entra no catálogo. Papel fixo de cliente.",
    resp: "Vitor Aletto",
  },
  {
    nome: "Carrinho local",
    status: "Concluído",
    detalhe:
      "Um carrinho por usuário no SQLite. A quantidade não passa do estoque; produto inativo ou sem estoque é recusado. O carrinho permanece depois do logout.",
    resp: "Vitor Aletto",
  },
  {
    nome: "Pedidos (US-006, US-007, SEC-001)",
    status: "Concluído",
    detalhe:
      "Finalizar pedido grava o pedido, o preço e o nome do item e baixa o estoque na mesma transação. A lista mostra só os pedidos da pessoa logada. Pedido de outra pessoa responde “Pedido não encontrado” e gera um evento de segurança sem dados do item.",
    resp: "Vitor Aletto",
  },
  {
    nome: "Limite de tentativas de login (SEC-003)",
    status: "Não iniciado",
    detalhe:
      "Prazo interno de 16/10 não foi cumprido. A regra de tentativas e o tempo de bloqueio ainda não foram definidos nem implementados.",
    resp: "Mauro Junior",
  },
  {
    nome: "Busca e filtro do catálogo (US-009)",
    status: "Não iniciado",
    detalhe: "Fora do incremento desta data. A lista continua só com os produtos ativos, em ordem de nome.",
    resp: "A definir",
  },
  {
    nome: "Emulador ou celular Android",
    status: "Bloqueado",
    detalhe:
      "O app ainda não foi aberto em emulador ou aparelho: o ambiente não tem Android toolchain nem Visual Studio. As capturas são renderização do app por flutter_test.",
    resp: "Vitor Aletto",
  },
  {
    nome: "API do Multiplagier web",
    status: "Bloqueado",
    detalhe:
      "O Laravel ainda não expõe API para o mobile. Cadastro, carrinho e pedidos estão atrás de repositórios, então a origem pode ser trocada depois.",
    resp: "Vitor Aletto e Marco Machado",
  },
];

function continuacao() {
  const shots = [
    ["05-cadastro.png", "Cadastro", "Tela Criar conta, com nome, e-mail, senha e confirmação."],
    ["03-catalogo.png", "Catálogo", "Lista após o login, com atalhos de pedidos e carrinho."],
    ["06-carrinho.png", "Carrinho", "Smart TV no carrinho, com total e finalizar pedido."],
    ["07-pedido.png", "Pedido", "Pedido #1 pendente, gravado em 23/10/2026."],
  ];
  const col = Math.floor(CONTENT_WIDTH / shots.length);
  const widths = shots.map(() => col);
  const imagens = new TableRow({
    cantSplit: true,
    children: shots.map(([file, title, description]) =>
      cell(
        [
          new Paragraph({
            alignment: AlignmentType.CENTER,
            children: [png(file, title, description, 118, 236)],
          }),
        ],
        col,
        { borders: NO_BORDERS },
      ),
    ),
  });
  const legendas = new TableRow({
    children: shots.map(([, title]) =>
      cell(title, col, { borders: NO_BORDERS, align: AlignmentType.CENTER, bold: true, size: 16 }),
    ),
  });

  const diffW = [2800, 3600, CONTENT_WIDTH - 6400];
  const dificuldades = [
    [
      "Sem Android toolchain e sem Visual Studio",
      "O app não foi executado em emulador. As imagens deste relatório não são prints de aparelho.",
      "Instalar o Android Studio e substituir as capturas. Enquanto isso, a verificação é por testes.",
    ],
    [
      "API do web ainda indisponível",
      "Cadastro, carrinho e pedidos existem só no SQLite do aparelho. Não há sincronização.",
      "Manter os repositórios e alinhar com o time do web os endpoints de autenticação, catálogo e pedidos.",
    ],
    [
      "SEC-003 atrasado",
      "O login ainda aceita tentativas ilimitadas. A senha de demonstração continua no README, de propósito, para a conta semeada.",
      "Mauro Junior define a regra de bloqueio e implementa o limite. A conta demo sai quando o cadastro for a única entrada.",
    ],
  ];

  const nextW = [CONTENT_WIDTH - 3400, 1900, 1500];
  const proximos = [
    ["Instalar emulador Android e trocar as capturas por prints do app em execução", "Vitor Aletto", "06/11/2026"],
    ["Limite de tentativas de login (SEC-003), com testes", "Mauro Junior", "06/11/2026"],
    ["Alinhar com o web os endpoints de autenticação, catálogo e pedidos", "Marco Machado", "06/11/2026"],
    ["Trocar os repositórios SQLite pela API quando ela existir", "Vitor Aletto e Marco Machado", "20/11/2026"],
  ];

  const count = (s) => funcionalidades.filter((f) => f.status === s).length;

  return new Document({
    creator: "Equipe Multiplagier",
    title: "Relatório de Status – Multiplagier Mobile – 23/10/2026",
    styles: { default: { document: { run: { font: FONT, size: 21 } } } },
    sections: [
      {
        properties: { page: { size: PAGE, margin: { top: MARGIN, bottom: MARGIN, left: MARGIN, right: MARGIN } } },
        headers: {
          default: new Header({
            children: [
              new Paragraph({
                alignment: AlignmentType.RIGHT,
                children: [run("Continuação do relatório de 02/10/2026", { size: 16, color: "8A949E" })],
              }),
            ],
          }),
        },
        footers: { default: footer("Multiplagier Mobile") },
        children: [
          new Paragraph({
            spacing: { after: 40 },
            children: [run("Relatório de status — continuação", { size: 20, color: "5B6773" })],
          }),
          new Paragraph({
            spacing: { after: 40 },
            children: [run("Multiplagier Mobile", { bold: true, size: 44, color: "0F4C81" })],
          }),
          new Paragraph({
            spacing: { after: 160 },
            border: { bottom: { style: BorderStyle.SINGLE, size: 12, color: "0F4C81", space: 4 } },
            children: [run(`ISG022 | FATEC Mauá | 2026/2 | ${DATA}`, { size: 20, color: "5B6773" })],
          }),
          p(
            "Este documento continua o relatório de 02/10/2026 (docs/Relatorio_Status_Multiplagier_Mobile.docx), que registrou configuração inicial, login e catálogo. Aquele arquivo foi mantido como estava. O que mudou desde então é o fluxo de compra local: cadastro, carrinho e pedidos.",
          ),
          h1("1. Identificação"),
          p(
            `Projeto: Multiplagier Mobile. Turma: ISG022 – Segurança no Desenvolvimento de Aplicações, DSM, FATEC Mauá, 2026/2. Integrantes: ${integrantes.join("; ")}.`,
          ),
          new Paragraph({
            spacing: { after: 80 },
            children: [
              run("Repositório: ", { size: 21 }),
              link(REPO, REPO),
              run(`. Trabalho desta continuação na branch local ${BRANCH}, ainda sem pull request para dev.`, { size: 21 }),
            ],
          }),
          h1("2. Situação atual"),
          p(
            `Nenhum item está em desenvolvimento neste corte. ${count("Concluído")} itens estão concluídos e cobertos por testes, ${count("Não iniciado")} não foram iniciados e ${count("Bloqueado")} seguem bloqueados. A suíte flutter test passou com ${TESTES_TOTAL} testes (repositório, widget e fluxo de compra com SQLite). flutter analyze não apontou problemas. O app não foi executado em emulador ou celular.`,
          ),
          statusTable(funcionalidades),
          h1("3. Evidências"),
          p(
            "As quatro telas abaixo foram geradas de novo em 23/10, renderizando o aplicativo com SQLite real (tool/screenshots/capture_screens_test.dart). Também foram atualizados os arquivos 01-login, 02-login-erro e 04-detalhe em docs/evidencias. O Word de 02/10 guarda as imagens antigas dentro do próprio arquivo e não muda com essa atualização.",
          ),
          table(widths, [imagens, legendas]),
          h1("4. Dificuldades"),
          table(diffW, [
            headerRow(["Problema", "Efeito", "O que a equipe está fazendo"], diffW),
            ...dificuldades.map(
              (d) =>
                new TableRow({
                  cantSplit: true,
                  children: d.map((text, i) => cell(text, diffW[i], { bold: i === 0 })),
                }),
            ),
          ]),
          h1("5. Próximos passos"),
          table(nextW, [
            headerRow(["Tarefa", "Responsável", "Previsão"], nextW),
            ...proximos.map(
              (s) =>
                new TableRow({
                  cantSplit: true,
                  children: s.map((text, i) => cell(text, nextW[i])),
                }),
            ),
          ]),
          p(
            "Em relação ao cronograma proposto em 02/10: o emulador (09/10) e o limite de login (16/10) atrasaram e continuam em aberto. O cadastro, previsto para 16/10, ficou pronto em 23/10. O carrinho saiu na data prevista (23/10) e os pedidos, previstos para 30/10, ficaram prontos antes. A API continua bloqueada pelo backend web.",
            { after: 40 },
          ),
        ],
      },
    ],
  });
}

function acompanhamento() {
  const left = Math.floor(CONTENT_WIDTH / 2);
  const widths = [left, CONTENT_WIDTH - left];
  const shots = [
    ["03-catalogo.png", "Catálogo", "Catálogo do Cliente Demo, com produtos ativos, preços e os botões de pedidos e carrinho."],
    ["07-pedido.png", "Pedido concluído", "Pedido #1, pendente, da Smart TV 50\" 4K, no valor de R$ 2.499,00."],
  ];

  const sitW = [2200, CONTENT_WIDTH - 2200];
  const blocos = [
    [
      "Concluído e em uso",
      "Login, logout e sessão; catálogo (lista e detalhe); cadastro de cliente; carrinho por usuário; pedido com baixa de estoque e lista só dos próprios pedidos. Coberto por 111 testes automatizados.",
    ],
    [
      "Em desenvolvimento",
      "Nenhuma tela ou funcionalidade está pela metade neste corte de 23/10.",
    ],
    [
      "Não iniciado",
      "Limite de tentativas de login (SEC-003) e busca/filtro do catálogo (US-009).",
    ],
    [
      "Bloqueado",
      "Abrir o app em emulador ou celular Android, e sincronizar com a API do Multiplagier web.",
    ],
  ];

  const diffW = [3200, CONTENT_WIDTH - 3200];
  const dificuldades = [
    [
      "O computador não tem Android toolchain nem Visual Studio.",
      "O aplicativo não foi aberto em emulador. As duas imagens são a tela real do Flutter, gerada por teste. Vitor Aletto vai instalar o Android Studio para obter prints de aparelho.",
    ],
    [
      "O projeto web ainda não oferece API.",
      "Conta, carrinho e pedidos ficam no SQLite do app. Os repositórios já separam a tela do banco, para a troca pela API quando Marco Machado alinhar os endpoints com o web.",
    ],
    [
      "O limite de tentativas de login atrasou.",
      "O prazo interno era 16/10 e a regra ainda não existe. Mauro Junior vai definir quantas tentativas bloqueiam o login e implementar isso com testes.",
    ],
  ];

  const nextW = [CONTENT_WIDTH - 3600, 2100, 1500];
  const proximos = [
    ["Emulador Android e capturas do app em execução", "Vitor Aletto", "06/11/2026"],
    ["Limite de tentativas de login (SEC-003)", "Mauro Junior", "06/11/2026"],
    ["Combinar os endpoints com o time do web", "Marco Machado", "06/11/2026"],
    ["Passar cadastro, catálogo e pedidos para a API", "Vitor e Marco", "20/11/2026"],
  ];

  return new Document({
    creator: "Equipe Multiplagier",
    title: "Relatório de acompanhamento – 23/10/2026 – Multiplagier Mobile",
    styles: { default: { document: { run: { font: FONT, size: 21 } } } },
    sections: [
      {
        properties: {
          page: {
            size: PAGE,
            margin: { top: 720, bottom: 680, left: 780, right: 780 },
          },
        },
        footers: { default: footer("Relatório de acompanhamento") },
        children: [
          new Paragraph({
            spacing: { after: 20 },
            children: [run("Relatório de acompanhamento", { bold: true, size: 32, color: "0F4C81" })],
          }),
          new Paragraph({
            spacing: { after: 120 },
            border: { bottom: { style: BorderStyle.SINGLE, size: 10, color: "0F4C81", space: 1 } },
            children: [run(`Multiplagier Mobile  ·  ${DATA}  ·  ISG022, FATEC Mauá, 2026/2`, { size: 18, color: "5B6773" })],
          }),
          h1("1. Identificação"),
          p(
            `Projeto: Multiplagier Mobile, aplicativo Flutter de e-commerce de eletrônicos. Turma: ISG022 – Segurança no Desenvolvimento de Aplicações, DSM, FATEC Mauá, 2026/2. Integrantes: ${integrantes.join("; ")}.`,
            { after: 40 },
          ),
          h1("2. Situação atual"),
          p(
            "O cliente já consegue criar uma conta, entrar, ver o catálogo, montar um carrinho e concluir um pedido. Tudo isso funciona no SQLite do próprio aplicativo, sem a API do site. Cada pessoa vê somente os próprios pedidos.",
            { after: 60 },
          ),
          table(sitW, [
            ...blocos.map(
              ([titulo, texto]) =>
                new TableRow({
                  cantSplit: true,
                  children: [
                    cell(titulo, sitW[0], { bold: true, fill: "EAF1F8" }),
                    cell(texto, sitW[1]),
                  ],
                }),
            ),
          ]),
          h1("3. Dificuldades"),
          table(diffW, [
            ...dificuldades.map(
              ([problema, acao]) =>
                new TableRow({
                  cantSplit: true,
                  children: [
                    cell(problema, diffW[0], { bold: true }),
                    cell(acao, diffW[1]),
                  ],
                }),
            ),
          ]),
          h1("4. Próximos passos"),
          table(nextW, [
            headerRow(["Tarefa", "Responsável", "Previsão"], nextW),
            ...proximos.map(
              (s) =>
                new TableRow({
                  cantSplit: true,
                  children: s.map((text, i) => cell(text, nextW[i])),
                }),
            ),
          ]),
          h1("5. Capturas do estado atual"),
          p(
            "Catálogo já em uso e um pedido realmente gravado pelo aplicativo. As imagens não são de emulador.",
            { after: 40 },
          ),
          table(widths, [
            new TableRow({
              cantSplit: true,
              children: shots.map(([file, title, description]) =>
                cell(
                  [
                    new Paragraph({
                      alignment: AlignmentType.CENTER,
                      spacing: { after: 40 },
                      children: [png(file, title, description, 118, 236)],
                    }),
                  ],
                  left,
                  { borders: NO_BORDERS },
                ),
              ),
            }),
            new TableRow({
              children: shots.map(([, title, description]) =>
                cell(`${title}. ${description}`, left, {
                  borders: NO_BORDERS,
                  align: AlignmentType.CENTER,
                  size: 16,
                }),
              ),
            }),
          ]),
        ],
      },
    ],
  });
}

const arquivos = [
  ["./Relatorio_Status_Multiplagier_Mobile_23-10-2026.docx", continuacao()],
  ["./Relatorio_Acompanhamento_23-10-2026.docx", acompanhamento()],
];

for (const [nome, doc] of arquivos) {
  const out = new URL(nome, import.meta.url);
  fs.writeFileSync(out, await Packer.toBuffer(doc));
  console.log("Gerado:", out.pathname);
}
