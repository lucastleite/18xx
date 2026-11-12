# Frost 1831 - Proximos Passos

Documento de trabalho para levar o Frost 1831 ao upstream (tobymao/18xx) em PRs
pequenos e revisaveis. Resume o que ja foi feito no refactor "core-clean" e como
pretendemos fatiar o jogo em PRs.

## Contexto

Referencia: PR 12888 (18Africa) do ruwen.bussinger. O conselho do time no Slack
(Phil Campeau, KevinR) e: primeiro um PR com map, entities, meta e um `game.rb`
basico; depois os steps/regras em pedacos gerenciaveis. O 18Africa comecou como
`:prealpha` com um `game.rb` "data skeleton" usando os rounds padrao do engine.

Estrategia de branches:
- `feature/frost-1831` e a fonte da verdade viva. Todo trabalho evolutivo acontece aqui.
- As branches de PR (`frost-pr1`, `frost-pr2`, ...) so nascem quando formos separar
  para envio. Cada PR sai limpo a partir do master atualizado.
- Ajuste pedido em PR ja aprovado vai nos dois lugares (branch completa + branch do PR).
- Bug encontrado vira PR proprio e explicito, nunca escondido no meio de outra coisa.

## Fase 0: Refactor core-clean (FEITO nesta branch)

Objetivo: o core (engine e views genericas) nao deve conhecer o Frost. Tudo que e
especifico mora em `g_frost1831/`. Onde o core precisa de um ponto de extensao, ele
ganha um hook neutro (retorna nil/[]/default) e o filho preenche.

Commits (feature/frost-1831):
- Grupos A e F: documenta hooks neutros no `base.rb` (extra_game_tabs,
  spreadsheet_extra_*, phase_extra_*, tile_lay_graph_for_entity) e reverte um
  residuo cosmetico no `tracker.rb`.
- Grupo B: `choose.rb` deixa de referenciar views do Frost; o step expoe
  `extra_choice_components`. `market_regulation` vira namespaced.
- Grupo C: as views de operating e stock round do Frost passam a herdar das do core
  e sobrescrevem so os pontos especificos (influence choice, tabela de custo de
  faccao, intervention). `game_page` ganha `round_view(key, default)` extensivel.
- Bugfix Diggers/Explorers: tile_lay com `free: true, special: true` (lay de graça
  e sem conexao, como a descricao ja prometia). Nao e refactor, e bug de dado do jogo.
- Grupo D: `consume_unique_bonus` sai do core para `GFrost1831::StockMarket`.
- Grupo 14: remove do core todas as views de faccao (influence_arena,
  influence_choice, parliament, market_regulation, round/voting, round/favor).
  Voting e favor viram `View::Game::GFrost1831::Round::Voting` e `::Favor`.

Dividas conscientes (ficam no core por ora, com precedente/justificativa):
- Intervention selector em `hex.rb`/`map.rb` (2 linhas). O 1882 ja faz algo parecido
  com o TokenSelector. Se alguem reclamar, generalizamos o mecanismo de selector.
- `no_market` como atributo de `Corporation`. Segue o padrao de outros flags opcionais
  ja existentes (treasury_as_holding, always_market_price).
- Checks `favor_mode?`/`voting?` no `game_page` (via respond_to?, genericos).

Fora de qualquer PR upstream (infra self-host, so nesta branch):
- `config.ru` (Rack::Static), `routes/user.rb` (SKIP_TURNSTILE), `lib/bus.rb` (REDIS_URL).
  Remover essas mudancas quando criar as branches de PR.

## Fase 1: Fatiar os PRs

Ordem geral: subir primeiro o que e simples e dificil de reclamar (mapa, entidades,
trens), e deixar por ultimo o que e "esquisito" (privadas, influencia, faccao,
parlamento, intervencao). Modelo do 18Africa.

Esboco de PRs (ajustar tamanhos conforme formos montando):

- PR 1 - Data skeleton: `meta` (mudar DEV_STAGE para :prealpha), `entities`, `map`,
  `tiles`, logos e icones, e um `game.rb` LEAN com bank, caixa inicial, cert limit,
  market, phases, trains e rounds padrao do engine. Sem faccao, parlamento,
  influencia, intervencao. Objetivo: renderizar o mapa e rodar o fluxo basico.
  Investigar como o 18Africa garantiu que roda so com rounds default.

- PR 2 - Stock round / mercado: buy_sell_par_shares, buy_cert, stock_market custom.

- PR 3 - Track e tokens: track, token, special_track, tiles especiais, uso do
  tile_lay_graph_for_entity.

- PR 4 - Trains e dividendos: diamond_trains, buy_train, dividend, route.

- PR 5+ - As coisas "esquisitas" (por ultimo): faccoes (choose_factions,
  faction_dividend), influencia (choose_influence, pre_turmoil_influence),
  parlamento/votacao (vote, voting, parliament_movement), intervencao (intervention,
  turmoil, favor) e as views namespaced correspondentes.

- PR solto (feature de engine, independente do Frost): share_price com `hide_value`
  (prefixo `_`), `arrow` (sufixo `!dulrn`) e o tipo `K` (pays_unique_bonus). E
  generico o suficiente para outros jogos usarem; sobe sozinho como melhoria de engine.

## Observacoes de build/teste

- Testes e lint rodam via Docker: `docker compose exec rack rake` e `rubocop`.
- Arquivos do Frost (`g_frost1831/`) precisam de `rake compile_all` para o bundle
  `g_frost1831.js` (carregado sob demanda) ser regenerado no browser. `rake compile`
  sozinho so refaz main/server.
- `public/assets/` sao artefatos de build (gitignored), nao commitar.
- Nao existe ainda spec nem fixtures dedicados do frost1831. Vale criar junto do PR 1.
