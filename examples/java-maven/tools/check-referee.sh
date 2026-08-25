#!/usr/bin/env bash
#
# GATE 0 — is the referee still the referee?
#
# Every gate is only as trustworthy as the files that define it. An agent stuck at a gate
# has an obvious shortcut available: lower the threshold. This checks nobody took it.
#
# The list of protected files is PROTECTED_FILES in gauntlet.conf.
# A human re-blesses a deliberate change with:  tools/check-referee.sh --regenerate
#
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CONF="${GAUNTLET_CONF:-gauntlet.conf}"
if [ ! -f "$CONF" ]; then
  echo "  no $CONF — cannot tell which files are protected"
  exit 1
fi

REFEREE_MANIFEST=".gauntlet/referee.sha256"
PROTECTED_FILES=()
# shellcheck disable=SC1090
. "./$CONF"

# expand any globs, drop anything that does not exist
expanded=()
for pattern in "${PROTECTED_FILES[@]}"; do
  for f in $pattern; do
    [ -f "$f" ] && expanded+=("$f")
  done
done

if [ ${#expanded[@]} -eq 0 ]; then
  echo "  PROTECTED_FILES in $CONF matches nothing — the referee is unguarded"
  exit 1
fi

if [ "${1:-}" = "--regenerate" ]; then
  mkdir -p "$(dirname "$REFEREE_MANIFEST")"
  shasum -a 256 "${expanded[@]}" > "$REFEREE_MANIFEST"
  echo "  re-blessed ${#expanded[@]} referee files into $REFEREE_MANIFEST"
  exit 0
fi

if [ ! -f "$REFEREE_MANIFEST" ]; then
  echo "  no $REFEREE_MANIFEST — run: tools/check-referee.sh --regenerate"
  exit 1
fi

# A file added to PROTECTED_FILES but never blessed is a hole, so check the count too.
blessed=$(wc -l < "$REFEREE_MANIFEST" | tr -d ' ')
if [ "$blessed" -ne "${#expanded[@]}" ]; then
  echo "  PROTECTED_FILES lists ${#expanded[@]} files but $REFEREE_MANIFEST blesses $blessed."
  echo "  Something was added or removed. Review it, then: tools/check-referee.sh --regenerate"
  exit 1
fi

if shasum -a 256 -c "$REFEREE_MANIFEST" --status 2>/dev/null; then
  echo "  referee intact (${#expanded[@]} files)"
  exit 0
fi

echo "  REFEREE TAMPERED WITH:"
shasum -a 256 -c "$REFEREE_MANIFEST" 2>&1 | grep -v ': OK$' | sed 's/^/    /'
echo
echo "  A file that defines the gates has changed. A green gauntlet means nothing until"
echo "  this is reverted. If the change was deliberate and a human approved it:"
echo "      tools/check-referee.sh --regenerate"
exit 1
