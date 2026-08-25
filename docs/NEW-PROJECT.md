# Starting a new project

The gates come first. Before a line of code exists you decide what "done" means, and then
the agents work toward it. That's the opposite of the usual order, and it's the only part of
this that takes getting used to.

## Scaffold it

```sh
./new-project.sh java /path/to/myapp
```

`java`, `rust` or `python`. You get a project with the runner, the tools, the five agents,
the conductor skill, a build file, and a `gauntlet.conf` wired to real commands. For Java the
directory name becomes the package, so use something like `myapp`, not `My App`.

It ends red at the architecture gate:

```
GATE 2  architecture rules
  no production code in src/main/java — the Coder has not run
```

That's correct. The gates exist; the code doesn't yet.

## Then write two files

**`architecture.md`** — your modules and which may depend on which. The scaffold gives you
`domain` (pure) and `cli` (adapter), which is enough for most things and easy to grow.

Fix the entry point contract while you're in there: how the system is invoked, what it
reads, what it writes, what its exit codes mean. The QA agent drives the system through this
and nothing else, so pin it down now.

Every rule you write needs a machine behind it. Rules 1–3 in the scaffold are already
enforced by `ArchitectureTest.java`. If you add a fourth, add the check too — a rule that
only lives in prose is a suggestion.

**`docs/stories/01-first-story.md`** — what you want, in your own words. Informal is fine.
Cover the ordinary case, then say what should happen when things are awkward: nothing
supplied, too much supplied, a value that makes no sense. If you'd rather the system refuse
than guess, say so.

Both files are protected by gate 0, so after editing them:

```sh
tools/check-referee.sh --regenerate
```

## Run it

```sh
./gauntlet.sh          # red, and it tells you where
/run-loop 01
```

## What you own, what the agents own

| Yours | Theirs |
|-------|--------|
| `architecture.md` | `specs/` |
| `docs/stories/` | source and tests |
| `gauntlet.conf`, the build file | `qa/` |
| the architecture rules test | |

Everything in the left column is in `PROTECTED_FILES`. If an agent tries to edit its way
past a gate, gate 0 turns the run red.

## As the project grows

**More stories.** Write the next one and run `/run-loop 02`. Nothing carries over except the
code, which is the point.

**More modules.** Add the module to `architecture.md`, add the dependency rule, add the check
to the architecture test, re-bless. Do this before the agents need the module, not after —
retrofitting a boundary onto code that already crossed it is the expensive version.

**Stories from an issue tracker.** Define `fetch_story()` in `gauntlet.conf` and use
`./gauntlet.sh --fetch-story 42`. See the examples in `gauntlet.conf.example`.

**Thresholds.** The scaffold demands 100% line, branch and mutation coverage on `domain`
only. That's achievable there and nowhere else. Don't extend it to the adapter — the QA
scripts cover that. A threshold you can't hit gets lowered, and a lowered threshold is a dead
gate.

## Existing project instead?

```sh
./install.sh /path/to/project
```

Same machinery, no scaffolding, nothing overwritten. You write `gauntlet.conf` yourself —
start from `gauntlet.conf.example` or one of the `templates/gauntlet.conf.*` files, and point
each gate at commands your build already runs. Start with the gates you can turn green today
and add the strict ones once the code is ready for them.
