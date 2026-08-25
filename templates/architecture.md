# Architecture Specification

Human-written. Agents may **not** modify this file, nor the test that enforces it.
It is listed in `PROTECTED_FILES`, so gate 0 fails if anyone tries.

This is the wall. It exists so that each module is about a single topic — which is what
keeps humans *and* agents from getting confused. A module about one thing is a small thing
to hold in your head, and a small thing to misread.

## Modules

| Module | Responsibility | May depend on |
|--------|----------------|---------------|
| `core` | The domain logic. Pure. No I/O, no framework. | standard library only |
| `adapter` | Turns the outside world into a core call, and back. | `core` |

## Rules

1. `core` must **not** depend on `adapter`. Dependencies flow inward only.
2. `core` must **not** perform I/O. If it needs to talk, it returns a value.
3. There must be no dependency cycles between modules.
4. `core` is a **deep module**: it exposes one narrow public surface and hides the rest.
   Anything inside it that is not part of that surface is internal and stays internal.
   Agents read interfaces — a small interface is a small interface to get wrong.

Rules 1–3 are enforced by `gate_architecture` in `gauntlet.conf`. Every rule you write here
should have a machine behind it; a rule that only lives in prose is a suggestion.

## Entry point contract

Human-owned, so the QA agent can drive the system without guessing and without reading the
implementation:

    <how the system is invoked>

- Input arrives via ...
- Output goes to ...
- Errors go to ...
- Exit codes: `0` success, `1` input rejected, `2` incorrect usage.

Agents must implement exactly this. No agent may change it.
