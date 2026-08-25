#!/usr/bin/env bash
#
# THE GAUNTLET — the deterministic half of an agent loop.
#
# Agents are non-deterministic. These gates are not. Each one is a real tool with a binary
# verdict and no model judgment anywhere in it. An agent is not done when it says it is
# done; it is done when this script exits 0.
#
# This file is generic. Your project's gates live in gauntlet.conf.
#
# Usage:
#   ./gauntlet.sh                  every gate, stops at the first failure
#   ./gauntlet.sh mutation         one gate, by name
#   ./gauntlet.sh 3 4              gates by number
#   ./gauntlet.sh --stage coder    the gates one loop stage must satisfy
#   ./gauntlet.sh --list           show the configured gates and stages
#   ./gauntlet.sh --fetch-story 42 pull a story in from wherever you keep them
#
# Humans own this file and gauntlet.conf. Agents may not edit either, and may not lower a
# threshold to get past a gate. Gate 0 checks that nobody did.
#
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

CONF="${GAUNTLET_CONF:-gauntlet.conf}"
if [ ! -f "$CONF" ]; then
  echo "gauntlet: no $CONF in $ROOT — copy gauntlet.conf.example and fill it in." >&2
  exit 1
fi

# Defaults a project's conf may override.
STORY_DIR="docs/stories"
REFEREE_MANIFEST=".gauntlet/referee.sha256"
PROTECTED_FILES=()
GATES=()

# shellcheck disable=SC1090
. "./$CONF"

if [ ${#GATES[@]} -eq 0 ]; then
  echo "gauntlet: $CONF defines no GATES." >&2
  exit 1
fi

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
pass() { printf '\033[32m  PASS\033[0m  %s\n' "$1"; }
fail() { printf '\033[31m  FAIL\033[0m  %s\n' "$1"; }

gate_name()  { echo "${1%%|*}"; }
gate_label() { echo "${1#*|}"; }

stage_gates() {
  local upper var
  upper=$(echo "$1" | tr '[:lower:]-' '[:upper:]_')
  var="STAGE_$upper"
  echo "${!var:-}"
}

# ---------------------------------------------------------------- gate 0, always runs
gate_0_referee() {
  tools/check-referee.sh
}

# ---------------------------------------------------------------- argument handling

# Stories can live anywhere: a plain file you wrote, a Linear issue, a GitHub issue, a row
# in a spreadsheet. If the conf defines fetch_story(), this pulls one into $STORY_DIR.
#
# The referee is re-blessed straight afterwards, because a new story changes a protected
# file. That is safe here and only here: you asked for this story, and no agent has run yet.
# Nothing re-blesses anything once the loop is under way.
if [ "${1:-}" = "--fetch-story" ]; then
  if [ -z "${2:-}" ]; then echo "gauntlet: --fetch-story needs a story id" >&2; exit 1; fi
  if ! declare -f fetch_story > /dev/null 2>&1; then
    echo "gauntlet: $CONF defines no fetch_story() — stories are plain files in $STORY_DIR/" >&2
    exit 1
  fi
  mkdir -p "$STORY_DIR"
  fetch_story "$2" || exit 1
  tools/check-referee.sh --regenerate
  exit 0
fi

selected=""
if [ "${1:-}" = "--list" ]; then
  echo
  bold "Gates"
  printf '  %-3s %-16s %s\n' "0" "referee" "referee integrity (always runs)"
  i=0
  for entry in "${GATES[@]}"; do
    i=$((i + 1))
    printf '  %-3s %-16s %s\n' "$i" "$(gate_name "$entry")" "$(gate_label "$entry")"
  done
  echo
  bold "Stages"
  for s in $(set | grep -o '^STAGE_[A-Z_]*' | sed 's/^STAGE_//' | tr '[:upper:]' '[:lower:]'); do
    printf '  %-16s %s\n' "$s" "$(stage_gates "$s")"
  done
  echo
  exit 0
fi

if [ "${1:-}" = "--stage" ]; then
  if [ -z "${2:-}" ]; then echo "gauntlet: --stage needs a stage name" >&2; exit 1; fi
  selected=$(stage_gates "$2")
  if [ -z "$selected" ]; then
    echo "gauntlet: $CONF defines no stage '$2' (try ./gauntlet.sh --list)" >&2
    exit 1
  fi
  [ "$selected" = "all" ] && selected=""
  STAGE_LABEL="$2"
else
  selected="$*"
  STAGE_LABEL=""
fi

run_all=0
[ -z "$selected" ] && run_all=1

echo
if [ -n "$STAGE_LABEL" ]; then
  bold "════════ THE GAUNTLET — stage: $STAGE_LABEL ════════"
else
  bold "════════ THE GAUNTLET ════════"
fi

failed_gate=""

run_gate() {
  local num="$1" name="$2" label="$3" fn="$4"
  echo
  bold "GATE $num  $label"
  if "$fn"; then
    pass "$name"
    return 0
  fi
  fail "$name"
  failed_gate="GATE $num  $label"
  return 1
}

# Gate 0 is not optional. A green gauntlet means nothing if the gates were edited.
run_gate 0 referee "referee integrity (the gates have not been edited)" gate_0_referee || {
  echo
  bold "════════ GAUNTLET RED ════════"
  echo "Blocked at: $failed_gate"
  exit 1
}

i=0
for entry in "${GATES[@]}"; do
  i=$((i + 1))
  name=$(gate_name "$entry")
  label=$(gate_label "$entry")

  if [ $run_all -eq 0 ]; then
    match=0
    for w in $selected; do
      if [ "$w" = "$i" ] || [ "$w" = "$name" ]; then match=1; fi
    done
    [ $match -eq 1 ] || continue
  fi

  run_gate "$i" "$name" "$label" "gate_$name" || break
done

echo
if [ -n "$failed_gate" ]; then
  bold "════════ GAUNTLET RED ════════"
  echo "Blocked at: $failed_gate"
  echo "Fix the code. Do not lower the threshold. Do not edit gauntlet.sh or gauntlet.conf."
  exit 1
fi
bold "════════ GAUNTLET GREEN ════════"
exit 0
