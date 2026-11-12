# PR Submission Guide for 18xx.games

Always included steering for creating and submitting pull requests.

## Before Creating PR

1. **Branch from latest master** (`git checkout master && git pull origin master`)
2. **Run rubocop and full suite** (`docker compose exec rack rake`)
3. **One commit per PR** - clean, focused commits
4. **Test locally with Docker** before pushing

## PR Size and Scope

- **Split new titles into several reviewable PRs** (not one giant PR)
- Each PR should be **one feature or closely related features**
- Target **100-400 lines per PR** (can go up to 600-700 for complete round/phase)
- Examples of good PR scope:
  - Stock market + stock round (88-130 lines)
  - Buy/sell/par step (200-250 lines)
  - Operating round basics (400-500 lines)
  - One specific mechanic (60-200 lines)

## PR Title Format

- Start with title(s) affected: `[Frost 1831] ...`
- Use `[core]` for shared `lib/engine` changes
- Use `[dev]` for developer-only changes
- Be specific and descriptive

## PR Description Template

```markdown
Part N of [Game] implementation.

## Changes
- Feature 1 description
- Feature 2 description
- Feature 3 description

## Testing
- Rubocop passes locally (via Docker)
- XXX lines, Y files, 1 commit
- [If applicable] Specs pass, fixtures tested

## Related
- Builds on #XXXX (previous PR)
- [If applicable] Independent files, can be merged in parallel
```

## PR Labels

Use when applicable:
- `migration` - if migration script needed
- `pins` - if games will break without migration
- `archive_alpha_games` - if broken games are alpha title
- Title labels (e.g. `1889`, `18Chesapeake`, `frost_1831`)

## What to Verify in PR Description

Say what you verified:
- Specs passed
- Fixtures tested  
- Reproduced games tested
- Rubocop clean

Say what you didn't run and why (if applicable).

## Addressing Review Feedback

- **When reviewer gives specific code, use it as given**
- If you think it's wrong, say so and explain why instead of quietly writing something different
- **Change only what feedback asks for** - don't refactor or extend nearby code beyond the request

## Multiple Related PRs

When submitting multiple PRs for same title:
- Ensure they don't conflict (different files)
- Can be reviewed/merged in parallel
- Mention in description: "Independent from other PRs, can be merged in any order"

## Checklist Before Submitting

- [ ] Branch from latest master
- [ ] One focused feature or related features
- [ ] Rubocop passes (`docker compose exec rack rubocop -a`)
- [ ] Specs pass if added
- [ ] One clean commit
- [ ] Descriptive title with `[Game]` prefix
- [ ] PR description explains changes and testing
- [ ] No unnecessary comments in code (code should be self-explanatory)
