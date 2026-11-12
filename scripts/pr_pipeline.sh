#!/usr/bin/env bash
#
# pr_pipeline.sh — sobe commits da branch de trabalho como PRs, 1 a 1,
# apontando para a master do SEU fork, espera o CI ficar verde, faz merge
# e segue para o próximo. Para no primeiro vermelho e registra no log.
#
# Uso:
#   scripts/pr_pipeline.sh            # roda o pipeline (continua de onde parou)
#   scripts/pr_pipeline.sh --status   # mostra o progresso e sai
#   scripts/pr_pipeline.sh --dry-run  # mostra o que faria, sem criar PR/push
#
# Retomada: o estado "fonte da verdade" é a master do fork. A cada execução
# o script descobre quais commits da SOURCE_BRANCH ainda não estão na master
# do fork e processa o próximo. Se der pau, corrija, e rode de novo.
#
set -uo pipefail

# ------------------------- Configuração -------------------------
FORK_REMOTE="fork"            # remote do seu fork (git remote -v)
BASE_BRANCH="master"          # branch base dos PRs, no fork
SOURCE_BRANCH="frost-final"   # branch que contém os commits a transformar em PRs
UPSTREAM_REMOTE="origin"      # usado só para calcular o ponto de partida dos commits
SLEEP_SECONDS=300             # 5 minutos entre checagens de CI
LOG_FILE="scripts/pr_pipeline.log"

# Pule commits cujo título casa com esta regex (não viram PR).
SKIP_REGEX='DO NOT UPSTREAM'

# ------------------------- Infra -------------------------
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT" || exit 1
LOG_PATH="$ROOT/$LOG_FILE"

log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
  echo "$msg"
  echo "$msg" >> "$LOG_PATH"
}

die() {
  log "ERRO: $*"
  log "Pipeline PARADO. Corrija o problema e rode o script de novo para continuar."
  exit 1
}

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY-RUN> $*"
    return 0
  fi
  "$@"
}

slugify() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/\[[^]]*\]//g; s/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' \
    | cut -c1-40
}

# Lista, do mais antigo para o mais novo, os commits de SOURCE_BRANCH que estão
# à frente de UPSTREAM_REMOTE/BASE_BRANCH, pulando os que casam SKIP_REGEX.
pipeline_commits() {
  git log --reverse --format='%H%x09%s' \
    "$UPSTREAM_REMOTE/$BASE_BRANCH..$SOURCE_BRANCH" \
  | while IFS=$'\t' read -r sha subject; do
      if echo "$subject" | grep -qE "$SKIP_REGEX"; then
        continue
      fi
      echo "$sha"$'\t'"$subject"
    done
}

# Um commit é considerado "já processado" se um commit com o MESMO subject já
# existe na master do fork (cherry-pick muda o SHA, então comparamos por título).
already_done() {
  local subject="$1"
  git log --format='%s' "$FORK_REMOTE/$BASE_BRANCH" 2>/dev/null \
    | grep -Fxq "$subject"
}

# ------------------------- Ações -------------------------
show_status() {
  git fetch "$FORK_REMOTE" "$BASE_BRANCH" --quiet 2>/dev/null
  echo "Progresso do pipeline (base: $FORK_REMOTE/$BASE_BRANCH)"
  echo "--------------------------------------------------------"
  local n=0 done=0 pending=0
  while IFS=$'\t' read -r sha subject; do
    [[ -z "$sha" ]] && continue
    n=$((n+1))
    if already_done "$subject"; then
      printf '  [x] %s\n' "$subject"
      done=$((done+1))
    else
      printf '  [ ] %s\n' "$subject"
      pending=$((pending+1))
    fi
  done < <(pipeline_commits)
  echo "--------------------------------------------------------"
  echo "Total: $n | Mergeados: $done | Pendentes: $pending"
}

# Espera o CI de um PR. Retorna 0 se verde, 1 se vermelho/erro.
wait_for_ci() {
  local branch="$1"
  while true; do
    # state: SUCCESS | FAILURE | PENDING | (vazio se ainda não há checks)
    local state
    state="$(gh pr checks "$branch" --repo "$(gh repo view --json nameWithOwner -q .nameWithOwner)" 2>/dev/null \
             | awk '{print $2}' | sort -u | tr '\n' ' ')"

    local raw
    raw="$(gh pr checks "$branch" 2>&1)"

    if echo "$raw" | grep -qiE '\bfail|failure|error|cancelled'; then
      log "CI VERMELHO no PR da branch '$branch'."
      log "Detalhe dos checks:"
      echo "$raw" | sed 's/^/    /' | tee -a "$LOG_PATH"
      return 1
    fi

    if echo "$raw" | grep -qiE 'no checks reported|no commits'; then
      log "Ainda sem checks reportados para '$branch'. Aguardando..."
    elif ! echo "$raw" | grep -qiE 'pending|in progress|queued|\*'; then
      # Nenhum pending e nenhum fail => tudo passou.
      if echo "$raw" | grep -qiE 'pass|success|✓'; then
        log "CI VERDE no PR da branch '$branch'."
        return 0
      fi
    fi

    log "CI ainda rodando para '$branch'. Nova checagem em $((SLEEP_SECONDS/60)) min."
    sleep "$SLEEP_SECONDS"
  done
}

process_one() {
  local sha="$1" subject="$2" idx="$3"
  local slug branch
  slug="$(slugify "$subject")"
  branch="pr/$(printf '%02d' "$idx")-$slug"

  log "=== PR #$idx: $subject"
  log "commit=$sha  branch=$branch"

  # Base limpa a partir da master do fork já atualizada.
  run git fetch "$FORK_REMOTE" "$BASE_BRANCH" --quiet || die "fetch do fork falhou"
  run git branch -f "$branch" "$FORK_REMOTE/$BASE_BRANCH" || die "não criei a branch base"
  run git checkout "$branch" || die "checkout da branch do PR falhou"

  if ! run git cherry-pick "$sha"; then
    run git cherry-pick --abort 2>/dev/null
    die "cherry-pick de $sha falhou (conflito). Resolva e rode de novo."
  fi

  run git push -u "$FORK_REMOTE" "$branch" --force-with-lease \
    || die "push da branch do PR falhou"

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY-RUN> gh pr create --base $BASE_BRANCH --head $branch ..."
    return 0
  fi

  # Cria o PR (ou reaproveita se já existe para essa branch).
  if ! gh pr view "$branch" >/dev/null 2>&1; then
    gh pr create \
      --base "$BASE_BRANCH" \
      --head "$branch" \
      --title "$subject" \
      --body "Automated pipeline PR. Single commit: \`$subject\`." \
      || die "gh pr create falhou"
  else
    log "PR para '$branch' já existe. Reaproveitando."
  fi

  if ! wait_for_ci "$branch"; then
    die "CI falhou no PR '$branch' ($subject). Veja o log acima."
  fi

  log "Fazendo merge do PR '$branch' na $BASE_BRANCH do fork..."
  gh pr merge "$branch" --squash --delete-branch \
    || die "gh pr merge falhou para '$branch'"

  run git checkout "$SOURCE_BRANCH" --quiet
  log "PR #$idx mergeado com sucesso."
}

main() {
  touch "$LOG_PATH"
  log "########## Início do pipeline ##########"
  git fetch "$UPSTREAM_REMOTE" "$BASE_BRANCH" --quiet 2>/dev/null
  git fetch "$FORK_REMOTE" "$BASE_BRANCH" --quiet 2>/dev/null

  local idx=0 processed=0
  while IFS=$'\t' read -r sha subject; do
    [[ -z "$sha" ]] && continue
    idx=$((idx+1))
    if already_done "$subject"; then
      log "pulei (já mergeado): $subject"
      continue
    fi
    process_one "$sha" "$subject" "$idx"
    processed=$((processed+1))
  done < <(pipeline_commits)

  if [[ $processed -eq 0 ]]; then
    log "Nada a fazer: todos os commits já estão na $BASE_BRANCH do fork."
  else
    log "Pipeline concluído: $processed PR(s) processado(s) nesta execução."
  fi
  log "########## Fim do pipeline ##########"
}

case "${1:-}" in
  --status) show_status ;;
  --dry-run) main ;;
  "") main ;;
  *) echo "Uso: $0 [--status|--dry-run]"; exit 1 ;;
esac
