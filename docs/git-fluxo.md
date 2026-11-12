# Fluxo Git

Convenção de branches e commits do **Multiplagier Mobile**.

## Branches

```text
main  ←  estável (não recebe commits de trabalho nesta fase)
 │
 └── dev  ←  integração contínua do time
      │
      ├── feat/...
      ├── fix/...
      ├── imp/...
      ├── chore/...
      ├── refac/...
      └── docs/...
```

| Branch | Uso |
|--------|-----|
| `main` | Linha estável. **Não** recebe commits diretos de trabalho nesta fase. |
| `dev` | Integração; todo o desenvolvimento entra aqui. |
| Trabalho | Criadas a partir de `dev` e abrem PR **apenas** para `dev`. |

### Prefixos de branch de trabalho

| Prefixo | Quando usar |
|---------|-------------|
| `feat/` | Nova funcionalidade |
| `fix/` | Correção de bug |
| `imp/` | Melhoria de algo existente |
| `chore/` | Build, deps, tooling |
| `refac/` | Refatoração sem mudança de comportamento |
| `docs/` | Documentação e evidências |

Exemplo: `docs/readme-e-entregaveis-05-11`.

## Fluxo do dia a dia

1. Atualizar `dev`.
2. Criar branch a partir de `dev` com o prefixo adequado.
3. Commits atômicos (ver abaixo).
4. Abrir PR para `dev` (via `gh` se preferir).
5. Após merge, apagar a branch de trabalho.

`main` só avança quando o time decidir promover um conjunto estável a partir de `dev`.

## Commits atômicos

- **Uma preocupação por commit** (ex.: “filtro do catálogo”, não “filtro + README + seed”).
- Mensagem clara no imperativo / foco no *porquê* quando útil.
- Evitar misturar refactor amplo com feature na mesma alteração.
- Não incluir segredos (`.env`, credenciais).

### Exemplos

```text
feat: adiciona limite de tentativas de login (SEC-003)
fix: isola detalhe de pedido por userId (SEC-001)
docs: atualiza README e guia de instalação
test: cobre filtro de catálogo por categoria
```

## Comandos úteis

```bash
git checkout dev
git pull
git checkout -b feat/minha-feature

git status
git add <arquivos>
git commit -m "feat: descreve a mudança"

gh pr create --base dev
```

## Resumo

- Trabalho → branch a partir de `dev` → PR para `dev`.
- `main` permanece estável nesta fase.
- Commits pequenos e atômicos facilitam revisão e bisect.
