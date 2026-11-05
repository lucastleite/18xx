K para indicar pagamento único# Frost 1831 — Checklist de Upstream

Documento vivo. Registra o que precisa ser ajustado em cada commit da
`frost-final` **antes** de ele virar PR no repo oficial (`tobymao/18xx`), e o
que **nunca** sobe pro oficial (fica só na Railway).

> Atualize este arquivo sempre que descobrir uma nova pendência, mergear um PR,
> ou mudar a estratégia. É a fonte da verdade do que falta fazer.

---

## Como trabalhamos (resumo do fluxo)

- Branch de trabalho / Railway: **`frost-final`** (mantém legado + infra; roda online).
- Cada feature vira **1 PR** no oficial: branch nova a partir de `origin/master`
  + `git cherry-pick <commit>` + push pro fork `lucastleite` + PR contra `tobymao:master`.
- Fixes pequenos de algo já mergeado vão como **PR separado** (não acumular no mesmo PR).
- Correção de review:
  - PR **sem** comentários/reviews → `git commit --amend` + `push --force-with-lease`.
  - PR **com** comentários/reviews → **commit novo** por cima (sem amend).
- **Nunca** fazer `amend`/force-push destrutivo no **repo oficial**. (A regra do amend acima
  vale só pra limpar um PR ainda não revisado na nossa branch de PR.)
- Antes de subir/atualizar um PR, reproduzir as 3 etapas da CI localmente via Docker:
  - `docker compose exec -T rack rubocop <arquivos>`
  - `docker compose exec -T rack bundle exec rspec spec/lib/engine/game/g_frost1831/`
  - `docker compose exec -T rack bundle exec rake compile_all`

---

## Regras de curadoria antes de virar PR

1. **Legado não sobe.** Qualquer opção/código que não aparece mais pra selecionar e
   só existe pra manter jogos antigos funcionando (ex.: `d_train_endgame?`) deve ser
   **removido do PR**. Esse código fica só na `frost-final`, agrupado com a infra da
   Railway, num commit cujo nome avisa que não sobe pro oficial e será removido depois.
2. **Infra da Railway não sobe.** Deploy/config/agent (ver commit `DO NOT UPSTREAM`).
3. **Sem duplicatas vindas de cherry-pick.** Se a `master` já ganhou uma constante
   num PR anterior, o cherry-pick pode duplicá-la (ex.: `TRAINS`, `EBUY_CAN_SELL_SHARES`).
   Remover a duplicata e manter a versão correta (a que tem a feature do PR).
4. **Um PR = uma feature.** Não misturar escopos (ex.: não trazer optional rules
   pra dentro do PR de trains).
5. **Sem comentários/código em PT-BR** no que sobe pro oficial.
6. **Nada de código que depende de commit posterior.** Antes de abrir cada PR, rodar
   `python3 scripts/audit_commit_order.py` e conferir se o commit usa método, constante
   ou `@ivar` que só é definido mais pra frente na pilha. A CI não pega isso (os specs
   não chegam ao fim de jogo nem exercitam a maioria das regras). Foi o que o Chris
   apontou no PR #13034 (`end_game!` chamando `event_turmoil!`, que ainda não existia).

---

## Pendências que NÃO sobem pro oficial (ficam na `frost-final` / Railway)

| Item | Onde está | Ação planejada |
|------|-----------|----------------|
| Infra Railway + config de agente | commit `2fc373304` `[dev] ... DO NOT UPSTREAM` | Fica só na `frost-final`. Nunca vira PR. Contém: `.appsec/`, `.kiro/`, `.claude/`, `Dockerfile*`, `NEXT-STEPS.md`, e alterações em `api.rb`/`config.ru`/`Rakefile`. |
| ⚠️ SEGURANÇA: `api.rb` ganha GET sem auth (`/enable/<id>`, `/auto-routing/<id>/<bool>`) | mesmo commit `2fc373304` | Só pode existir na Railway e atrás de auth antes de qualquer exposição. Jamais upstream. |
| `d_train_endgame?` (fim de jogo pelo 1º trem D) | definido no commit `optional rules` (`b8caab602`); removido do PR #13034 | Agrupar com a infra num commit marcado "não upstream / remover depois". |
| (adicionar conforme surgir) | | |

### Fontes de regra do agente (vivem na `frost-final`, baseadas no PR #12928 do crericha)

O conceito de "agente" que o Chris subiu é o **`AGENTS.md`** (PR #12928, expandido nos
commits `a6631bc8f` e `5f76f707f`). A partir dele criamos skills e steering:

| Arquivo | Onde | O que traz |
|---------|------|------------|
| `AGENTS.md` | commits `a6631bc8f` / `5f76f707f` | Guia do Chris: arquitetura da engine, gotchas do Opal (divisão inteira, `!empty?`>`any?`), sem constantes redundantes/magic strings, sem comentários no código, não duplicar mecânica, blast radius de código compartilhado, specs, labels de breaking games, regras de PR. |
| `.kiro/steering/pr-submission-guide.md` | `frost-final` (commit infra) | Guia de submissão de PR (ativo como steering). |
| `.kiro/skills/18xx-engine-mechanics.md` | `frost-final` (commit infra) | Skill de mecânicas da engine. |
| `.kiro/skills/game-actions.md` | `frost-final` (commit infra) | Skill de ações de jogo. |

> Acessar sem checkout: `git show 5f76f707f:AGENTS.md`, `git show frost-final:.kiro/steering/pr-submission-guide.md`, etc.
> O hook `.kiro/hooks/validate-pr-before-create.json` valida cada PR contra essas fontes antes de `gh pr create`.

### Frente pendente: agrupar legado + infra na `frost-final`
- [ ] Juntar o código legado (ex.: `d_train_endgame?`) com o commit de infra da Railway.
- [ ] Nome do commit deve avisar: não sobe pro oficial e será removido quando os
      jogos legados acabarem.
- [ ] Decidir: deixar no 1º commit (infra) ou num commit final dedicado.

---

## Status dos commits da `frost-final` → PR no oficial

Ordem = `git log --reverse origin/master..frost-final`. Atualize o status a cada merge.

| # | Commit | Feature | Status upstream |
|---|--------|---------|-----------------|
| 1 | `2fc373304` | `[dev]` Railway deploy + agent config | ❌ NÃO SOBE (infra) |
| 2 | `6b45cce51` | operating round basics | ✅ Mergeado (PR #13009) |
| 3 | `76d69bfbb` | E marker (L→E) fix | 🔵 PR aberto #13033 |
| 4 | `f4adcb301` | trains, train names, phases, game end | 🔵 PR aberto #13034 (legado removido) |
| 5 | `ca75bdce9` | custom stock market and influence zones | ⬜ Pendente |
| 6 | `583d737d5` | stock round and certificate limits | ⬜ Pendente |
| 7 | `0b0724d14` | buy/sell/par shares | ⬜ Pendente |
| 8 | `8bf68744c` | private companies: purchase rules and tile discounts | ⬜ Pendente |
| 9 | `bcaca94b2` | private company auction | ⬜ Pendente |
| 10 | `6d92bbd82` | factions: entities, setup and influence tracking | ⬜ Pendente |
| 11 | `56a960ed0` | faction bases: placement and connectivity | ⬜ Pendente |
| 12 | `91c748aa6` | faction tile laying with influence cost | ⬜ Pendente |
| 13 | `cd7304c90` | routes, revenue and border bonuses | ⬜ Pendente |
| 14 | `0fe27e16e` | faction dividends | ⬜ Pendente |
| 15 | `4ae1dcad2` | influence arena and spending choices | ⬜ Pendente |
| 16 | `b7f7f13b4` | parliament: voting round and regulations | ⬜ Pendente |
| 17 | `28a101276` | favor company | ⬜ Pendente |
| 18 | `5ec4a4a7e` | parliamentary intervention | ⬜ Pendente |
| 19 | `196819517` | turmoil | ⬜ Pendente |
| 20 | `3c86b81c0` | blizzard event | ⬜ Pendente |
| 21 | `0f544ee3d` | diamond trains | ⬜ Pendente |
| 22 | `b8caab602` | optional rules | ⬜ Pendente — contém legado `d_train_endgame?` a separar |
| 23 | `b421e8d4e` | views: player card, round headers, market regulation | ⬜ Pendente |
| 24 | `4767f1830` | setup and round flow | ⬜ Pendente |
| 25 | `ded9e4f3f` | `[core]` hooks for Frost 1831 | ⬜ Pendente |
| 26 | `10cbecf6e` | `[core]` shared view hooks | ⬜ Pendente |

> Os SHAs mudam quando a `frost-final` é rebaseada. Depois de um rebase, reconferir
> com `git log --oneline --reverse origin/master..frost-final`.

Legenda: ✅ mergeado · 🔵 PR aberto · ⬜ pendente · ❌ não sobe

---

## Histórico de ajustes feitos antes de subir (aprendizados)

- **PR #13009 (OR basics):** removido override redundante `can_ebuy_sell_shares?`;
  no lugar, `EBUY_CAN_SELL_SHARES = false` na classe do jogo (feedback do crericha).
- **PR #13034 (trains/phases):** CI quebrou com `NoMethodError: d_train_endgame?`
  (legado). Removida a chamada órfã (`game_end_check_values` → só `{ bank: :full_or }`)
  e as duplicatas de `TRAINS`/`EBUY_CAN_SELL_SHARES` trazidas pelo cherry-pick.

---

## PR #13034 (trens): trecho de fim de jogo removido

- Review do crericha: por que parte do fim de jogo virou outro método (`continue_end_game!`)?
- Causa: o override `end_game!` rodava o turmoil final e a transferência de influência, que
  são de outra feature. O método foi separado porque o `execute_pending_turmoil!` (turmoil)
  também o chama para retomar o fim de jogo depois da janela de influência.
- Correção no PR: commit novo `e9423deb4` removendo `end_game!` + `continue_end_game!`
  (a base já encerra o jogo e loga o placar). Push **pendente** (SSH `github-personal` negou a chave).
- Na `frost-final`: o commit de remoção ficou logo depois do commit de trens (posição 4) e o
  trecho voltou por amend no commit de turmoil. A árvore final ficou idêntica à anterior.
- Mensagem ao Chris: rascunhada, **não enviada** (enviar só depois do push).
- Sobras do mesmo tipo ainda no PR #13034, fora do que o Chris perguntou: `end_now?` com
  `@bank_broken_trigger`, `game_end_check_custom?`/`game_ending_description` com
  `@d_train_bought`/`@final_turn`, e `GAME_END_CHECK` com `custom`. Decidir se saem também.

---

## Auditoria de ordem dos commits (`scripts/audit_commit_order.py`)

Numeração atual da `frost-final` (o commit de remoção é o 4). Heurística textual: nomes
usados num commit e só definidos depois. `factions` aparece como falso positivo (variável local).

**1. Estado só inicializado no commit 24 (setup and round flow)**
`@faction_influence`, `@corporation_influence`, `@corporation_factions`, `@favors_used`,
`@favor_used_this_or`, `@regulations`, `@player_influence`, `@pending_faction_choices`,
`@influence_cubes_collected`, `@faction_support_reserve`. Lidos a partir do commit 10.
Nos commits 10 a 23 o jogo não consegue nem iniciar esse estado.

**2. Métodos básicos definidos em commit errado**
- `parliament_open?` fica no 22 (optional rules), mas é usado desde o 6. É estado do jogo, não regra opcional.
- `faction_display_name` fica no 23 (views), mas é usado nos commits 16, 19 e 21.

**3. Dependências para frente entre features**

| Commit | Usa, mas só existe depois |
|--------|---------------------------|
| 5 custom stock market | `corporation_factions` (10), `queue_influence_choice`, `within_influence_limit?` (15), `update_ownership_limit_for` (16) |
| 6 stock round | `all_factions_arena_order` (15), `government_neutral?`, `trigger_priority_faction_choice!` (16), `parliament_open?` (22) |
| 7 buy/sell/par | `faction_influence*`, `OPPOSITES` (10), `available_faction_cities` (11), `faction_share_price` (14), `move_government` (16) |
| 8 private companies | `current_voting_president`, `regulation_value` (16), `@influence_company` (17) |
| 10 factions | `faction_influence_limit` (11), `move_government`, `update_ownership_limit_for` (16), `auto_second_faction?` (22) |
| 12 faction tile laying | `queue_influence_choice` (15), `move_government` (16), `assign_favor_to_current_operator` (17) |
| 14 faction dividends | `faction_certificates` (18) |
| 15 influence arena | `governing_faction_sym` (16), `government_marker` (18), `execute_deferred_turmoil!` (19) |
| 16 parliament | `current_voting_regulation_id` (18) |
| 17 favor company | `trigger_intervention` (18) |
| 21 diamond trains | `d_train_endgame?` (22, legado) |

Conclusão: os commits de 5 a 23 não são independentes. O próximo PR (5, mercado) vai
repetir o problema do #13034 se subir como está.
