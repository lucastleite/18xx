# Requirements — frost1831-refactor

## Contexto

O jogo Frost 1831 é implementado sobre o engine 18xx em `lib/engine/game/g_frost1831/`. Esta refatoração é puramente interna: sem mudança de regras, sem mudança de comportamento observável pelo jogador. O objetivo é eliminar duplicações e melhorar a manutenibilidade antes de submeter o PR ao repositório oficial.

---

## Restrições Globais

- Nenhuma mudança de comportamento de jogo (saída dos testes deve ser idêntica).
- Nenhuma mudança em arquivos de view (`assets/`).
- Nenhuma adição de dependências externas.
- Todos os testes RSpec existentes devem continuar passando.
- Não tocar em `reachable_hexes` (tratado separadamente).
- Escopo limitado a `lib/engine/game/g_frost1831/` e seus subdirectórios.

---

## Requisitos Funcionais

### 1. Centralizar `faction_tokens_available`

**1.1** O cálculo de tokens disponíveis de uma fação (tokens totais menos tokens usados, mínimo zero) deve existir em exatamente um lugar: o método `faction_tokens_available(faction)` em `game.rb`.

**1.2** Toda ocorrência do seguinte padrão inline deve ser removida e substituída pela chamada ao método centralizado:
```ruby
tokens_total = faction.tokens.size - 1
tokens_used  = faction.share_price&.coordinates&.[](1) || 0
tokens_available = [tokens_total - tokens_used, 0].max
```

**1.3** Os locais afetados são: `status_array` em `game.rb`, o guard em `available_favor_factions` em `game.rb`, e o guard em `can_place_faction_token?` em `step/track.rb`.

**1.4** O comportamento deve ser idêntico ao atual em todos os três locais.

---

### 2. Extrair `INFLUENCE_LIMITS`

**2.1** As tabelas de limites de influência (por fase, para fação no Parlamento e para corporação no card) devem ser definidas como uma única constante `INFLUENCE_LIMITS` em `game.rb`, no formato:
```ruby
INFLUENCE_LIMITS = {
  faction:     { '2' => 6, '3' => 6, '4' => 6, '5' => 8, '6' => 8, 'D' => 10 },
  corporation: { '2' => 3, '3' => 4, '4' => 4, '5' => 5, '6' => 5, 'D' => 5  },
}.freeze
```

**2.2** Os métodos `faction_influence_limit`, `corporation_influence_limit` e `phase_extra_data` devem usar `INFLUENCE_LIMITS` como fonte única de verdade, eliminando os blocos `case @phase.name` duplicados.

**2.3** O comportamento deve ser idêntico ao atual para todas as fases.

---

### 3. Módulo `FavorDelegate`

**3.1** Deve ser criado o arquivo `lib/engine/game/g_frost1831/step/favor_delegate.rb` contendo um módulo `Engine::Game::GFrost1831::Step::FavorDelegate`.

**3.2** O módulo deve conter exatamente os seguintes métodos, que hoje estão duplicados nos 4 steps:
- `actions(entity)`: retorna `%w[choose]` quando `entity&.company? && entity.sym == 'FAV'`, caso contrário delega via `super`.
- `process_choose(action)`: retorna imediatamente quando `action.entity&.sym != 'FAV'`; caso contrário localiza o `SpecialChoose` no round e chama `process_choose_ability`.
- `blocking_for_entity?(entity)`: retorna `false` quando `entity&.company? && entity.sym == 'FAV'`, caso contrário delega via `super`.

**3.3** Os 4 steps `track.rb`, `route.rb`, `dividend.rb` e `buy_train.rb` devem incluir o módulo com `include FavorDelegate` e remover o código duplicado correspondente.

**3.4** Em `track.rb`, os métodos `actions` e `blocking_for_entity?` têm lógica própria além do guard FAV. O `include` deve ser feito de forma que a lógica existente continue funcionando, com o guard FAV tratado pelo módulo via `super` no método da classe.

**3.5** Em `buy_train.rb`, o `process_choose` existente trata tanto o caso FAV quanto o caso `diamond_`. O módulo deve cuidar apenas do early-return para `FAV`; a lógica de diamond permanece na classe.

**3.6** Comportamento idêntico ao atual para todos os 4 steps.

---

### 4. Unificar `faction_display_name`

**4.1** O método privado `faction_name(sym)` em `step/special_choose.rb` deve ser removido.

**4.2** Todas as chamadas a `faction_name(sym)` em `special_choose.rb` devem ser substituídas por `@game.faction_display_name(sym)`.

**4.3** O método `faction_display_name` em `game.rb` permanece como está (ele já é público e está correto).

**4.4** Comportamento idêntico ao atual em todas as exibições de nomes de fações.

---

### 5. Estado de fim de jogo como máquina de estados explícita

**5.1** As três flags booleanas/nil `@end_game_turmoil_done`, `@pre_turmoil_window` e `@end_game_reason` devem ser substituídas por uma única variável de estado `@end_game_state` com os seguintes valores possíveis:

| Símbolo | Significado |
|---|---|
| `:idle` | Nenhuma sequência de fim de jogo em andamento |
| `:waiting_influence` | Janela pré-turmoil aberta (jogadores podem alocar influência) |
| `:turmoil_done` | Turmoil final executado; aguardando `continue_end_game!` |

**5.2** A inicialização em `setup` deve definir `@end_game_state = :idle`.

**5.3** Os métodos `end_game!`, `execute_pending_turmoil!`, `continue_end_game!`, `event_turmoil!` e `execute_turmoil_consequences!` devem ser atualizados para usar `@end_game_state` em vez das três flags anteriores.

**5.4** `attr_reader :pre_turmoil_window` deve ser atualizado para `attr_reader :end_game_state`, e os acessores que dependem do valor de `pre_turmoil_window` devem verificar `@end_game_state == :waiting_influence`.

**5.5** Todos os locais que testam `@pre_turmoil_window` (em steps ou outros arquivos) devem ser atualizados para testar `@game.end_game_state == :waiting_influence` (ou `@end_game_state == :waiting_influence` quando em `game.rb`).

**5.6** Comportamento de fim de jogo idêntico ao atual.

---

## Requisitos Não-Funcionais

**NFR-1** Cada item de refatoração deve ser atômico (commit separado é recomendado, mas não obrigatório para a spec).

**NFR-2** O código resultante deve estar em conformidade com o `.rubocop.yml` existente no repositório.

**NFR-3** Nenhum arquivo de teste existente deve falhar após qualquer uma das alterações.
