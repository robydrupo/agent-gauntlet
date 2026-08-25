---
name: run-loop
description: Run one story through the full gauntlet loop - Specifier, Coder, Cleaner, Hardener, QA - verifying each stage against the deterministic gates and only finishing when the whole gauntlet is green. Use when asked to run the loop, run a story, or build a story end to end.
---

# The Loop

You are the **conductor**. You run one story from `docs/stories/` through five specialist
agents and verify each one against the gauntlet.

## The one rule that makes this work

**You never do the work yourself.** You do not write code, write tests, write specs, or fix
a failing gate. You do not read the source tree. If you find yourself editing a file, you
have broken the loop — stop and hand it back to the agent whose job it was.

Your context holds gate results, not implementation. That is deliberate: a conductor who has
read all the code is a conductor who starts second-guessing the specialists, and then you
have six confused agents instead of five focused ones.

**And you never take an agent's word for it.** Every agent will report success. Some of them
will be wrong. The gauntlet is the only thing that decides, and *you* run it — not the agent.

## Step 1 — orient

Run `./gauntlet.sh --list` to see this project's gates and stages. Gate and stage names are
project-specific; never assume them.

Then get the story. Stories may live in files or in an issue tracker:
- If `./gauntlet.sh --fetch-story <id>` is configured and the user gave an id that isn't a
  local file, run it. It pulls the story in and re-blesses the referee.
- If the user named a local story (`01`, `01-checkout`, a path), use that.
- Otherwise, if the story directory holds exactly one `.md` file, use it.
- Otherwise list them and ask which one.

Either way the Specifier receives a path to a markdown file and never learns where it came
from.

## Step 2 — establish the baseline

Run `./gauntlet.sh` and note where it stops. If **gate 0** fails, stop immediately: someone
has edited the files that define the gates, and nothing downstream can be trusted. Report it
and do not proceed.

## Step 3 — run the five stages in order

| # | Agent | `subagent_type` | Its exit condition |
|---|-------|-----------------|--------------------|
| 1 | Specifier | `specifier` | *(none — see below)* |
| 2 | Coder | `coder` | `./gauntlet.sh --stage coder` |
| 3 | Cleaner | `cleaner` | `./gauntlet.sh --stage cleaner` |
| 4 | Hardener | `hardener` | `./gauntlet.sh --stage hardener` |
| 5 | QA | `qa` | `./gauntlet.sh` |

For each stage:

1. **Dispatch** the agent with the Agent tool, `subagent_type` set from the table. Give it
   only what it needs — the story path for the Specifier, nothing but "implement the specs"
   for the Coder. Do not paste code, earlier gate output, or advice into the prompt. Their
   instruction files already say what they may read.
2. **Verify independently.** When the agent returns, run its exit condition yourself with
   Bash. The exit code is the truth. The agent's summary is a claim.
3. **If red:** send the agent back with `SendMessage`, using its ID so it keeps its own
   context, and give it the failing gate output verbatim and nothing else. Do not diagnose
   the problem for it, and do not suggest a fix — that is you doing its job.
4. **After three failed attempts at one stage, stop the whole loop.** Report which gate is
   blocking, the output, and what the agent said it tried. A stage that cannot get green in
   three tries usually means the specification is wrong or the architecture is fighting the
   problem, and both of those are human decisions.

Never skip a stage because a later gate happens to be green already, and never run stages
out of order.

## Step 3b — when an agent reports a FINDING

There are two different reds, and they are handled differently.

**The agent's own work is wrong.** Its gate is red because of what it just did. It fixes it
itself — that is the retry loop above.

**The work underneath is wrong.** The agent is blocked by something it is forbidden to
touch, and says so with `FINDING:`. Retrying it is useless; it will report the same thing
again. Route it instead:

| Who reports it | What it means | Send it to |
|----------------|---------------|-----------|
| Coder | a scenario is wrong, impossible, or self-contradictory | **the user** — the spec is a human decision |
| Cleaner | a test asserts the wrong behaviour | **Coder** |
| Hardener | a mutant survives because the code is wrong, not the test | **Coder** |
| QA | the built system disagrees with the QA procedure | **Coder** |

When you send a finding to the Coder, dispatch a **fresh** Coder agent with the finding text
and nothing else. Then **re-run every stage from the Coder onwards.** A code change
invalidates the Cleaner's refactoring, the Hardener's mutation score and the QA run — those
stages passed against code that no longer exists.

This is the part that makes it a loop rather than a pipeline. Do not shortcut it by re-running
only the stage that reported the finding.

Count a finding-and-repair as one attempt at the stage that reported it. If the same stage
reports a second finding after a Coder repair, stop and bring both to the user: two rounds
usually means the specification is wrong, not the code.

## Step 3a — the one place you pause

The Specifier has **no deterministic gate behind it**. No machine can check whether a
specification matches a human's intent.

So after it returns: read `specs/` — this is the one thing you read in detail all run.

- If the Specifier left any `# QUESTION:` comments, **stop and ask the user** before
  dispatching the Coder. Quote the questions and the scenarios they sit above.
- Otherwise, summarise the scenarios in a couple of lines and continue. Don't wait for
  approval you weren't asked for.

## Step 4 — finish

Run the full `./gauntlet.sh` one last time. Every gate, from scratch.

**You are done when, and only when, that exits 0.** Not when the QA agent says so.

## Step 5 — report

Keep it short. The user wants to know what the machine decided, not what the agents said:

- A stage-by-stage table: agent, attempts needed, final verdict.
- The headline numbers the gates produced — mutation score, worst CRAP score, coverage.
- Every `FINDING:` any agent raised, who raised it, and what the Coder changed in response.
  These matter most — they are the defects that the gates caught but the agents could not fix
  on their own, and they are the closest thing you get to a bug report from this process.
- Every `# QUESTION:` the Specifier raised, and how it was settled.
- Any stage that needed more than one attempt, and what the gate said the first time. That
  is where your loop is weak, and it is the most useful thing you can tell the user.
