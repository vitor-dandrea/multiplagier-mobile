// Gera o relatório de acompanhamento (estilo entrega) de 05/11/2026.
// Uso: cd docs && npm install && npm run relatorio:05-11
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
  PageNumber,
} from "docx";

const DATA = "05/11/2026";
const REPO = "https://github.com/vitor-dandrea/multiplagier-mobile";
const TESTES_TOTAL = 120;
const FONT = "Calibri";
const PAGE = { width: 11906, height: 16838 };
const MARGIN_TOP = 720;
const MARGIN_BOTTOM = 680;
const MARGIN_SIDE = 780;
const CONTENT_WIDTH = PAGE.width - MARGIN_SIDE * 2;

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

const OUT =
  "./VitorAletto-MarcoMachado-MauroLuiz-Relatorio_Acompanhamento_05-11-2026.docx";

function run(text, opts = {}) {
  return new TextRun({ text, font: FONT, size: opts.size ?? 21, ...opts });
}

function h1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 200, after: 80 },
    children: [run(text, { bold: true, size: 26, color: "0F4C81" })],
  });
}

function p(text, opts = {}) {
  return new Paragraph({
    spacing: { after: opts.after ?? 60, line: 240 },
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
          spacing: { after: 20, line: 220 },
          alignment: opts.align ?? AlignmentType.LEFT,
          children: [
            run(c, {
              size: opts.size ?? 17,
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
    margins: { top: 40, bottom: 40, left: 70, right: 70 },
    children: paragraphs,
  });
}

function headerRow(labels, widths) {
  return new TableRow({
    tableHeader: true,
    cantSplit: true,
    children: labels.map((label, i) =>
      cell(label, widths[i], {
        bold: true,
        fill: "0F4C81",
        color: "FFFFFF",
        size: 17,
      }),
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

function acompanhamento() {
  const left = Math.floor(CONTENT_WIDTH / 2);
  const widths = [left, CONTENT_WIDTH - left];
  const shots = [
    [
      "03-catalogo.png",
      "Catálogo",
      "Catálogo com produtos ativos; busca e filtro por categoria (US-009) disponíveis.",
    ],
    [
      "07-pedido.png",
      "Pedido",
      "Pedido gravado localmente, com itens e total, visível só para o usuário logado.",
    ],
  ];

  const sitW = [2200, CONTENT_WIDTH - 2200];
  const blocos = [
    [
      "Concluído e em uso",
      STATUS_COLORS.Concluído,
      `Cadastro de cliente; carrinho local; pedidos com baixa de estoque e isolamento por usuário (SEC-001); limite de login SEC-003 (5 falhas / 1 min de bloqueio); busca e filtro por categoria do catálogo (US-009), concluídos e testados. Suíte: ${TESTES_TOTAL} testes. Emulador Android em uso (Pixel_6_API_35).`,
    ],
    [
      "Em desenvolvimento",
      STATUS_COLORS["Em andamento"],
      "Nenhuma funcionalidade está pela metade neste corte de 05/11.",
    ],
    [
      "Não iniciado",
      STATUS_COLORS["Não iniciado"],
      "Sincronização com a API do Multiplagier web (cadastro, catálogo, carrinho e pedidos ainda só no SQLite local).",
    ],
    [
      "Bloqueado",
      STATUS_COLORS.Bloqueado,
      "Integração com a API: o projeto web ainda não expõe os endpoints necessários para o mobile.",
    ],
  ];

  const diffW = [3200, CONTENT_WIDTH - 3200];
  const dificuldades = [
    [
      "Configuração do emulador Android (já resolvida).",
      "A instalação e o ajuste do ambiente Android tinham travado as capturas em aparelho. O emulador Pixel_6_API_35 está operacional e o app abre nele.",
    ],
    [
      "API do Multiplagier web indisponível.",
      "Conta, carrinho e pedidos seguem só no SQLite do app. A sincronização não começou. Continua o alinhamento com o time do web para os endpoints.",
    ],
  ];

  const nextW = [CONTENT_WIDTH - 3600, 2100, 1500];
  const proximos = [
    [
      "Alinhar com o web os endpoints de autenticação, catálogo e pedidos",
      "Marco Machado",
      "20/11/2026",
    ],
    [
      "Trocar os repositórios SQLite pela API quando ela existir",
      "Vitor e Marco",
      "depois da API",
    ],
    [
      "Polimento opcional de UX e evidências (se houver tempo)",
      "Equipe",
      "conforme agenda",
    ],
  ];

  return new Document({
    creator: "Equipe Multiplagier",
    title: "Relatório de acompanhamento – 05/11/2026 – Multiplagier Mobile",
    styles: { default: { document: { run: { font: FONT, size: 21 } } } },
    sections: [
      {
        properties: {
          page: {
            size: PAGE,
            margin: {
              top: MARGIN_TOP,
              bottom: MARGIN_BOTTOM,
              left: MARGIN_SIDE,
              right: MARGIN_SIDE,
            },
          },
        },
        footers: { default: footer("Relatório de acompanhamento") },
        children: [
          new Paragraph({
            spacing: { after: 20 },
            children: [
              run("Relatório de acompanhamento", {
                bold: true,
                size: 32,
                color: "0F4C81",
              }),
            ],
          }),
          new Paragraph({
            spacing: { after: 100 },
            border: {
              bottom: {
                style: BorderStyle.SINGLE,
                size: 10,
                color: "0F4C81",
                space: 1,
              },
            },
            children: [
              run(
                `Multiplagier Mobile  ·  ${DATA}  ·  ISG022, FATEC Mauá, 2026/2`,
                { size: 18, color: "5B6773" },
              ),
            ],
          }),
          h1("1. Identificação"),
          p(
            `Projeto: Multiplagier Mobile, aplicativo Flutter de e-commerce de eletrônicos. Turma: ISG022 – Segurança no Desenvolvimento de Aplicações, DSM, FATEC Mauá, 2026/2. Integrantes: ${integrantes.join("; ")}.`,
            { after: 40 },
          ),
          new Paragraph({
            spacing: { after: 60 },
            children: [
              run("Repositório: ", { size: 21 }),
              link(REPO, REPO),
              run(".", { size: 21 }),
            ],
          }),
          h1("2. Situação atual"),
          p(
            "O fluxo local de compra está fechado: cadastro, login com limite de tentativas, catálogo com busca e categoria, carrinho e pedidos. Tudo ainda no SQLite do aparelho. O emulador Android (Pixel_6_API_35) está em uso. A sincronização com a API do web não foi iniciada.",
            { after: 50 },
          ),
          table(sitW, [
            ...blocos.map(
              ([titulo, fill, texto]) =>
                new TableRow({
                  cantSplit: true,
                  children: [
                    cell(titulo, sitW[0], { bold: true, fill }),
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
            "Duas evidências do estado atual: catálogo (com US-009) e um pedido gravado. Capturas em docs/evidencias.",
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
                  size: 15,
                }),
              ),
            }),
          ]),
        ],
      },
    ],
  });
}

const out = new URL(OUT, import.meta.url);
fs.writeFileSync(out, await Packer.toBuffer(acompanhamento()));
console.log("Gerado:", out.pathname);
