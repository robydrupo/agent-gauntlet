# Architecture Specification

Human-written. Agents may **not** modify this file, nor the ArchUnit test that enforces it
(`src/test/java/wordwrap/architecture/ArchitectureTest.java`).

This is the "wall" from the notes: a specification file the agent cannot violate.
It exists so that each module is about a single topic — which keeps humans *and* agents
from getting confused.

## Modules

| Module            | Responsibility                                        | May depend on |
|-------------------|-------------------------------------------------------|---------------|
| `wordwrap.domain` | The wrapping algorithm. Pure. No I/O, no framework.   | JDK core only |
| `wordwrap.cli`    | Adapter: turns argv/stdin into a domain call, prints. | `wordwrap.domain` |

## Rules

1. `wordwrap.domain` must **not** depend on `wordwrap.cli`. Dependencies flow inward only.
2. `wordwrap.domain` must **not** perform I/O — no `java.io`, no `java.nio.file`,
   no `System.out` / `System.err`. If the algorithm needs to talk, it returns a value.
3. There must be no package cycles anywhere in `wordwrap`.
4. `wordwrap.domain` is a **deep module**: it exposes one narrow public surface and hides
   the rest. Any helper class inside `domain` that is not part of that surface must be
   package-private. Agents read interfaces — a small interface is a small thing to misread.

## Entry point contract

Human-owned, so that the QA agent can drive the system without guessing and without
reading the implementation:

    java -cp target/classes wordwrap.cli.Main <width>

- The text to wrap arrives on **stdin**.
- The wrapped text goes to **stdout**.
- Errors go to **stderr**.
- Exit `0` on success, `1` when the input is rejected, `2` on incorrect usage.

The Coder must implement exactly this. No agent may change it.
