# Story 01 — Word Wrap

*Written by a human. This is the only creative input to the loop.*
*Agents may read this file. No agent may edit it.*

## What I want

I want to be able to take a blob of text and a column width, and get the text back
broken into lines that fit inside that width.

Break lines at spaces where you can. A word should not be cut in half just because
the line was nearly full — push the whole word onto the next line instead.

If a single word is genuinely longer than the column width, then you have no choice:
break it. Fill the line to the width and continue the rest of the word on the line
below, as many times as it takes.

The space you broke on shouldn't show up at the start of the next line. That looks wrong.

Text that already fits should come back untouched.

Empty text should give me back empty text, not an error.

A column width of zero or less makes no sense to me. I'd rather the system refuse
than guess.

## How I'd check it myself

I'd open the command-line tool, feed it some text and a width, and eyeball whether
the lines look right — nothing longer than the width, no words chopped up unless
they had to be, no stray leading spaces.

Then I'd try the silly cases: nothing at all, one enormous word, a width of zero.
