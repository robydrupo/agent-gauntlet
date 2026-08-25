#!/usr/bin/env bash
#
# Delete everything the five agents produce, so you can run the loop yourself from scratch.
#
# Keeps the human-owned half: the story, architecture.md, pom.xml, gauntlet.conf, and the
# two harness test classes. Removes the specs, the code, the tests and the QA scripts.
#
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

rm -rf target
rm -f  specs/*.feature specs/qa/*.md
rm -f  qa/*.sh qa/golden/*
rm -f  src/main/java/wordwrap/domain/*.java src/main/java/wordwrap/cli/*.java
rm -f  src/test/java/wordwrap/domain/*.java
rm -f  src/test/java/wordwrap/acceptance/WordWrapSteps.java

echo "Reset. The human-owned half is intact:"
echo "  docs/stories/01-word-wrap.md   the story"
echo "  architecture.md                the modules and the entry point contract"
echo "  gauntlet.conf, pom.xml         the gates"
echo
echo "Now run:  /run-loop 01"
echo "Or check the starting state:  ./gauntlet.sh"
