#!/usr/bin/env bash
#
# Start a new project with the gauntlet already wired up.
#
#     ./new-project.sh java /path/to/myapp
#     ./new-project.sh rust /path/to/myapp
#     ./new-project.sh python /path/to/myapp
#
# Leaves you with a project whose gauntlet runs and is RED, because there is no code yet.
# That is the correct starting state: the gates exist before the first line is written.
#
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LANG_="${1:-}"
TARGET="${2:-}"
if [ -z "$LANG_" ] || [ -z "$TARGET" ]; then
  echo "usage: ./new-project.sh <java|rust|python> /path/to/new/project" >&2
  exit 1
fi

if [ -e "$TARGET" ] && [ -n "$(ls -A "$TARGET" 2>/dev/null)" ]; then
  echo "new-project: $TARGET exists and is not empty." >&2
  echo "Use ./install.sh to add the gauntlet to an existing project." >&2
  exit 1
fi

mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"
NAME="$(basename "$TARGET")"

case "$LANG_" in
  java)
    if ! echo "$NAME" | grep -qE '^[a-z][a-z0-9]*$'; then
      echo "new-project: for java the directory name must be a valid package segment" >&2
      echo "  lowercase letters and digits, starting with a letter. Got: $NAME" >&2
      exit 1
    fi
    ;;
  rust|python) ;;
  *) echo "new-project: unknown language '$LANG_'" >&2; exit 1 ;;
esac

echo
echo "Creating $LANG_ project '$NAME' in $TARGET"
echo

# ---------------------------------------------------------------- the machinery
"$SRC/install.sh" "$TARGET" | grep -E '^  (updated|created|kept) ' | sed 's/^  /    /' 

scaffold_java() {
  # Start from the working example, strip it back to a skeleton, rename it.
  cp -R "$SRC/examples/java-maven/." "$TARGET/"
  rm -rf "$TARGET/target" "$TARGET/.gauntlet"
  ( cd "$TARGET" && ./reset.sh > /dev/null )
  rm -f "$TARGET/README.md" "$TARGET/prove-gates-bite.sh" "$TARGET/docs/stories/01-word-wrap.md"

  ( cd "$TARGET"
    for d in src/main/java src/test/java; do
      [ -d "$d/wordwrap" ] && mv "$d/wordwrap" "$d/$NAME"
    done
    grep -rl 'wordwrap' . 2>/dev/null | while read -r f; do
      sed -i '' "s/wordwrap/$NAME/g" "$f"
    done
  )

  # The example's architecture.md describes word wrap. Replace it with the same rules,
  # stated generically, with this project's package names.
  cat > "$TARGET/architecture.md" <<EOF
# Architecture Specification

Human-written. Agents may **not** modify this file, nor the test that enforces it
(\`src/test/java/$NAME/architecture/ArchitectureTest.java\`). Both are protected by gate 0.

This is the wall. Each module is about a single topic, which is what keeps humans and agents
from getting confused about where a change belongs.

## Modules

| Module | Responsibility | May depend on |
|--------|----------------|---------------|
| \`$NAME.domain\` | The business logic. Pure. No I/O, no framework. | JDK core only |
| \`$NAME.cli\` | Adapter: turns input into a domain call, renders the result. | \`$NAME.domain\` |

Add modules as the system grows, and add a rule below for each one.

## Rules

1. \`$NAME.domain\` must **not** depend on \`$NAME.cli\`. Dependencies flow inward only.
2. \`$NAME.domain\` must **not** perform I/O — no \`java.io\`, no \`java.nio.file\`,
   no \`System.out\` / \`System.err\`. If it needs to talk, it returns a value.
3. There must be no package cycles anywhere in \`$NAME\`.
4. \`$NAME.domain\` is a **deep module**: one narrow public surface, everything else
   package-private.

Rules 1–3 are enforced by ArchitectureTest. Every rule you add here should have a machine
behind it; a rule that only lives in prose is a suggestion.

## Entry point contract

Human-owned, so the QA agent can drive the system without reading the implementation:

    java -cp target/classes $NAME.cli.Main <args>

- Input arrives on stdin.
- Output goes to stdout.
- Errors go to stderr.
- Exit codes: \`0\` success, \`1\` input rejected, \`2\` incorrect usage.

Change this to suit your system, then keep it fixed. No agent may change it.
EOF
}

scaffold_rust() {
  cp "$SRC/templates/gauntlet.conf.rust" "$TARGET/gauntlet.conf"
  mkdir -p "$TARGET/crates/core/src" "$TARGET/crates/cli/src"
  cat > "$TARGET/Cargo.toml" <<EOF
[workspace]
members = ["crates/core", "crates/cli"]
resolver = "2"
EOF
  cat > "$TARGET/crates/core/Cargo.toml" <<EOF
[package]
name = "core"
version = "0.1.0"
edition = "2021"
EOF
  cat > "$TARGET/crates/cli/Cargo.toml" <<EOF
[package]
name = "cli"
version = "0.1.0"
edition = "2021"

[dependencies]
core = { path = "../core" }
EOF
}

scaffold_python() {
  cp "$SRC/templates/gauntlet.conf.python" "$TARGET/gauntlet.conf"
  mkdir -p "$TARGET/src/core" "$TARGET/src/adapter" "$TARGET/tests/unit"
  touch "$TARGET/src/core/__init__.py" "$TARGET/src/adapter/__init__.py"
  cat > "$TARGET/pyproject.toml" <<EOF
[project]
name = "$NAME"
version = "0.1.0"
requires-python = ">=3.11"
EOF
  cat > "$TARGET/.importlinter" <<'EOF'
[importlinter]
root_packages = core adapter

[importlinter:contract:layers]
name = core must not import adapter
type = layers
layers =
    adapter
    core
EOF
}

scaffold_"$LANG_"

# ---------------------------------------------------------------- your half
cp "$SRC/templates/story.md" "$TARGET/docs/stories/01-first-story.md"
rm -f "$TARGET/docs/stories/01-example.md"
[ "$LANG_" != "java" ] && cp "$SRC/templates/architecture.md" "$TARGET/architecture.md"

( cd "$TARGET" && tools/check-referee.sh --regenerate | sed 's/^  /    /' )

echo
echo "Done. Now, in order:"
echo
echo "  1. Edit architecture.md   — your modules and how the system is invoked."
echo "  2. Edit docs/stories/01-first-story.md — what you want, in your own words."
echo "  3. tools/check-referee.sh --regenerate   (you changed protected files)"
case "$LANG_" in
  java)   echo "  4. ./gauntlet.sh          — red at the architecture gate. Correct." ;;
  rust)   echo "  4. cargo install cargo-llvm-cov cargo-mutants   (coverage + mutation gates)"
          echo "  5. ./gauntlet.sh          — red. Correct." ;;
  python) echo "  4. pip install ruff mypy pytest coverage behave import-linter mutmut radon"
          echo "  5. ./gauntlet.sh          — red. Correct." ;;
esac
echo "  Then: /run-loop 01"
echo
