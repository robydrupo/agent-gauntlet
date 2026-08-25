# The gates

A gate is a shell function that exits 0 or non-zero. It must be deterministic, and there
must be no language model anywhere inside it. Everything else is your choice.

Order them cheapest-first. An agent that gets its feedback in two seconds iterates; one that
waits four minutes for a full suite starts guessing.

---

## 0 — Referee integrity

**Decides:** that the files defining the gates haven't been edited.

Built into `gauntlet.sh`, always runs. Configure with `PROTECTED_FILES` in `gauntlet.conf`.
Include the runner, the config, your build file, `architecture.md`, the architecture rules
test, and `docs/stories/*.md`.

Re-bless deliberate changes with `tools/check-referee.sh --regenerate`. That command is for
humans; if an agent runs it, the gate is gone.

---

## 1 — Build

**Decides:** it compiles / imports / type-checks.

Fold your linter and type checker in here rather than making them separate gates — they fail
for the same reason and the agent fixes them the same way.

| | |
|---|---|
| Java | `mvn -q compile` |
| Python | `ruff check && mypy .` |
| TypeScript | `tsc --noEmit && eslint .` |
| Go | `go vet ./...` |
| Rust | `cargo clippy -- -D warnings` |

---

## 2 — Architecture rules

**Decides:** each module depends only on what `architecture.md` permits.

The most under-used gate, and the one that pays off most as a codebase grows. Agents work
better when a module is about a single topic — the same reason humans do. This is what stops
the boundary eroding one convenient import at a time.

| | |
|---|---|
| Java | [ArchUnit](https://www.archunit.org/) |
| Python | [import-linter](https://import-linter.readthedocs.io/) |
| TypeScript | [dependency-cruiser](https://github.com/sverweij/dependency-cruiser) |
| Go | [go-arch-lint](https://github.com/fe3dback/go-arch-lint) |
| Rust | crate boundaries + `cargo-deny` |

Write the rule in `architecture.md` *and* in the tool. Prose alone is a suggestion.

---

## 3 — Unit tests

**Decides:** the units behave.

Nothing exotic. Your test runner, exiting non-zero.

---

## 4 — Acceptance

**Decides:** the specification the Specifier wrote is satisfied.

Gherkin is the usual choice because the Specifier can write it and a human can read it, but
any executable spec format works — the requirement is that the artefact the Specifier
produces is the artefact the gate runs.

| | |
|---|---|
| Java | Cucumber JVM |
| Python | behave / pytest-bdd |
| TypeScript | cucumber-js |
| Go | godog |
| Rust | cucumber-rs |

---

## 5 — Coverage

**Decides:** a hard number is met.

A threshold, not a trend. "Coverage went up" is not a gate.

Scope it. 100% on a domain module is reasonable; 100% across an entire application is a
threshold you will quietly lower in three weeks, and a lowered threshold is a dead gate.

---

## 6 — CRAP

**Decides:** no method is both complex and under-tested.

    CRAP(m) = complexity(m)² × (1 − coverage(m))³ + complexity(m)

Simple code may be lightly tested. Convoluted code must be covered or the number explodes.
Threshold 30 is the conventional line — a method of complexity 5 must be ~60% covered to
pass, one of complexity 10 must be ~90%.

It gives the Cleaner a stop condition instead of an opinion, which is the difference between
an agent that refactors and one that fiddles forever.

`tools/crap.py` reads **JaCoCo XML**. Elsewhere you need per-method cyclomatic complexity and
per-method coverage in one place, which usually means joining two tools:

| | |
|---|---|
| Java | JaCoCo XML → `tools/crap.py` |
| Python | `radon cc --json` + `coverage json` |
| TypeScript | `eslint complexity` + `nyc --reporter=json` |
| Go | `gocyclo` + `go test -coverprofile` |

---

## 7 — Mutation testing

**Decides:** the tests actually verify behaviour rather than merely executing it.

The tool breaks the production code on purpose and reruns the tests. A mutant that survives
proves that behaviour is untested. This is the only gate that catches tests written to
satisfy gate 5, and it is slow — put it last among the code gates and scope it to the module
that matters.

| | |
|---|---|
| Java | [PIT](https://pitest.org/) |
| Python | [mutmut](https://mutmut.readthedocs.io/) / [cosmic-ray](https://github.com/sixty-north/cosmic-ray) |
| TypeScript | [Stryker](https://stryker-mutator.io/) |
| Go | [go-mutesting](https://github.com/zimmski/go-mutesting) |
| Rust | [cargo-mutants](https://mutants.rs/) |

Watch for *equivalent* mutants — ones that genuinely cannot change behaviour, usually
because the code is unreachable. They're rarer than an agent will claim.

---

## 8 — QA scripts

**Decides:** the built system does what the QA procedure says, driven from outside.

The script builds the system, runs it, feeds it input, captures output, and diffs against a
golden file. It imports nothing and reaches inside nothing. If the system were rewritten in
another language tomorrow, the script should still pass.

This is the gate that catches what four other agents missed, because it's the only one that
tests the thing you actually ship rather than the parts it's made of.

Rules: no timestamps, no random data, no network, no wall-clock timing, no machine-specific
paths. Assert on exit codes as well as output. Print the diff on failure.

---

## Stages

Stages map gates to the agent that owns them:

```sh
STAGE_CODER="build architecture unit acceptance"
STAGE_CLEANER="build architecture unit acceptance coverage crap"
STAGE_HARDENER="build architecture unit acceptance coverage crap mutation"
STAGE_QA="all"
```

Each stage repeats every earlier stage's gates on purpose. An agent that fixes its own gate
by breaking an earlier one has not finished.
