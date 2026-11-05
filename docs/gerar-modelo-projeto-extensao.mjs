// Gera docs/Modelo_Projeto_Extensao_Multiplagier_Mobile.docx
// Preenche a estrutura do Modelo_projeto.docx (FATEC — Projeto de Extensão).
// Uso: cd docs && npm install && npm run modelo:extensao
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
const MARGIN = 1134;
const CONTENT_WIDTH = PAGE.width - MARGIN * 2; // 9638

const BORDER = { style: BorderStyle.SINGLE, size: 4, color: "B8C2CC" };
const BORDERS = { top: BORDER, bottom: BORDER, left: BORDER, right: BORDER };

const REPO = "https://github.com/vitor-dandrea/multiplagier-mobile";

const equipe = [
  {
    nr: "01",
    nome: "Vitor Aletto",
    papel: "Tech Lead",
    email: "vitor.aletto@fatec.sp.gov.br",
    whatsapp: "[a preencher]",
  },
  {
    nr: "02",
    nome: "Marco Machado",
    papel: "Product Manager",
    email: "marco.machado@fatec.sp.gov.br",
    whatsapp: "[a preencher]",
  },
  {
    nr: "03",
    nome: "Mauro Junior",
    papel: "Team Member",
    email: "mauro.junior@fatec.sp.gov.br",
    whatsapp: "[a preencher]",
  },
];

function run(text, opts = {}) {
  return new TextRun({ text, font: FONT, size: opts.size ?? 22, ...opts });
}

function h1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 320, after: 140 },
    children: [run(text, { bold: true, size: 28, color: ACCENT })],
  });
}

function h2(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 220, after: 100 },
    children: [run(text, { bold: true, size: 24, color: ACCENT })],
  });
}

function p(text, opts = {}) {
  return new Paragraph({
    spacing: { after: opts.after ?? 100, line: 276 },
    alignment: opts.align ?? AlignmentType.JUSTIFIED,
    children: [run(text, opts)],
  });
}

function bullet(text) {
  return new Paragraph({
    spacing: { after: 70, line: 270 },
    indent: { left: 360, hanging: 240 },
    alignment: AlignmentType.JUSTIFIED,
    children: [run("• "), run(text)],
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
    verticalAlign: opts.valign,
    columnSpan: opts.columnSpan,
    children: paragraphs,
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

function kvTable(rows) {
  const widths = [2600, CONTENT_WIDTH - 2600];
  return table(
    widths,
    rows.map(
      ([k, v]) =>
        new TableRow({
          cantSplit: true,
          children: [
            cell(k, widths[0], { bold: true, fill: "EAF1F8", size: 20 }),
            cell(v, widths[1], { size: 20 }),
          ],
        }),
    ),
  );
}

function objetivoBox(texto) {
  const widths = [CONTENT_WIDTH];
  return table(widths, [
    new TableRow({
      children: [
        cell(
          [
            new Paragraph({
              spacing: { after: 40 },
              children: [run("Objetivo", { bold: true, size: 20, color: ACCENT })],
            }),
            new Paragraph({
              spacing: { after: 20, line: 260 },
              alignment: AlignmentType.JUSTIFIED,
              children: [run(texto, { size: 20 })],
            }),
          ],
          widths[0],
          { fill: "F5F8FB" },
        ),
      ],
    }),
  ]);
}

// ---------------------------------------------------------------------------
function capa() {
  return [
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 1200, after: 80 },
      children: [run("Fatec Mauá", { bold: true, size: 36, color: ACCENT })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { after: 400 },
      children: [
        run(
          "Curso Superior de Tecnologia em Desenvolvimento de Software Multiplataforma",
          { size: 22, color: MUTED },
        ),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 600, after: 120 },
      border: {
        bottom: { style: BorderStyle.SINGLE, size: 12, color: ACCENT, space: 8 },
      },
      children: [
        run("Projeto de Extensão Comunitária", {
          bold: true,
          size: 32,
          color: ACCENT,
        }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { after: 80 },
      children: [run("(Curricularização)", { size: 22, color: MUTED })],
    }),
    spacer(400),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { after: 200 },
      children: [
        run("Multiplagier Mobile — MVP de e-commerce acadêmico", {
          bold: true,
          size: 30,
          color: ACCENT,
        }),
      ],
    }),
    spacer(200),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { after: 60 },
      children: [run("Integrantes do Projeto:", { bold: true, size: 22 })],
    }),
    ...equipe.map((m) =>
      new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { after: 40 },
        children: [run(`${m.nome} (${m.papel})`, { size: 22 })],
      }),
    ),
    spacer(800),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { after: 40 },
      children: [run("Mauá", { size: 24 })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [run("2026/2", { size: 24, color: MUTED })],
    }),
    new Paragraph({ children: [new PageBreak()] }),
  ];
}

function sumario() {
  const itens = [
    ["1.", "Características do Projeto de Extensão"],
    ["2.", "Informações da Equipe de Trabalho"],
    ["3.", "Etapa 1 — Desenvolvimento de documentação de Programação Mobile II"],
    ["4.", "Etapa 2 — Documentação de Segurança no Desenvolvimento de Aplicações"],
    ["5.", "Etapa 3 — Documentação Laboratório de Desenvolvimento de Dispositivos Móveis"],
    [
      "6.",
      "Etapa 4 — Documentação e relato das ações e funções desempenhadas por cada integrante",
    ],
    ["7.", "Conclusão"],
  ];
  return [
    h1("Sumário"),
    ...itens.map(
      ([n, t]) =>
        new Paragraph({
          spacing: { after: 100, line: 276 },
          children: [run(`${n}  ${t}`, { size: 22 })],
        }),
    ),
    new Paragraph({ children: [new PageBreak()] }),
  ];
}

function secaoCaracteristicas() {
  return [
    h1("1. Características do Projeto de Extensão"),
    kvTable([
      [
        "Título",
        "Multiplagier Mobile — MVP de e-commerce acadêmico (5º semestre DSM).",
      ],
      [
        "Temática",
        "Projetos (extensão curricularizada).",
      ],
      [
        "Descrição",
        "Desenvolvimento de um MVP Flutter de e-commerce local (catálogo, conta, carrinho e pedidos), com persistência SQLite e práticas de segurança no desenvolvimento de aplicações. O app opera de forma independente enquanto a API do Multiplagier web não estiver disponível, mantendo repositórios atrás de interfaces para futura integração.",
      ],
      [
        "Objetivos",
        "Entregar um aplicativo mobile funcional e testado que permita ao cliente consultar produtos, criar conta, autenticar-se, montar um carrinho e registrar pedidos; aplicar controles de segurança (hash de senha, sessão mínima, autorização por dono, limite de tentativas e auditoria); documentar o processo nas disciplinas LDDM, Segurança e Programação Mobile II.",
      ],
      ["Carga horária", "Total: 240 horas/aula."],
      [
        "Público-alvo",
        "Clientes do Multiplagier (consumidores de eletrônicos e acessórios); uso acadêmico/demonstração com dados locais. Empresas, ONGs e entidades sociais podem ser beneficiadas pela transferência do conhecimento e do modelo de MVP.",
      ],
      [
        "Ações/Etapas de execução",
        "1) Documentar e implementar a interface Flutter (Mobile II); 2) Aplicar e documentar controles de segurança (Segurança); 3) Projetar, migrar e semear a base SQLite (LDDM); 4) Relatar papéis, habilidades e contribuições de cada integrante da equipe.",
      ],
      [
        "Entregas",
        "01 Documentações de software do MVP (relatórios de status/acompanhamento e este modelo); 01 Código-fonte em repositório online (GitHub); 01 Relatório de composição de equipe, funções, responsabilidades e relato de execução das tarefas.",
      ],
      [
        "Instrumentos e procedimentos de avaliação",
        "Aluno — trabalho em grupo, eficácia nas tarefas e entrega digital em relatório padronizado de atividade de extensão. Projeto — resultados obtidos, publicação no repositório online e documentação das evidências por disciplina.",
      ],
      [
        "Componente(s) curricular(es) envolvidos",
        "LDDM (80 horas/aula); Segurança no Desenvolvimento de Aplicações (80 horas/aula); Programação Mobile II (80 horas/aula).",
      ],
      [
        "Formas de evidência",
        "Entrega de relatório de atividade de extensão com os resultados em cada disciplina; repositório GitHub com histórico de commits e testes automatizados.",
      ],
    ]),
  ];
}

function secaoEquipe() {
  const widths = [700, 3800, 5138];
  const rows = equipe.map(
    (m) =>
      new TableRow({
        cantSplit: true,
        children: [
          cell(m.nr, widths[0], { bold: true, align: AlignmentType.CENTER }),
          cell(`${m.nome}\n(${m.papel})`, widths[1], { bold: true }),
          cell(
            [
              new Paragraph({
                spacing: { after: 40 },
                children: [
                  run("Email: ", { bold: true, size: 20 }),
                  run(m.email, { size: 20 }),
                ],
              }),
              new Paragraph({
                spacing: { after: 20 },
                children: [
                  run("WhatsApp: ", { bold: true, size: 20 }),
                  run(m.whatsapp, { size: 20 }),
                ],
              }),
            ],
            widths[2],
          ),
        ],
      }),
  );

  return [
    h1("2. Informações da Equipe de Trabalho"),
    spacer(40),
    kvTable([["Nome do Grupo", "Multiplagier"]]),
    spacer(160),
    table(widths, [
      new TableRow({
        tableHeader: true,
        children: [
          cell("Nr.", widths[0], {
            bold: true,
            fill: ACCENT,
            color: "FFFFFF",
            align: AlignmentType.CENTER,
          }),
          cell("Nome completo / papel", widths[1], {
            bold: true,
            fill: ACCENT,
            color: "FFFFFF",
          }),
          cell("Contatos", widths[2], {
            bold: true,
            fill: ACCENT,
            color: "FFFFFF",
          }),
        ],
      }),
      ...rows,
    ]),
    spacer(120),
    p(
      `Repositório de trabalho: ${REPO} (branches main/dev e features).`,
      { align: AlignmentType.LEFT },
    ),
  ];
}

function secaoEtapa1() {
  return [
    h1("3. Etapa 1 — Desenvolvimento de documentação de Programação Mobile II"),
    objetivoBox(
      "Documentar e implementar a interface Flutter do MVP: autenticação, cadastro, catálogo com busca/filtro, carrinho e pedidos, cobertos por testes de widget e de integração.",
    ),
    spacer(120),
    h2("3.1 Telas e fluxo de navegação"),
    p(
      "O aplicativo organiza o fluxo do cliente em camadas de features Flutter: login e cadastro (auth), lista e detalhe de produtos com busca e filtro por categoria (catálogo), carrinho local e histórico/criação de pedidos. A navegação parte da sessão restaurada; sem sessão válida o usuário permanece nas telas de autenticação.",
    ),
    h2("3.2 Interface Flutter (UI)"),
    bullet("Login: e-mail, senha, validação de campos e mensagem genérica de falha."),
    bullet("Cadastro (US-001): criação de conta com regras de senha e tratamento de e-mail duplicado."),
    bullet("Catálogo (US-003/US-004/US-009): lista de produtos ativos, detalhe, busca textual e filtro por categoria."),
    bullet("Carrinho: inclusão, alteração de quantidade e remoção de itens persistidos localmente."),
    bullet("Pedidos (US-006/US-007): finalização do carrinho e listagem apenas dos pedidos do usuário autenticado."),
    h2("3.3 Testes de widget e integração"),
    p(
      "As telas são verificadas com flutter_test (widget) e fluxos ponta a ponta com SQLite real. Critério de aceite da etapa: funcionalidade implementada e coberta por testes automatizados, além de flutter analyze sem alertas.",
    ),
    h2("3.4 Entregáveis da etapa"),
    bullet("Código das features de UI e controllers no repositório GitHub."),
    bullet("Evidências de tela (capturas) e relatórios de acompanhamento para o professor."),
    bullet("Documentação desta etapa no presente modelo de extensão."),
  ];
}

function secaoEtapa2() {
  return [
    h1("4. Etapa 2 — Documentação de Segurança no Desenvolvimento de Aplicações"),
    objetivoBox(
      "Aplicar e documentar controles de segurança no MVP mobile: armazenamento seguro de credenciais, sessão mínima, autorização por dono do recurso, limite de tentativas de login, validação de entrada e registro de eventos de segurança.",
    ),
    spacer(120),
    h2("4.1 Credenciais e sessão"),
    bullet(
      "Senhas armazenadas com PBKDF2-HMAC-SHA256 e salt por usuário; nunca em texto puro.",
    ),
    bullet(
      "Sessão persistida apenas com o identificador do usuário (session id only), sem token ou senha no armazenamento local.",
    ),
    h2("4.2 SEC-001 — Autorização por dono"),
    p(
      "Pedidos e operações sensíveis são filtrados pelo usuário autenticado. Um cliente só visualiza e manipula os próprios pedidos, reduzindo risco de acesso cruzado a dados de outros usuários no SQLite local.",
    ),
    h2("4.3 SEC-003 — Limite de tentativas de login"),
    p(
      "Regra de bloqueio temporário após falhas consecutivas de autenticação, com cobertura de testes. A propriedade da implementação e da verificação de SEC-003 fica com Mauro Junior, alinhada ao backlog de segurança.",
    ),
    h2("4.4 Validação de entrada e auditoria"),
    bullet("Validação de e-mail/senha e regras de input nas telas de auth e cadastro."),
    bullet(
      "Tabela/registro security_events para auditar eventos relevantes (falhas de login, bloqueios e demais sinais de segurança).",
    ),
    bullet("Mensagens de erro genéricas, sem revelar se o e-mail existe ou detalhes internos."),
  ];
}

function secaoEtapa3() {
  return [
    h1(
      "5. Etapa 3 — Documentação Laboratório de Desenvolvimento de Dispositivos Móveis",
    ),
    objetivoBox(
      "Projetar, modelar e implementar a base de dados persistente do MVP: schema SQLite versão 3, migrações, seed demonstrativo e tabelas de carrinho e pedidos.",
    ),
    spacer(120),
    h2("5.1 Schema SQLite v3"),
    p(
      "O AppDatabase mantém o schema na versão 3, com entidades de usuários, produtos, itens de carrinho, pedidos/itens de pedido e estruturas de apoio à segurança (por exemplo, eventos de auditoria). A modelagem prioriza integridade referencial e restrições UNIQUE onde aplicável (e-mail de usuário).",
    ),
    h2("5.2 Migrações"),
    p(
      "Evolução controlada do banco local via migrações versionadas, permitindo que instalações anteriores avancem para o schema v3 sem perda indevida de dados de demonstração. Cada incremento de versão documenta as tabelas e colunas introduzidas (carrinho, pedidos, security_events etc.).",
    ),
    h2("5.3 Seed"),
    p(
      "Seed inicial com usuário demo, produtos ativos/inativos e dados mínimos para exercitar catálogo, carrinho e pedidos em ambiente acadêmico. O seed é adequado à demonstração e aos testes; credenciais demo permanecem documentadas apenas enquanto o fluxo for local.",
    ),
    h2("5.4 Tabelas de carrinho e pedidos"),
    bullet("Carrinho: itens vinculados ao usuário, com quantidade e referência ao produto."),
    bullet(
      "Pedidos: cabeçalho e itens gerados a partir do carrinho, associados ao dono da sessão (base para SEC-001).",
    ),
    bullet("Testes de repositório/banco validam criação, listagem e isolamento por usuário."),
  ];
}

function secaoEtapa4() {
  return [
    h1(
      "6. Etapa 4 — Documentação e relato das ações e funções desempenhadas por cada integrante",
    ),
    objetivoBox(
      "Aplicar técnicas de gerenciamento de equipes a partir da análise das habilidades técnicas e humanas dos integrantes, registrando papéis, responsabilidades e o trabalho efetivamente realizado no MVP.",
    ),
    spacer(120),
    h2("6.1 Vitor Aletto — Tech Lead / implementação"),
    p(
      "Liderança técnica e implementação principal do MVP Flutter: configuração do projeto, camadas features/data/core, autenticação com PBKDF2, catálogo, cadastro, carrinho, pedidos, migrações SQLite, testes automatizados, execução em emulador Android e geração dos entregáveis de documentação técnica.",
    ),
    h2("6.2 Marco Machado — Product Manager"),
    p(
      "Gestão de produto e backlog: priorização das user stories, alinhamento de critérios de aceite e acompanhamento do escopo acadêmico. Pendente o alinhamento formal dos contratos de API com o time do Multiplagier web (autenticação/catálogo), necessário para a etapa futura de integração remota.",
    ),
    h2("6.3 Mauro Junior — Team Member (segurança)"),
    p(
      "Ownership de SEC-003 (limite de tentativas de login): definição/acompanhamento da regra, apoio à implementação e verificação por testes. Contribui também para a revisão dos controles SEC-001 e da documentação de segurança do projeto.",
    ),
    h2("6.4 Dinâmica da equipe"),
    p(
      "O grupo Multiplagier trabalha com fluxo Git (main/dev/feat), commits atômicos e pull requests. As decisões de escopo privilegiaram um MVP local testável, com interfaces de repositório preparadas para substituir o SQLite pela API quando ela estiver disponível.",
    ),
  ];
}

function secaoConclusao() {
  return [
    h1("7. Conclusão"),
    p(
      "O Projeto de Extensão Comunitária Multiplagier Mobile resultou em um MVP Flutter de e-commerce acadêmico operacional em ambiente local, com catálogo, conta, carrinho e pedidos, além de práticas de segurança aplicadas no desenvolvimento (PBKDF2, sessão mínima, SEC-001, SEC-003, validação de entrada e security_events).",
    ),
    p(
      "Entre os benefícios destacam-se a integração curricular entre Programação Mobile II, Segurança e LDDM (240 horas), a publicação do código e das evidências no GitHub e a formação da equipe em papéis complementares (implementação, produto e segurança).",
    ),
    p(
      "As principais dificuldades foram a ausência inicial de toolchain Android/emulador (posteriormente resolvida) e a indisponibilidade da API do projeto web, que mantém a integração remota como próximo passo. Ainda assim, a arquitetura por repositórios permite evoluir o MVP sem refazer a camada de interface.",
    ),
    p(
      "Como contribuição à comunidade acadêmica e potencial transferência a organizações interessadas, o projeto oferece um modelo concreto de MVP mobile seguro, documentado e testado — base para demonstrações, continuidade em semestres seguintes e eventual adoção por entidades que demandem um protótipo de comércio eletrônico mobile.",
    ),
  ];
}

const doc = new Document({
  creator: "Equipe Multiplagier",
  title: "Modelo de Projeto de Extensão – Multiplagier Mobile",
  description:
    "Projeto de Extensão Comunitária (Curricularização) — FATEC Mauá / DSM / 2026/2",
  styles: { default: { document: { run: { font: FONT, size: 22 } } } },
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
                run("Multiplagier Mobile – Projeto de Extensão", {
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
                run("FATEC Mauá  ·  2026/2  ·  Página ", {
                  size: 16,
                  color: "8A949E",
                }),
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
        ...sumario(),
        ...secaoCaracteristicas(),
        ...secaoEquipe(),
        ...secaoEtapa1(),
        ...secaoEtapa2(),
        ...secaoEtapa3(),
        ...secaoEtapa4(),
        ...secaoConclusao(),
      ],
    },
  ],
});

const out = new URL(
  "./Modelo_Projeto_Extensao_Multiplagier_Mobile.docx",
  import.meta.url,
);
fs.writeFileSync(out, await Packer.toBuffer(doc));
console.log("Gerado:", out.pathname);
