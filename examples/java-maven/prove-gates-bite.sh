#!/usr/bin/env bash
#
# A referee that never says no is worthless. This breaks the project in three realistic
# ways and asserts that the gauntlet catches each one.
#
# Run it on a green tree. It restores everything it touches, including on failure.
#
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

BACKUP=$(mktemp -d)
DOMAIN=src/main/java/wordwrap/domain/WordWrapper.java
TESTS=src/test/java/wordwrap/domain/WordWrapperTest.java
cp pom.xml "$BACKUP/" && cp "$DOMAIN" "$BACKUP/" && cp "$TESTS" "$BACKUP/"

restore() {
  cp "$BACKUP/pom.xml" pom.xml
  cp "$BACKUP/$(basename "$DOMAIN")" "$DOMAIN"
  cp "$BACKUP/$(basename "$TESTS")" "$TESTS"
}
trap 'restore; rm -rf "$BACKUP"' EXIT

failures=0
expect_red() {
  local what="$1"; shift
  if "$@" > /tmp/gauntlet-proof.log 2>&1; then
    echo "  DID NOT BITE   $what"
    echo "    the gauntlet passed when it should have failed"
    failures=$((failures + 1))
  else
    echo "  caught         $what"
  fi
}
expect_green() {
  local what="$1"; shift
  if "$@" > /tmp/gauntlet-proof.log 2>&1; then
    echo "  still green    $what"
  else
    echo "  UNEXPECTED RED $what"
    failures=$((failures + 1))
  fi
}

echo
echo "Baseline — the tree must be green before this proves anything."
if ! ./gauntlet.sh > /tmp/gauntlet-proof.log 2>&1; then
  echo "  the gauntlet is already red. Run it yourself and fix that first."
  exit 1
fi
echo "  green"

echo
echo "1. An agent lowers the mutation threshold to sneak past gate 7."
sed -i '' 's|<mutationThreshold>100</mutationThreshold>|<mutationThreshold>60</mutationThreshold>|' pom.xml
expect_red "gate 0 rejects a tampered pom.xml" ./gauntlet.sh mutation
restore

echo
echo "2. An agent puts I/O in the domain, which architecture.md forbids."
python3 - "$DOMAIN" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("        int lastSpace =", '        System.out.println("debug");\n        int lastSpace =')
open(p, "w").write(s)
PY
expect_red "gate 2 rejects I/O in the domain" ./gauntlet.sh architecture
restore

echo
echo "3. An agent writes tests that run every line but assert nothing meaningful."
cat > "$TESTS" <<'JAVA'
package wordwrap.domain;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class WordWrapperTest {
    private final WordWrapper wrapper = new WordWrapper();

    @Test
    void it_wraps() {
        assertNotNull(wrapper.wrap("the quick brown fox", 5));
        assertNotNull(wrapper.wrap("abcdefghijk", 5));
        assertNotNull(wrapper.wrap("hi", 5));
        assertNotNull(wrapper.wrap(" abcde", 5));
    }

    @Test
    void it_rejects_bad_widths() {
        assertThrows(IllegalArgumentException.class, () -> wrapper.wrap("x", 0));
    }
}
JAVA
expect_green "gate 5 is fooled — 100% line AND branch coverage" ./gauntlet.sh coverage
expect_green "gate 6 is fooled — CRAP is clean"                 ./gauntlet.sh crap
expect_red   "gate 7 is not fooled — mutation score drops to 56%" ./gauntlet.sh mutation
restore

echo
if [ $failures -eq 0 ]; then
  echo "All gates bit. The referee works."
  echo
  echo "Note what case 3 shows: 100% line and branch coverage, a clean CRAP score, and the"
  echo "tests still verify nothing. Only mutation testing notices. That is the entire reason"
  echo "the Hardener is a separate agent with a separate tool."
  exit 0
fi
echo "$failures gate(s) did not bite. The gauntlet is not trustworthy until that is fixed."
exit 1
