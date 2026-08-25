# QA Procedure — Story 01, Word Wrap

You are a person using this system through its command-line interface.

1. Run the tool with a width of 5 and type `the quick brown fox` as input.
   You should see four lines: `the`, `quick`, `brown`, `fox`. Nothing longer than 5
   characters. The tool should finish successfully.
2. Run it with a width of 5 and type `abcdefghijk`.
   You should see `abcde`, `fghij`, `k` — the word had to be broken.
3. Run it with a width of 5 and give it nothing at all.
   You should get nothing back, and no error.
4. Run it with a width of 0 and type `hello world`.
   The tool should refuse, tell you the width must be greater than zero, and finish
   unsuccessfully.
5. Run it with no width at all.
   The tool should tell you how to use it and finish unsuccessfully.
