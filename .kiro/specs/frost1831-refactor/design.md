# Design — frost1831-refactor

## Linguagem Detectada

Ruby (dominante no workspace: `.rb` em lib/, assets/, spec/).

## Visão Geral

Cinco refatorações independentes e ordenadas por tamanho crescente de risco. Cada uma pode ser aplicada e testada isoladamente. Nenhuma altera lógica de negócio — apenas reorganiza o código.

---

## Item 1 — Centralizar `faction_tokens_available`

### Problema

O cálculo de tokens disponíveis de uma fação está copiado em três lugares em `game.rb` e `step/track.rb`:

```ruby
tokens_total     = faction.tokens.size - 1
tokens_used      = faction.share_price&.coordinates&.[](1) || 0
tokens_available = [tokens_total - tokens_used, 0].max
```

### Solução

Adicionar o método público em `game.rb`:

```ruby
def faction_tokens_available(faction)
  tokens_total = faction.tokens.size - 1
  tokens_used  = faction.share_price&.coordinates&.[](1) || 0
  [tokens_total - tokens_used, 0].max
end
```

Substituir os três inline em:
- `status_array` (game.rb, linha ~733): usa `tokens_available` na saída de UI
- `available_favor_factions` (game.rb): guard `tokens_total - tokens_used > 0` → `faction_tokens_available(f) > 0`
- `can_place_faction_token?` (step/track.rb): guard `return false unless tokens_available.positive?`

Arquivos alterados: `game.rb`, `step/track.rb`.

---

## Item 2 — Extrair `INFLUENCE_LIMITS`

### Problema

Os valores numéricos de limites por fase aparecem três vezes:
- `faction_influence_limit` (case @phase.name → 6/6/6/8/8/10)
- `corporation_influence_limit` (case @phase.name → 3/4/4/5/5/5)
- `phase_extra_data` (case literal idêntico para ambos)

### Solução

Adicionar constante no início da classe `Game`:

```ruby
INFLUENCE_LIMITS = {
  faction:     { '2' => 6, '3' => 6, '4' => 6, '5' => 8, '6' => 8, 'D' => 10 },
  corporation: { '2' => 3, '3' => 4, '4' => 4, '5' => 5, '6' => 5, 'D' => 5  },
}.freeze
```

Refatorar os três métodos:

```ruby
def faction_influence_limit
  self.class::INFLUENCE_LIMITS[:faction][@phase.name] || 6
end

def corporation_influence_limit
  self.class::INFLUENCE_LIMITS[:corporation][@phase.name] || 3
end

def phase_extra_data(phase)
  corp_limit    = self.class::INFLUENCE_LIMITS[:corporation][phase[:name]] || 3
  parl_limit    = self.class::INFLUENCE_LIMITS[:faction][phase[:name]]    || 6
  [corp_limit.to_s, parl_limit.to_s]
end
```

Arquivo alterado: somente `game.rb`.

---

## Item 3 — Módulo `FavorDelegate`

### Problema

Os métodos de delegação para o step `SpecialChoose` quando a entidade é a companhia `FAV` estão copiados em `track.rb`, `route.rb`, `dividend.rb` e `buy_train.rb`.

### Solução

Criar `lib/engine/game/g_frost1831/step/favor_delegate.rb`:

```ruby
# frozen_string_literal: true

module Engine
  module Game
    module GFrost1831
      module Step
        module FavorDelegate
          def actions(entity)
            return %w[choose] if entity&.company? && entity.sym == 'FAV'

            super
          end

          def process_choose(action)
            return unless action.entity&.sym == 'FAV'

            special_choose = @round.steps.find { |s| s.is_a?(GFrost1831::Step::SpecialChoose) }
            special_choose&.process_choose_ability(action)
          end

          def blocking_for_entity?(entity)
            return false if entity&.company? && entity.sym == 'FAV'

            super
          end
        end
      end
    end
  end
end
```

**Integração por step:**

- `route.rb` e `dividend.rb`: `include FavorDelegate` e remoção direta dos três métodos (não têm lógica própria além do guard FAV).

- `track.rb`: O `actions` e o `blocking_for_entity?` têm lógica própria. A classe já sobrescreve esses métodos. O módulo é incluído e o `process_choose` duplicado é removido. Os outros dois métodos na classe continuam corretos pois chamam `super` ao final dos guards — o `include` posiciona o módulo na cadeia antes do `Engine::Step::Track`, então `super` do módulo alcança a engine, e o `super` da classe alcança o módulo (que por sua vez alcança o pai). Isso funciona corretamente.

  Verificação de composição para `track.rb`:
  ```
  GFrost1831::Step::Track → FavorDelegate → Engine::Step::Track
  ```
  - `actions`: se FAV → retorna `%w[choose]` (módulo). Se não FAV, a classe continua para sua própria lógica e eventualmente chama `super` que vai para o módulo — mas o módulo já descartou FAV, então vai para `Engine::Step::Track#actions`. ✓
  - `blocking_for_entity?`: se FAV → retorna `false` (módulo). A classe tem guard próprio e chama `super`, mas FAV já é tratado antes de chegar. ✓

- `buy_train.rb`: O `process_choose` existente trata FAV e diamond separadamente. O módulo **não** cobre `process_choose` aqui para evitar conflito. Apenas `actions` e `blocking_for_entity?` vêm do módulo (remover esses dois guards da classe e incluir o módulo).

  Na prática em `buy_train.rb` não existe `blocking_for_entity?` explícito — o módulo apenas acrescenta o guard. Em `actions`, o guard FAV é removido da classe, herdado do módulo.

**Arquivo novo:** `step/favor_delegate.rb`  
**Arquivos alterados:** `step/track.rb`, `step/route.rb`, `step/dividend.rb`, `step/buy_train.rb`, `game.rb` (adicionar `require_relative 'step/favor_delegate'`).

---

## Item 4 — Unificar `faction_display_name`

### Problema

O método `faction_name(sym)` em `step/special_choose.rb` e `step/pre_turmoil_influence.rb` são cópias exatas de `faction_display_name(sym)` em `game.rb`.

### Solução

- Em `step/special_choose.rb`: remover o método privado `faction_name` e substituir todas as chamadas por `@game.faction_display_name`.
- Em `step/pre_turmoil_influence.rb`: idem — remover `faction_name` e substituir chamadas por `@game.faction_display_name`.

`faction_display_name` em `game.rb` já é público, logo acessível via `@game`.

Arquivos alterados: `step/special_choose.rb`, `step/pre_turmoil_influence.rb`.

---

## Item 5 — Estado de fim de jogo como máquina de estados

### Problema

O fluxo de fim de jogo em `end_game!` e `execute_pending_turmoil!` é controlado por três variáveis distintas:
- `@end_game_turmoil_done` — booleano: turmoil final já executou?
- `@pre_turmoil_window` — hash ou nil: janela pré-turmoil está aberta?
- `@end_game_reason` — símbolo ou nil: qual foi a razão do fim de jogo?

Isso torna o fluxo difícil de ler e abre possibilidade de estados inconsistentes.

### Solução

Substituir as três flags por `@end_game_state` (Symbol) e `@end_game_reason` (mantido separado por ser informação distinta do estado).

**Máquina de estados:**

```
:idle → (end_game! chamado) → :waiting_influence
                           → :turmoil_done (se não há janela de influência)
:waiting_influence → (execute_pending_turmoil!) → :turmoil_done
:turmoil_done → (continue_end_game!) → jogo encerrado
```

**Mapeamento de estado → flags antigas:**

| Novo estado | `@pre_turmoil_window` | `@end_game_turmoil_done` |
|---|---|---|
| `:idle` | `nil` | `false` |
| `:waiting_influence` | `{ players_remaining: [...] }` | `false` |
| `:turmoil_done` | `nil` | `true` |

**Mudanças em `game.rb`:**

```ruby
# setup
@end_game_state  = :idle
@end_game_reason = nil
# remover @pre_turmoil_window e @end_game_turmoil_done

def end_game!(game_end_reason)
  return if @finished
  return if @end_game_state == :turmoil_done  # já processou

  @log << '-- Final Maintenance --'
  @end_game_reason = game_end_reason

  event_turmoil!
  return if @end_game_state == :waiting_influence  # parou para janela

  @end_game_state = :turmoil_done
  continue_end_game!
end

def execute_pending_turmoil!
  @end_game_state = :turmoil_done
  execute_turmoil_consequences!

  if @end_game_reason && !@finished
    continue_end_game!
  end
end

# event_turmoil!: onde antes setava @pre_turmoil_window = {...}
# → agora seta @end_game_state = :waiting_influence e mantém
#   players_remaining em @end_game_window_players (campo separado)

attr_reader :end_game_state, :end_game_reason
```

**Acesso externo ao dado da janela (substitui `pre_turmoil_window`):**

O step `pre_turmoil_influence.rb` acessa `@game.pre_turmoil_window` para obter `players_remaining`. Após a refatoração, ele acessa `@game.end_game_state == :waiting_influence` para saber se a janela está ativa, e `@game.pre_turmoil_players` (novo attr_reader) para a lista de jogadores.

Alternativamente (mais conservador): manter o hash `@pre_turmoil_window` para os dados dos jogadores mas controlá-lo pelo estado:

```ruby
def end_game_turmoil_window?
  @end_game_state == :waiting_influence
end
```

E em `pre_turmoil_influence.rb`: substituir `@game.pre_turmoil_window` por `@game.end_game_turmoil_window?` nos guards, e manter `@game.pre_turmoil_players` para a lista.

Esta abordagem é mais cirúrgica e reduz risco de quebrar coisas inesperadas.

**Arquivos alterados:** `game.rb`, `step/pre_turmoil_influence.rb`.

---

## Ordem de Implementação Recomendada

1. Item 4 (menor: 2 arquivos, troca de método)
2. Item 1 (médio: 2 arquivos, extração de método)
3. Item 2 (médio: 1 arquivo, extração de constante)
4. Item 3 (médio: 1 arquivo novo + 4 alterações)
5. Item 5 (maior risco: refatoração de máquina de estados)

Essa ordem permite validar cada passo com os testes antes de prosseguir.

---

## Verificação

Após cada item:
```bash
bundle exec rspec spec/lib/engine/game/g_frost1831
```
Todos os testes devem passar sem alteração de saída.
