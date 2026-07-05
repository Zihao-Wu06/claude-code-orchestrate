## Plan

I will not delegate this. I'll do it myself with two tool calls, run directly (no subagent, no peer):

1. **Read(README.md)** — read the file (or at least the region around line 3) to confirm the exact current text and surrounding context before editing. This satisfies the "read before edit" precondition and lets me verify the typo is really there as described (line 3, "teh quick brown fox") rather than trusting the user's line number blindly.

2. **Edit(README.md, old_string: "teh quick brown fox", new_string: "the quick brown fox")** — a single exact string replacement. No `replace_all` needed since this is one occurrence on one line.

That's it — no Bash, no Grep/Glob, no Agent spawn, no peer.sh consult, no report file.

## Why

Running the routing rule (first match wins, top to bottom) from SKILL.md:

- **Row 1** (planning/synthesis/integration) doesn't apply — there's nothing to decompose.
- **Row 2 fires immediately: "trivial + single-step, where briefing a subagent costs more than just doing it."** This is a one-word, single-character-class fix (teh→the) on a named file at a named line. Writing a proper dispatch contract for fast-worker — Goal / Inputs / Constraints / Interface / Acceptance check / Return format, per dispatch-prompt.md's mechanical template — would run to more tokens than the fix itself, plus the round-trip latency of spawning and waiting on the agent. The skill exists to keep expensive-model spend proportional to task complexity; routing a 1-line typo through any executor (even cheap Sonnet) inverts that ratio.

No later row ever gets consulted, because row 2 already matched:
- Not row 3 (high-stakes): blast radius is negligible (a doc string), and it's trivially verifiable by rereading the line — neither condition holds, let alone both.
- Not row 4 (recon): nothing to locate or map: the file and line are already given.
- Not row 5 (mechanical-but-delegate-worthy): it's mechanical, but scale is the missing ingredient — fast-worker earns its keep on bulk/repetitive mechanical work, not a single substitution.
- Not row 6 (reasoning-heavy): there is no design decision, ambiguity, or trade-off.
- Not row 7 (Codex/decorrelated prior): no novel problem, no disagreement, no loop to break out of.

I also don't spawn scout to "confirm" the typo first as a separate step — reading the file myself is a single cheap Read call, well under the "~100 lines read → dispatch scout" threshold in the Cost & context policy, so doing it inline is correct per that same policy rather than a violation of it.

No verification-stage reviewer is warranted either: this is my own trivial edit, not a delegated result, and the Verification stage in SKILL.md governs fan-in from delegated work, not solo edits I make directly. The "cheaply verifiable" check here is simply rereading the corrected line, which the Edit tool's diff view already shows.
