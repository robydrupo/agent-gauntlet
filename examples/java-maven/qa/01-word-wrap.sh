#!/usr/bin/env bash
# Executable form of specs/qa/01-word-wrap.md.
# Drives the built system from the outside. Reaches inside nothing.
set -uo pipefail
cd "$(dirname "$0")/.."
RUN=(java -cp target/classes wordwrap.cli.Main)
rc=0

check() {
  local name="$1" golden="$2" actual="$3" expected_exit="$4" actual_exit="$5"
  if ! diff -u "$golden" <(printf '%s' "$actual") > /tmp/qa.diff 2>&1; then
    echo "    FAIL $name — output differs:"; sed 's/^/      /' /tmp/qa.diff; rc=1; return
  fi
  if [ "$expected_exit" != "$actual_exit" ]; then
    echo "    FAIL $name — expected exit $expected_exit, got $actual_exit"; rc=1; return
  fi
  echo "    ok   $name"
}

out=$(printf 'the quick brown fox' | "${RUN[@]}" 5); e=$?
check "step 1: wraps at spaces" qa/golden/01-fox.txt "$out" 0 $e

out=$(printf 'abcdefghijk' | "${RUN[@]}" 5); e=$?
check "step 2: breaks a too-long word" qa/golden/01-longword.txt "$out" 0 $e

out=$(printf '' | "${RUN[@]}" 5); e=$?
check "step 3: empty input gives empty output" qa/golden/01-empty.txt "$out" 0 $e

out=$(printf 'hello world' | "${RUN[@]}" 0 2>&1 >/dev/null); e=$?
check "step 4: refuses a width of zero" qa/golden/01-zero-width.txt "$out" 1 $e

out=$(printf '' | "${RUN[@]}" 2>&1 >/dev/null); e=$?
check "step 5: refuses a missing width" qa/golden/01-usage.txt "$out" 2 $e

exit $rc
