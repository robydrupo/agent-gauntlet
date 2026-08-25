# Example — Java / Maven

The word wrap kata with all nine gates wired up. Small enough to read in one sitting, real
enough that the gates have something to bite on.

This directory was created by running `../../install.sh examples/java-maven` and then filling
in `gauntlet.conf`, `architecture.md` and the story — so it doubles as the installer's test.

## Try it

```sh
./gauntlet.sh              # nine gates, ~11s, all green
./gauntlet.sh --list       # what's configured
./prove-gates-bite.sh      # break it three ways, confirm each gate catches it
```

Run `prove-gates-bite.sh` before trusting any of this. Its third case replaces the tests with
ones that call every line and assert almost nothing — that passes **100% line coverage, 100%
branch coverage and CRAP**, and dies at mutation testing on 56%.

## Run the loop yourself

```sh
./reset.sh                 # deletes everything the agents produce
/run-loop 01
```

`reset.sh` keeps the human-owned half — the story, `architecture.md`, `pom.xml`,
`gauntlet.conf`, and the two harness test classes — and deletes the specs, the code, the
tests and the QA scripts. Afterwards `./gauntlet.sh` should be red at gate 2 with
`no production code in src/main/java — the Coder has not run`.

## What's whose

| | |
|---|---|
| **Human-owned** | `docs/stories/01-word-wrap.md`, `architecture.md`, `gauntlet.conf`, `pom.xml` |
| **Harness** | `ArchitectureTest.java` (executable form of architecture.md), `RunCucumberTest.java` |
| **Specifier** | `specs/01-word-wrap.feature`, `specs/qa/01-word-wrap.md` |
| **Coder** | `src/main/**`, `src/test/java/wordwrap/domain/**`, `WordWrapSteps.java` |
| **Cleaner** | refactors the above; adds nothing |
| **Hardener** | strengthens `src/test/java/wordwrap/domain/**` only |
| **QA** | `qa/*.sh`, `qa/golden/*` |

Everything in the first two rows is in `PROTECTED_FILES`, so gate 0 fails if an agent
touches it.

## Notes on the thresholds

Coverage and mutation are pinned at 100% but **scoped to `wordwrap.domain`**. The CLI adapter
is deliberately excluded from both and is checked by the QA scripts instead — it's the part
that talks to the outside world, and unit-testing `System.out` earns nothing.

CRAP runs across the whole `wordwrap` package at the conventional threshold of 30, including
the uncovered adapter. That's on purpose: it puts quiet pressure on keeping the adapter thin.
`Main.main` currently scores 6.

## Requirements

JDK 17 and Maven. `gauntlet.conf` pins `JAVA_HOME` to Homebrew's `openjdk@17`; change that
line if your JDK lives elsewhere, then run `tools/check-referee.sh --regenerate`.
