# agent-gauntlet

Infrastructure for letting coding agents work on a project without you reading every line
they write.

The premise is one sentence: **agents are non-deterministic, so you surround them with tools
that are not.** An agent is never finished because it says it is finished. It is finished
when `./gauntlet.sh` exits 0.

Everything here is the deterministic half — the gates, the referee that guards them, and a
loop of narrow single-purpose agents that have to get through them. Drop it into any project
in any language.

## Install

```sh
git clone https://github.com/robydrupo/agent-gauntlet.git
cd agent-gauntlet
./install.sh /path/to/your/project
```

That copies the runner, the tools, five agent definitions and a conductor skill into your
project, and never overwrites anything you've customised. Then wire `gauntlet.conf` to your
build, write `architecture.md`, write a story, and:

```sh
tools/check-referee.sh --regenerate
./gauntlet.sh --list
/run-loop 01
```

## The gauntlet

A gate is a shell function that exits 0 or non-zero. That is the entire contract. It must be
deterministic, and there must be no language model anywhere inside it.

`gauntlet.sh` is generic. Your gates live in `gauntlet.conf`:

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

```sh
./gauntlet.sh                  # every gate, stops at the first failure
./gauntlet.sh mutation         # one gate, by name
./gauntlet.sh --stage coder    # the gates one agent must satisfy
./gauntlet.sh --list           # what's configured
```

The reference set of gates, wired up in `examples/java-maven`:

| # | Gate | What it decides | Java tool |
|---|------|-----------------|-----------|
| 0 | referee integrity | the gates themselves are unedited | `sha256` |
| 1 | compile | it builds | javac |
| 2 | architecture rules | modules depend only on what they may | ArchUnit |
| 3 | unit tests | the units behave | JUnit 5 |
| 4 | acceptance | the specification is satisfied | Cucumber |
| 5 | coverage | a hard number, not a trend | JaCoCo |
| 6 | CRAP | complex code is not also untested | `tools/crap.py` |
| 7 | mutation | the tests actually verify something | PIT |
| 8 | QA scripts | the built system works from the outside | bash + diff |

See [docs/GATES.md](docs/GATES.md) for what each gate is for and the equivalent tools in
Python, TypeScript, Go and Rust.

### The three gates that carry the weight

**Mutation testing** breaks the production code on purpose — flips `>` to `>=`, negates a
condition, deletes a call — and reruns the tests. If they still pass, that behaviour was
never tested. Line coverage tells you a line ran; mutation testing tells you it *mattered*.
This is the only gate that catches tests written to satisfy a coverage number.

**CRAP** = `complexity² × (1 − coverage)³ + complexity`, per method. It punishes the
*combination* of convoluted and under-tested. Simple code may be lightly tested; gnarly code
must be covered or the number explodes. It gives the Cleaner a stop condition instead of an
opinion.

**Architecture rules** are the executable form of `architecture.md`: which module may depend
on which. Agents work better in a codebase where each module is about one topic — the same
reason humans do. A module about one thing is a small thing to hold in your head and a small
thing to misread. Prose can't enforce that; ArchUnit and its equivalents can.

### Gate 0: nobody bribed the referee

An agent stuck at a threshold has an obvious shortcut: lower the threshold. Gate 0
checksums every file that defines a gate — the runner, the config, the build file, the
architecture spec, and the stories — and always runs, even when you ask for a single gate.
Deliberate changes get re-blessed by a human with `tools/check-referee.sh --regenerate`.

The stories are protected too. Requirements are not the agents' to rewrite.

This raises the cost of cheating; it does not make it impossible. An agent that edits both
the build file and the manifest defeats it. Real enforcement is a CI check on a protected
path — gate 0 is what catches the honest mistake and the lazy shortcut on your laptop.

## The loop

Five specialists, each with a narrow job and — deliberately — a narrow view. An agent that
cannot see context which doesn't belong to it cannot be confused by that context.

| Agent | Reads | Writes | Deliberately cannot see |
|-------|-------|--------|-------------------------|
| Specifier | the story | specs, QA procedure | the source tree |
| Coder | the specs | code and unit tests | the story |
| Cleaner | the code, CRAP report | code structure | the specs |
| Hardener | the code, mutation report | tests only | — |
| QA | the QA procedure, the entry-point contract | QA scripts, golden files | the specs, the unit tests |

Some of those exclusions look arbitrary until you hit them. The Coder is kept away from the
story because the specification is its requirements document — two sources of truth will
eventually disagree, and it will pick the wrong one. The QA agent is kept away from the unit
tests because it is the independent check; if it reproduces what the Coder already asserted,
it has verified nothing.

A sixth agent, the **conductor** (`/run-loop`), dispatches the five and has the narrowest
view of all: it never reads the source tree. It runs the gates itself after every stage,
sends an agent back with the failing output when a gate is red, and gives up after three
attempts rather than thrashing. A conductor that has read all the code starts second-guessing
the specialists, and then you have six confused agents instead of five focused ones.

It stops to ask you exactly once — after the Specifier, if the Specifier left any
`# QUESTION:` comments. That stage has **no gate behind it**, because no machine can check
whether a specification matches what a human meant. That is the one place your attention is
structurally required.

## The example

`examples/java-maven` is a complete working build: the word wrap kata with all nine gates
wired up. It was created by running `./install.sh examples/java-maven`, so it's also the
test that the installer works.

```sh
cd examples/java-maven
./gauntlet.sh              # all nine gates green, ~11s
./prove-gates-bite.sh      # break it three ways, confirm each gate catches it
./reset.sh                 # delete everything the agents produce, then /run-loop 01
```

`prove-gates-bite.sh` is worth running before you trust any of this. It lowers the mutation
threshold and checks gate 0 catches it; puts I/O in the domain and checks gate 2 catches it;
and replaces the tests with ones that call every line and assert nothing — which sails
through **100% line coverage, 100% branch coverage and a clean CRAP score**, and dies at
mutation testing with a score of 56%.

That third case is the whole argument for keeping the Hardener as a separate agent with a
separate tool.

## What this doesn't do

- **It doesn't design your system.** `architecture.md` is yours to write, and the gates only
  enforce what you put in it. A rule that only lives in prose is a suggestion.
- **It doesn't check the specification.** Nothing here can tell whether the Specifier
  understood you. Read the specs.
- **100% mutation and branch coverage is brutal on a real codebase.** In the example it's
  scoped to the domain module and the adapter is checked by the QA scripts instead. Scope
  yours the same way — thresholds you can't hit get lowered, and a lowered threshold is a
  dead gate.
- **`tools/crap.py` reads JaCoCo XML only.** Other ecosystems need per-method complexity and
  per-method coverage joined from two tools; docs/GATES.md says which.

## Requirements

bash 3.2+, Python 3, `shasum`. Everything else is whatever your own gates call.
The Java example needs JDK 17 and Maven.

## License

MIT.
