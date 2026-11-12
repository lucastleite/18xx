# Tasks — frost1831-refactor

## Contexto de Execução

- Repo: `/Users/lucas.leite/Personal-Studies/18xx`
- Linguagem: Ruby
- Testes: `bundle exec rspec spec/` (sem fixture específica para Frost 1831 — usar rspec geral e instanciação manual)
- Rubocop: `bundle exec rubocop lib/engine/game/g_frost1831/`
- Escopo: somente `lib/engine/game/g_frost1831/` e subdirectórios

---

## Item 1 — Centralizar `faction_tokens_available`

- [x] 1.1 Adicionar o método público `faction_tokens_available(faction)` em `game.rb` (antes de `faction_influence_limit`)
- [x] 1.2 Substituir o inline em `status_array` (game.rb) pelo método centralizado
- [x] 1.3 Substituir o guard inline em `available_favor_factions` (game.rb) pelo método centralizado
- [x] 1.4 Substituir o inline em `can_place_faction_token?` (step/track.rb) pelo método centralizado
- [x] 1.5 Verificar que nenhuma outra ocorrência do padrão `tokens.size - 1` / `share_price&.coordinates&.[](1)` existe no diretório do jogo
- [ ] 1.6 Rodar `bundle exec rspec spec/` e confirmar que passa

---

## Item 2 — Extrair `INFLUENCE_LIMITS`

- [ ] 2.1 Adicionar a constante `INFLUENCE_LIMITS` em `game.rb` logo após `FACTION_ROW`
- [ ] 2.2 Refatorar `faction_influence_limit` para usar `INFLUENCE_LIMITS[:faction][@phase.name]`
- [ ] 2.3 Refatorar `corporation_influence_limit` para usar `INFLUENCE_LIMITS[:corporation][@phase.name]`
- [ ] 2.4 Refatorar `phase_extra_data` para usar `INFLUENCE_LIMITS` em vez dos dois `case` literais
- [ ] 2.5 Verificar que os valores default (fallback `|| 6` e `|| 3`) estão corretos para fases desconhecidas
- [ ] 2.6 Rodar `bundle exec rspec spec/` e confirmar que passa

---

## Item 3 — Módulo `FavorDelegate`

- [ ] 3.1 Criar o arquivo `lib/engine/game/g_frost1831/step/favor_delegate.rb` com o módulo `Engine::Game::GFrost1831::Step::FavorDelegate` contendo `actions`, `process_choose` e `blocking_for_entity?`
- [ ] 3.2 Adicionar `require_relative 'step/favor_delegate'` em `game.rb`
- [ ] 3.3 Em `step/route.rb`: adicionar `require_relative '../step/favor_delegate'`, incluir `include FavorDelegate` e remover os três métodos duplicados
- [ ] 3.4 Em `step/dividend.rb`: idem — incluir módulo e remover `actions` (guard FAV), `process_choose`, mas **manter** o restante de `actions` próprio (lógica de factions e `share_price_change`). Atenção: o `actions` de dividend tem lógica própria além do guard FAV; o módulo cuida apenas do guard, e a classe mantém o `super` para o restante
- [ ] 3.5 Em `step/track.rb`: incluir `FavorDelegate`; remover apenas o `process_choose` duplicado (os outros dois métodos na classe têm lógica própria e continuam corretos via `super`)
- [ ] 3.6 Em `step/buy_train.rb`: incluir `FavorDelegate`; remover o guard FAV do `actions` da classe (o módulo o absorve); manter o `process_choose` completo pois ele trata diamond além de FAV — ajustar para que o early-return para FAV venha do módulo via `super` ou reordenar a lógica interna
- [ ] 3.7 Rodar `bundle exec rspec spec/` e confirmar que passa

---

## Item 4 — Unificar `faction_display_name`

- [ ] 4.1 Em `step/special_choose.rb`: substituir todas as chamadas a `faction_name(sym)` por `@game.faction_display_name(sym)`
- [ ] 4.2 Em `step/special_choose.rb`: remover o método privado `faction_name`
- [ ] 4.3 Em `step/pre_turmoil_influence.rb`: substituir todas as chamadas a `faction_name(sym)` por `@game.faction_display_name(sym)`
- [ ] 4.4 Em `step/pre_turmoil_influence.rb`: remover o método privado `faction_name`
- [ ] 4.5 Rodar `bundle exec rspec spec/` e confirmar que passa

---

## Item 5 — Estado de fim de jogo como máquina de estados

- [ ] 5.1 Em `game.rb` (`setup`): adicionar `@end_game_state = :idle`; remover `@pre_turmoil_window` e `@end_game_turmoil_done`
- [ ] 5.2 Em `game.rb`: adicionar o método auxiliar `end_game_turmoil_window?` que retorna `@end_game_state == :waiting_influence`
- [ ] 5.3 Em `game.rb` (`attr_reader`): substituir `pre_turmoil_window` por `end_game_state`; manter `pre_turmoil_players` como attr_reader apontando para `@pre_turmoil_players` (hash de players_remaining movido para campo separado)
- [ ] 5.4 Em `game.rb` (`event_turmoil!`): substituir o bloco que seta `@pre_turmoil_window = { ... }` para setar `@end_game_state = :waiting_influence` e `@pre_turmoil_players = { players_remaining: players_with_influence.dup }`
- [ ] 5.5 Em `game.rb` (`end_game!`): substituir guard `unless @end_game_turmoil_done` e `return if @pre_turmoil_window` pela verificação de `@end_game_state`; ao terminar, setar `@end_game_state = :turmoil_done`
- [ ] 5.6 Em `game.rb` (`execute_pending_turmoil!`): substituir `@pre_turmoil_window = nil` por `@end_game_state = :turmoil_done`
- [ ] 5.7 Em `game.rb` (`finalize_intervention`): substituir `@pre_turmoil_window = nil` e `@end_game_turmoil_done = false` por `@end_game_state = :idle`
- [ ] 5.8 Em `step/pre_turmoil_influence.rb` (`actions` e `active?` e `blocking?`): substituir `@game.pre_turmoil_window` por `@game.end_game_turmoil_window?`
- [ ] 5.9 Em `step/pre_turmoil_influence.rb` (`current_player_with_influence` e `remove_player_from_window`): substituir acesso a `@game.pre_turmoil_window` pelo acesso ao novo `@game.pre_turmoil_players`
- [ ] 5.10 Verificar que nenhum outro arquivo referencia `pre_turmoil_window` diretamente
- [ ] 5.11 Rodar `bundle exec rspec spec/` e confirmar que passa

---

## Validação Final

- [ ] 6.1 Rodar `bundle exec rubocop lib/engine/game/g_frost1831/` e corrigir eventuais violations
- [ ] 6.2 Rodar `bundle exec rspec spec/` completo uma última vez e confirmar 0 falhas
- [ ] 6.3 Verificar que nenhum arquivo em `assets/` foi modificado
