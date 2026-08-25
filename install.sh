#!/usr/bin/env bash
#
# Install the gauntlet into a project.
#
#     ./install.sh /path/to/your/project
#
# Copies the runner, the tools, the five agents and the conductor skill. Never overwrites
# anything you have already customised — it tells you what it skipped so you can diff.
#
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "usage: ./install.sh /path/to/your/project" >&2
  exit 1
fi
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

if [ "$TARGET" = "$SRC" ]; then
  echo "install.sh: refusing to install into itself" >&2
  exit 1
fi

copied=0
skipped=0

# Always current: the machinery has no project-specific content in it.
install_always() {
  mkdir -p "$TARGET/$(dirname "$2")"
  cp "$SRC/$1" "$TARGET/$2"
  echo "  updated  $2"
  copied=$((copied + 1))
}

# Yours once created: never clobber a customised file.
install_once() {
  if [ -e "$TARGET/$2" ]; then
    echo "  kept     $2  (already exists)"
    skipped=$((skipped + 1))
    return
  fi
  mkdir -p "$TARGET/$(dirname "$2")"
  cp "$SRC/$1" "$TARGET/$2"
  echo "  created  $2"
  copied=$((copied + 1))
}

echo
echo "Installing the gauntlet into $TARGET"
echo

install_always gauntlet.sh            gauntlet.sh
install_always tools/crap.py          tools/crap.py
install_always tools/check-referee.sh tools/check-referee.sh
chmod +x "$TARGET/gauntlet.sh" "$TARGET/tools/crap.py" "$TARGET/tools/check-referee.sh"

for a in "$SRC"/agents/*.md; do
  install_always "agents/$(basename "$a")" ".claude/agents/$(basename "$a")"
done
install_always skills/run-loop/SKILL.md .claude/skills/run-loop/SKILL.md

install_once gauntlet.conf.example    gauntlet.conf
install_once templates/architecture.md architecture.md
install_once templates/story.md        docs/stories/01-example.md

mkdir -p "$TARGET/specs/qa" "$TARGET/qa/golden" "$TARGET/.gauntlet"

echo
echo "  $copied written, $skipped left alone"
cat <<'NEXT'

Next:
  1. Edit gauntlet.conf     — wire each gate to a real command for your stack.
  2. Edit architecture.md   — your modules, your dependency rules, your entry point.
  3. Write docs/stories/    — one story, in your own words.
  4. tools/check-referee.sh --regenerate
  5. ./gauntlet.sh --list   — confirm the gates and stages look right.
  6. ./gauntlet.sh          — it should be red, and it should say why.
  7. /run-loop 01

NEXT
