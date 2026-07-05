# Plan: Extract session-handling logic from src/auth into its own package

## Reasoning against the skill's routing rule (SKILL.md)

I have not read any of the five files, and I should not start by reading them
myself. The Cost & context policy is explicit: "Don't read to understand —
dispatch scout. If understanding or locating something needs more than ~100
lines read, that is scout's job." ~2000 lines across 5 files is far past that
threshold, so step 1 is reconnaissance, not my own reading.

This task also trips the **high-stakes** flag from the routing table (row 3):
blast radius is high — the task is explicitly auth/session code, named in the
skill's own blast-radius list ("security & auth") — and it is hard to verify
by a diff or a single test alone, because subtle session bugs (fixation,
premature invalidation, token/session desync across the extracted boundary)
don't reliably surface as compile errors. Row 3 fires only once both
conditions are confirmed against real content, so I can't invoke it blind;
scout's inventory is what lets me confirm blast radius and coupling concretely
enough to decide whether the *design* step goes to deep-reasoner solo or to
the Opus+Codex blind-parallel path.

So the sequence is:

1. **Scout (Haiku, read-only)** produces a full structural inventory of all
   five files — this is a **data-handoff recon** per dispatch-prompt.md: the
   inventory feeds deep-reasoner next, so it returns in full, not truncated to
   ≤20 lines, and I relay it verbatim without re-reading it myself.
2. **deep-reasoner (Opus)**, using scout's inventory as input, designs the
   extraction: the new package's boundary and public interface, what exactly
   counts as "session-handling logic" at the fuzzy edges (e.g., do
   session-scoped functions in tokens.go move too?), and the acceptance
   check. Given "subtle... thoroughly and correctly" plus the high-stakes
   flag, I will present this design step's output alongside a Codex
   consult/adversarial-falsify pass before locking the interface — not
   because Opus is assumed wrong, but because the risk here is hard to verify
   any other way, and a decorrelated second opinion is cheap insurance before
   freezing a contract that fast-worker will build against.
3. Only once the interface is frozen does the mechanical move-and-rewire
   fan out to fast-worker (Sonnet), one file or one cohesive slice at a time,
   each against the same frozen interface, followed by build+test as the
   acceptance check and a fresh, blind reviewer for anything not cheaply
   verifiable (per the Verification stage).

## Sequence of tool calls (first three steps)

**Step 1 — Dispatch scout for full recon (data-handoff, not a summary).**
Only `general-purpose` is available this session (named subagents not yet
installed), so this uses the fallback path: `Agent(subagent_type:
"general-purpose", model: "haiku", …)` with the scout role preamble prepended
manually, since a bare Haiku generalist has no operating contract otherwise.

**Step 2 — Once scout returns, relay its full inventory (verbatim, unread by
me beyond skimming for the handoff) into a deep-reasoner dispatch** —
`Agent(subagent_type: "general-purpose", model: "opus", …)` with the
deep-reasoner preamble prepended, asking for the extraction design: target
package layout, public interface, what moves vs. stays, and the migration's
acceptance check. Scout's output is pasted into this dispatch's Inputs field
(or handed as a file path if it exceeds ~20 lines, which a 5-file/2000-line
inventory almost certainly will).

**Step 3 — Depending on what the design step's blast-radius/verifiability
picture looks like once I actually see scout's inventory**, either (a) run
Codex (`peer.sh --mode consult`) in parallel with deep-reasoner on the same
design question, blind, then reconcile per the parallel-path rules, or (b)
run deep-reasoner solo and route its frozen interface to Codex afterward as
an adversarial review pass before fast-worker starts building. I will decide
(a) vs. (b) from scout's concrete findings, not before — the skill is explicit
that row 3 fires on confirmed dual-condition, not on a guess.

I do not read handlers.go/middleware.go/session.go/tokens.go/store.go myself
at any point in this sequence unless a specific, narrow question later needs
a targeted read the executors couldn't resolve (e.g., adjudicating a
disagreement) — even then, that's a last resort, not a default.

## Full dispatch prompt — first delegation (scout recon)

```
Agent(subagent_type: "general-purpose", model: "haiku", prompt: "
You are acting as a read-only scout. Collect, don't judge — no fixes, no
design opinions. Your final message IS the return value.

Context: this recon feeds a deep-reasoner (Opus) design pass that will define
a new package boundary for extracting session-handling logic out of
src/auth; the design executor has not seen this code and will work only from
your inventory, so completeness matters more than brevity here.

Goal: Produce a full structural inventory of the auth module so the design
                  step can decide what moves into a new session package and
                  what stays in src/auth. Specifically, for each of the five
                  files, report:
                  1. Every top-level function/method/type declared, with its
                     exported/unexported status and a one-line description of
                     what it does.
                  2. Which of those are session-related (session creation,
                     lookup, validation, expiry/invalidation, storage,
                     session-to-token binding) versus auth-but-not-session
                     (e.g., login handler routing, password checks, pure
                     token issuance unrelated to session state) versus
                     ambiguous/could-go-either-way — call out the ambiguous
                     ones explicitly, do not silently classify them.
                  3. Cross-file coupling: which functions/types in one file
                     call, embed, or depend on functions/types in another of
                     the five files. Note shared structs, shared package-level
                     state (vars, consts, caches, mutexes), and any global
                     init-order dependency.
                  4. External callers: anything outside these five files
                     (elsewhere in the repo) that calls into them, especially
                     into whatever looks session-related — this defines the
                     public surface the new package must preserve.
                  5. Existing test coverage: which test files exist for this
                     module, and which of the session-related functions you
                     identified in (2) currently have tests versus none.
Inputs:           src/auth/handlers.go, src/auth/middleware.go,
                  src/auth/session.go, src/auth/tokens.go, src/auth/store.go
                  — read all five in full. Also search the rest of the repo
                  (grep/glob) for external references to symbols defined in
                  these five files, and for existing test files covering
                  src/auth.
Constraints:      Read-only — no edits, no fixes, no opinions on how the
                  extraction should be structured. If the module is larger
                  than expected or something looks incomplete, say exactly
                  what you covered and what you did not, rather than
                  silently truncating.
Acceptance check: Every claim in your inventory carries a path:line anchor
                  into the actual source (or the test file, for coverage
                  claims).
Return format:    Status first (DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT |
                  BLOCKED), then the full structured inventory grouped by the
                  five report sections above, each entry path:line anchored.
                  This is a data-handoff recon feeding another executor, not
                  a summary for a human — return the complete inventory,
                  uncompressed; do not cap it to a line budget or omit
                  entries to stay short. If any specific item requires design
                  judgment rather than fact-finding, list the fact you found
                  plus the note 'requires reasoning — route to deep-reasoner'
                  instead of deciding it yourself.
")
```

## Note on what I did not yet do

I did not decide the fast-worker fan-out shape (per-file vs. per-slice
dispatch, worktree isolation, etc.) because the skill's "Plan then fan out"
pattern requires the shared interface to be frozen first — deciding
partition boundaries before the interface exists risks fragmentation, the
exact failure mode the skill's guardrail section calls out. That decision
comes after step 2, using deep-reasoner's frozen interface as the contract
each fast-worker slice is checked against.
