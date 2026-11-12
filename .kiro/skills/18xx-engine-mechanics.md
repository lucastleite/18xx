---
name: 18xx Engine Mechanics
description: Understanding how the 18xx.games engine, rounds, steps, and UI work together
inclusion: auto
---

# 18xx Engine Mechanics

## How it works

- **One engine, two runtimes.** `lib/engine` runs as MRI Ruby on the server and in specs, and is compiled to JavaScript by Opal to run in the browser. Code must behave the same in both.

- **A game is a seed plus a list of actions.** Every load builds a fresh `Game` and replays all actions from the start. Any change that alters the outcome of a past action, or which actions are legal or required, breaks games in progress.

## Game Structure

Each title lives in `lib/engine/game/g_<title>/`:
- `meta.rb`: title, designer, player counts, optional rules (constants only)
- `entities.rb`: companies, corporations, minors (constants only)
- `map.rb`: hexes, tiles, location names (constants only)
- `game.rb`: `class Game < Game::Base` (or subclass of another title)
- `round/`, `step/`: title-specific subclasses

`Game::Base#next_round!` drives the sequence: `init_round` → `stock_round` → `operating_round` (N times per phase) → back to stock.

## Round

Holds an ordered list of steps and decides which entities act and in what order. `Round#process_action` gives each action to the first active step that lists its type in `actions(entity)`.

## Step

Declares action types an entity may take with `actions(entity)`, handles each in `process_<type>`, and ends with `pass!`. Steps with nothing to do are skipped automatically.

## UI

Opal + Snabberb components (`assets/app/view`) read `round.active_step` and `round.actions_for(entity)` to decide which buttons, hexes and inputs to show.

## Ruby that runs in the browser (Opal gotchas)

- **Integer division:** In Opal, `Integer#/` is JavaScript float division (`7 / 2 == 3.5`). Write `(numerator.to_f / divisor).floor` or `.ceil`, never `.round`.
- **Emptiness checks:** Prefer `!array.empty?` over `array.any?`; `empty?` is much cheaper.

## Writing game code

- **Follow the rulebook.** Every rule should trace back to the title's rules; cite the rule in the PR when not obvious.
- **Use what the engine already has.** Look for existing mechanisms: company powers go in abilities (`lib/engine/ability/`), not special cases in game class.
- **No magic strings, no redundant constants.** Put fixed names/values in constants (`map.rb` and `entities.rb` hold only constants) and read them through a method so subclasses can override.
- **Use one name for each concept.** Use the rulebook's term and the same name across code, logs and UI.
- **Don't add code comments.** Make code clear through naming and structure.
- **Keep display in the views.** Engine exposes state; views in `assets/app/view` decide layout.
- **Check the blast radius of shared code.** When changing core engine code, find every title that depends on it and run their specs/fixtures. Tag PR `[core]`.

## Running tests

```bash
# Full suite
docker compose exec rack rake

# One spec file
docker compose exec rack rspec <path>

# One title's fixtures
docker compose exec rack rspec spec/lib/engine/game/fixtures_spec.rb -e '<title>'

# Lint
docker compose exec rack rubocop -a
```

## Breaking live games

If a change alters past action outcomes or which actions are legal/required, games in progress break. Try to repair with a migration script first. Label PR: `migration` (if migration needed), `pins` (if migration impossible), or `archive_alpha_games` (if alpha title).
