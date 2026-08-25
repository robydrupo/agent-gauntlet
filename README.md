# agent-gauntlet

Let coding agents write code without reading every line yourself.

You define the gates: build, tests, coverage, mutation testing, architecture rules. Agents
work until every gate passes. `./gauntlet.sh` exits 0 or it doesn't, and no model gets a
vote.

Works with any language. Ships with a Java example.

## Install

```sh
git clone https://github.com/robydrupo/agent-gauntlet.git
cd agent-gauntlet
./install.sh /path/to/your/project
```

Copies the runner, two tools, five agent definitions and one skill. Won't overwrite files
you've already edited.

## Set it up

Three files to write.

**`gauntlet.conf`** — your gates. A gate is a shell function that exits 0 or non-zero.

```sh
GATES=(
  "unit|unit tests"
  "mutation|mutation testing"
)

gate_unit()     { pytest -q; }
gate_mutation() { mutmut run; }

STAGE_CODER="unit"
STAGE_HARDENER="unit mutation"
```

Stages say which gates each agent has to pass before it's allowed to stop.

**`architecture.md`** — your modules, which may depend on which, and how the system is
invoked. Agents read this file. Back the dependency rules with a real tool (ArchUnit,
import-linter, dependency-cruiser) or they're just suggestions.

**`docs/stories/01-*.md`** — what you want, in your own words.

Then:

```sh
tools/check-referee.sh --regenerate
./gauntlet.sh --list       # check the gates look right
./gauntlet.sh              # red, and it tells you why
```

## Run it

```sh
/run-loop 01
```

Five agents run in order:

| Agent | Job | Done when |
|-------|-----|-----------|
| Specifier | story → spec + QA procedure | you've read it |
| Coder | spec → code + unit tests | `--stage coder` is green |
| Cleaner | refactor, bring CRAP down | `--stage cleaner` is green |
| Hardener | kill surviving mutants | `--stage hardener` is green |
| QA | QA procedure → executable script | the whole gauntlet is green |

Each agent sees only what it needs. The Coder never reads the story, because the spec is its
requirements document and two sources of truth will disagree. The QA agent never reads the
unit tests, because it's the independent check. The rules are in `agents/`.

`/run-loop` dispatches them and re-runs the gates itself after each one, so an agent that
claims success but left a gate red gets sent back. It stops to ask you once: after the
Specifier, if the Specifier flagged something the story didn't answer. Nothing can check a
spec against what you meant, so that part stays yours.

You can also drive them by hand — `use the coder agent`, and so on.

## Gates

```sh
./gauntlet.sh                  # all of them, stops at the first failure
./gauntlet.sh mutation         # one, by name
./gauntlet.sh --stage coder    # one agent's set
```

The reference set, wired up in `examples/java-maven`:

| # | Gate | Decides | Java tool |
|---|------|---------|-----------|
| 0 | referee | the gates haven't been edited | `sha256` |
| 1 | compile | it builds | javac |
| 2 | architecture | modules depend only on what they may | ArchUnit |
| 3 | unit | the units behave | JUnit 5 |
| 4 | acceptance | the spec is satisfied | Cucumber |
| 5 | coverage | a hard number is met | JaCoCo |
| 6 | CRAP | no method is both complex and untested | `tools/crap.py` |
| 7 | mutation | the tests verify something | PIT |
| 8 | QA | the built system works from outside | bash + diff |

Gate 0 checksums the files that define the other gates — the runner, the config, the build
file, `architecture.md`, the stories. If an agent lowers a threshold to get past gate 7, the
run goes red. Re-bless deliberate changes with `tools/check-referee.sh --regenerate`.

`docs/GATES.md` explains each gate and lists the equivalent tools for Python, TypeScript, Go
and Rust.

## Try the example

```sh
cd examples/java-maven
./gauntlet.sh            # nine gates, ~11s
./prove-gates-bite.sh    # break it three ways, watch the gates catch it
./reset.sh               # delete the agents' work, then /run-loop 01
```

Run `prove-gates-bite.sh` first. Its third case swaps in tests that call every line and
assert nothing. They pass 100% line coverage, 100% branch coverage, and CRAP. Mutation
testing scores them 56% and the run goes red.

That's the case worth understanding before you rely on any of this.

## Limits

- Nothing checks the specification. Read it.
- `tools/crap.py` reads JaCoCo XML only. Other languages need per-method complexity and
  coverage joined from two tools; `docs/GATES.md` says which.
- Gate 0 stops shortcuts, not determined cheating. An agent that edits the build file *and*
  the checksum file gets through. Use a CI check on protected paths if that matters.
- 100% mutation coverage is only realistic scoped to a module. The example scopes it to the
  domain and covers the adapter with QA scripts instead. Thresholds you can't hit get
  lowered, and a lowered threshold is a dead gate.

## Requirements

bash 3.2, Python 3, `shasum`. Gates call whatever you point them at. The Java example needs
JDK 17 and Maven.

MIT.
