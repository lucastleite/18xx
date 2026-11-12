# Frost 1831 — Roteiro de PRs para o oficial

Fila de PRs na ordem em que vamos subir. Complementa o `UPSTREAM_CHECKLIST.md`
(que guarda as regras de curadoria e o que nunca sobe).

## Como usar

- Quando um PR for mergeado, mova a linha dele para "Já no oficial" e apague o bloco da fila.
- Cada bloco diz o que o PR contém, do que depende e o que precisa de cuidado.
- `(confirmar)` marca algo que eu li no código mas não validei rodando.
- Antes de extrair um PR, rodar `python3 scripts/audit_commit_order.py` e a validação do checklist.

## Já no oficial / em revisão

| PR | Conteúdo | Estado |
|----|----------|--------|
| #13009 | Operating round basics | Mergeado |
| #13033 | Marcador L→E | Mergeado |
| #13034 | Trens, fases e fim de jogo | Mergeado |
| #13042 | `[core]` seta forçada com `!` no mercado | Em revisão |
| #13043 | Mercado só com códigos do core + célula azul reivindicada | Em revisão |

## Fila

Ordem combinada. A facção como entidade (item 3) entra antes de todas as influências, como explicado em "Alertas de ordem".

### 1. Nevasca
- **Contém:** `event_blizzard!`, `BLIZZARD_SURVIVING_COLORS`, `on_corporation_eliminated`, `flush_pending_eliminations!`, `@pending_eliminations`, `@corporations_eliminated_count`.
- **Depende de:** nada de influência. Os ícones `blizzard` já estão no mapa do master.
- **Cuidado:**
  - O `PHASES` do master já dispara `blizzard`, e `phase.rb:26` faz `send("event_blizzard!")`. Como o método não existe no master, o primeiro trem 5 quebra hoje. Este PR conserta isso: vale dizer na descrição.
  - O evento lê `@influence_cubes_collected`, que é da influência no mapa. Tirar essa linha daqui e devolvê-la no item 5.
  - O master não tem `setup` no Frost. Este PR cria o `setup` só com as duas ivars acima.
  - Não achei chamada de `flush_pending_eliminations!` em `game.rb` (confirmar quem chama).

### 2. Auction round
- **Contém:** `new_auction_round`, step `BuyCert` (359 linhas), `init_round_finished`, e as privadas sem influência: Old Guard (`POG`, ramo do leilão em `after_buy_company`) e Grand Junction (`PGJ`, par forçado em `BuyCert`).
- **Cuidado:** `BuyCert` chama `@game.after_buy_company` depois de cada compra. Nesse PR o método só tem o ramo da Old Guard. O bloco da Convoy entra no item 4. Não achei outra referência a facção ou influência no `BuyCert`.

### 3. Facção como entidade e escolha ao flotar
- **Contém:** a facção como conceito, `ChooseFactions`, `float_corporation` (enfileira a escolha), `@faction_support_pool`, `on_corporation_floated`, `apply_faction_influence` só com o cubo na corporação, `corporation_influence_limit`, `status_array` da corporação, `ChooseInfluence`, `queue_influence_choice`, `resolve_influence_choice`.
- **Por que antes das influências:** ver "Alertas de ordem". Depois disso, cada fonte de influência (jogador, mapa, mercado, trem ◆) vai entrando sobre essa base.

### 4. Influência para jogador e Convoy
- **Contém:** `@player_influence`, `player_influence`, `player_influence_spend`, `player_card_rows` e a linha "Influence" no cartão do jogador (`view/game/player.rb`). Convoy (`PCO`) no `after_buy_company` (+1 para o jogador), companhia oculta `INF` (`create_influence_company`, exclusão em `num_certs`) e a parte do `SpecialChoose` que trata o `INF` (`process_inf`).
- **Por que juntos:** a Convoy é a única fonte de influência do jogador. Sem ela, o contador do jogador sobe sem nada que o incremente.
- **Cuidado:** `process_inf` tem dois destinos.
  - Para uma corporação (`add_corporation_influence`): funciona logo depois do item 3.
  - Direto para uma facção: exige ser presidente da facção e usa `faction_influence` e `faction_influence_limit`, que são do Parlamento. Esse ramo só funciona depois da arena (8) e das facções compráveis (9). Decidir: subir só o ramo da corporação aqui e completar depois, ou mover este item para depois do 9.
  - O gasto também aparece em `PreTurmoilInfluence`, que é da reviravolta (16).

### 5. Influência no mapa
- **Contém:** `after_lay_tile`, `NL_ROUTE_EDGES`, `edges_connected?`, `@influence_cubes_collected`.
- **Depende de:** 3. Os ícones `influence_cube` já estão no mapa do master.
- **Cuidado:** o ramo em que a facção recebe o cubo direto (`move_government`) fica de fora.

### 6. Zona de influência no mercado
- **Contém:** `check_influence_zone`, `sold_out_stock_movement`, `grant_market_influence`, o gancho no `log_share_price` e o `StockMarket` do Frost (`down` e `FACTION_ROW`).
- **Depende de:** 3, #13042 e #13043. Esses dois PRs de mercado já cobrem a célula azul (`claim_first_to_arrive_cell`).

### 7. Trem ◆
- **Contém:** `diamond_trains.rb` (115 linhas).
- **Cuidado:** a influência na compra do trem D (`grant_influence_for_d_purchase`) chama `execute_deferred_turmoil!`, que é de reviravolta. Proteger ou deixar essa linha para o item 16.

### 8. Arena
- **Contém:** `InfluenceArena` (375 linhas), `@government_marker`, `ParliamentMovement` (127), `move_government`, `faction_influence_gain/lose`, `government_neutral?`, `governing_faction_sym`, logos SVG das facções e `main.css`.
- **Cuidado:** `apply_faction_influence` ganha duas linhas (`faction_influence_gain` e `move_government`), e `ChooseFactions#extra_choice_components` passa a embutir a arena.

### 9. Facções (2 ou 3 PRs)
- **9b, entidades:** `FACTIONS`, `type: :faction`, certificados (`@faction_certificates`), compra e regra de oposição em `BuySellParShares`, Affiliate (`PAF`). Nota: o `no_market` só aparece na view do cartão (borda da linha IPO) e não precisa de atributo no `Corporation`.
- **Escolha de facção prioritária:** `ChoosePriorityFaction` (101 linhas), `@chosen_priority_faction`, `@chosen_or_priority_faction`, `all_factions_arena_order`, `factions_or_order`. Define a ordem de jogo das facções, então sobe junto com elas.
- **9c, operação das facções:** `FactionDividend`, bases (`place_faction_base`, `available_faction_cities`), gasto de fichas na coluna do mercado.

### 10. Regulação do mercado
- **Contém:** `@regulations` (R1 a R4), `apply_r3_limits`, view `market_regulation.rb` (93 linhas).
- **Cuidado:** o `setup` lê `tight_government?`, então a opção precisa estar no `meta.rb` quando isso subir.

### 11. Stock round
- **Contém:** `Round::Stock`, `BuySellParShares` (230), `corporations_to_move_price`, limite de certificados (`init_cert_limit`, `update_ownership_limit_for`).
- **Cuidado:** `finish_round` chama `trigger_priority_faction_choice!`, que depende de votação. Deixar essa parte para o item 12.

### 12. Votação (voting round)
- **Contém:** `Round::Voting`, `Vote` (201), view `round/voting.rb`, inserção em `next_round!`.

### 13. Intervenção
- **Contém:** `Intervention` (163), `trigger_intervention`, `intervention_faction_selector` (view e `lib/intervention_selector`), ganchos em `hex.rb` (`faction_options_for_hex`).

### 14. Favor
- **Contém:** `Favor` (109), a companhia oculta `FAV` e a parte de `SpecialChoose` que a trata, R4, view `round/favor.rb` (131), e as mudanças de `buy_company`, `buy_train` e `dividend` que reconhecem o `FAV`.

### 15. Operation round
- **Contém:** `Track` (241), `Token` (101), `Route` (32), `SpecialTrack` (36), `HomeToken` (26), view `round/operating.rb`, `@no_blocking_graph`, `Graph` com `home_as_token`.
- **Core:** `tile_lay_graph_for_entity` em `base.rb` e `tracker.rb`.

### 16. Reviravolta (turmoil)
- **Contém:** `Turmoil` (104), `PreTurmoilInfluence` (139), `event_turmoil!`, `execute_deferred_turmoil!`.

### 17. Regras opcionais
- **Contém:** `parliamentary_intervention` e `tight_government` no `meta.rb`.
- **Cuidado:** `ChooseFactions` já consulta `parliamentary_intervention?` e o `setup` consulta `tight_government?`. Se esses itens subirem antes, a opção precisa subir junto. `auto_second_faction` e `d_train_endgame` são legado e ficam só na Railway.

### 18. Spreadsheet
- **Core:** `spreadsheet_extra_headers`, `spreadsheet_extra_data`, `spreadsheet_extra_sort_value`, `companies_sort`, `phase_extra_headers`, `phase_extra_data`.
- **Contém:** colunas de favor e de facção na planilha.

### 19. Tela do parlamento
- **Contém:** view `parliament.rb` (71 linhas), `extra_game_tabs` em `base.rb` e `game_page.rb`.

## Alertas de ordem

1. **Influência precisa de facções antes (item 3).** Os itens 5, 6 e 7 terminam em `queue_influence_choice`, que pergunta qual das facções da corporação recebe o cubo. As facções da corporação só existem depois de `ChooseFactions` rodar no float, e `grant_market_influence` simplesmente retorna se a lista está vazia. Sem o item 3 antes, esses três PRs subiriam sem destino para o cubo.
2. **Influência do jogador só existe com a Convoy.** Por isso as duas estão juntas no item 4.
3. **O `setup` do master não existe.** Hoje o `setup` da `frost-final` mistura influência, parlamento, votação, intervenção e favor. Cada PR deve criar ou estender o `setup` só com as ivars que usa. Nunca copiar o `setup` inteiro.
4. **Reviravolta aparece dentro da influência.** `resolve_influence_choice` e o `buy_train` chamam `execute_deferred_turmoil!`. Esse trecho tem que ficar de fora até o item 16.

## Decisões tomadas

- Escolha de facção prioritária sobe com as facções (item 9).
- Convoy e influência do jogador sobem juntas, depois da facção como entidade (item 4).
- `INF` vem da Convoy e sobe com ela (item 4).
- `FAV` sobe com o favor (item 14).
- `SpecialChoose` é repartido: o `INF` no item 4, o Affiliate (`PAF`) com as facções (9) e o `FAV` no item 14.
- Old Guard e Grand Junction não dão influência e sobem com o leilão (item 2).
- O trem ◆ é o `diamond_trains.rb`.

## Pendências gerais

- **Fim de jogo pelo trem D** (`@d_train_bought`, `game_end_check_custom?`): parte já está no master via #13034, conferir o resto.
- **Specs:** hoje só existe o `game_spec.rb` do Frost. Cada PR precisa trazer o seu.

## Hooks de core

Cada um vai num PR `[core]` próprio, antes da feature que o usa.

| Hook | Arquivo | Usado por |
|------|---------|-----------|
| `spreadsheet_extra_*`, `phase_extra_*`, `companies_sort` | `lib/engine/game/base.rb`, `view/game/spreadsheet.rb`, `view/game/game_info.rb`, `view/game/corporation.rb` | 18 |
| `extra_game_tabs` | `lib/engine/game/base.rb`, `view/game_page.rb` | 19 |
| `tile_lay_graph_for_entity` | `lib/engine/game/base.rb`, `lib/engine/step/tracker.rb` | 15 |
| Seleção de facção no hex | `view/game/hex.rb`, `view/game/tile.rb`, `lib/intervention_selector.rb`, `view/game/intervention_faction_selector.rb` | 13 |
| Ícones de escolha e botões (confirmar o uso exato) | `view/game/choose.rb`, `view/game/buy_trains.rb` | 3, 14 |
| Fichas de facção e `token_label` | `view/game/corporation.rb` | 9b |

## Não sobe (ficam na `frost-final`)

- Infra da Railway e agentes, no commit `[dev] ... DO NOT UPSTREAM`.
- Endpoints sem auth de `api.rb` (`/enable/<id>` e `/auto-routing/<id>/<bool>`), no mesmo commit `[dev]`.
- `LICENSED_TITLES` e o parâmetro `force` em `view/create_game.rb`, que escondem os outros jogos na lista. Movidos para o commit `[dev]`.
- Legado: `d_train_endgame`, `auto_second_faction`.
- Este roteiro e o `UPSTREAM_CHECKLIST.md`.
- Antes de extrair, rebasear a `frost-final` no master atual. Hoje o diff mostra arquivos de 18Cuba, 1835 e `lib/bus.rb` só porque a branch está atrás.
