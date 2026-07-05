# Plan: Extracting session-handling logic from src/auth into its own package

## Why reconnaissance comes first

I have not seen any of these five files. The user explicitly flagged the code as
"subtle" and wants it done "thoroughly and correctly" — that's a direct signal
that a blind delegation (telling an executor to go extract "session logic" out
of files I haven't read) is the wrong first move. If I dispatch a worker into
unfamiliar, security-sensitive code armed with only the user's one-paragraph
description, I'm gambling that the worker's read of "what counts as
session-handling logic" matches reality, and I have no independent basis to
check its work afterward. Before I write a single delegation prompt I need to
know:

- Where the actual seams are (does `session.go` cleanly own sessions, or is
  session state threaded through `handlers.go` and `middleware.go` too?)
- What's exported vs. unexported, and what currently depends on the public
  API of `src/auth` from outside the package (breaking external callers would
  be a bigger problem than the refactor itself)
- Whether there's shared mutable state (stores, caches, mutexes) that crosses
  the five files — the single riskiest thing to split incorrectly
- What test coverage exists today, since that's the safety net for verifying
  the refactor didn't change behavior

So step 1 is cheap, read-only reconnaissance — not a full redesign, just enough
of a map that I (the orchestrator) can make the real architectural call about
where the package boundary goes, and so that my first substantive delegation
prompt names real symbols and real risks instead of vague categories borrowed
from the user's summary.

## Tool call sequence (the first two or three steps that matter)

**Step 1 — Parallel, cheap, read-only structural recon (single message, multiple
tool calls, since these are independent queries with no ordering dependency):**

```
Bash: wc -l src/auth/handlers.go src/auth/middleware.go src/auth/session.go src/auth/tokens.go src/auth/store.go
Grep: pattern "^func " glob "src/auth/*.go" (function inventory, source order)
Grep: pattern "type \w+ struct|type \w+ interface" glob "src/auth/*.go" (core types)
Grep: pattern "sync\.(Mutex|RWMutex|Once)|package-level var" glob "src/auth/*.go" (shared-state red flags)
Glob: src/auth/**/*_test.go (existing test coverage)
Grep: pattern "\"<module-path>/src/auth\"" (external callers, searched repo-wide outside src/auth)
```

I run these together in one message because they're independent read-only
lookups — no reason to serialize them, and doing so just burns turns. The goal
at this stage isn't deep understanding, it's a cheap function/type/test
inventory and a first pass at where shared state lives, so I know what I'm
walking into before I commit real reading time or anyone else's execution time.

**Step 2 — I read all five files myself, in full.** Not delegated. Given the
user's explicit "subtle... thoroughly and correctly" framing, the one thing I
will not outsource is forming my own understanding of this code — I'm the one
who has to decide where the package boundary goes and whose judgment the user
is actually trusting here. Using `Read` directly on all five files is also
just cheaper than routing through a sub-agent and re-reading its summary, for
content I'm going to reason over myself rather than merely file away.

While reading, I build three concrete lists:
1. Every symbol (type/func/const/var) that is genuinely session-lifecycle
   (create / validate / refresh / expire / destroy / persist a session) versus
   everything else (login-handler orchestration, HTTP middleware wiring, token
   *format* concerns merely called by session code).
2. Every call site where a "stays in auth" file reaches into a "moves to
   sessions" symbol, and vice versa — this defines the new package's required
   public API and which direction the import edge has to run.
3. Anything that smells like shared mutable state (a package-level map, a
   singleton store, a mutex) touched from more than one file. This is the
   highest-risk category: splitting shared state across a package boundary can
   silently change locking or lifetime semantics even when every individual
   function "looks" correctly moved.

**Step 3 — Only now do I delegate**, and only the portion that's actually ready
to be delegated. Given the explicit correctness bar, I do not hand the whole
extraction to a single worker unsupervised in one shot. Concretely:

- I decide the target package layout and the new package's public API myself
  — optionally sanity-checking the boundary design with an Opus-pinned
  `deep-reasoner` agent as a second opinion, since this is exactly the kind of
  "hard, easy to get subtly wrong" call that benefits from a second pass before
  it's frozen. I produce a written extraction map: which symbols move
  verbatim, which need signature changes, and where a compatibility shim needs
  to stay behind in `auth` for existing external callers.
- I hand that concrete, frozen map to a `fast-worker` (Sonnet-pinned) as a
  fully mechanical task: move these named symbols to this named new package,
  update these named import paths, do not make judgment calls about what else
  belongs there.
- If Step 1/2 turned up thin or missing test coverage over the session-related
  symbols, I treat that as a blocker to close first — I'd add characterization
  tests for the current behavior before moving code, not after, so "no
  behavior changed" is actually checkable rather than assumed.
- After the move, I run the test suite myself and diff-review the actual
  result before calling it done — I don't take a worker's "done" at face value
  for code the user has called out as subtle. Given the stated bar of
  "thoroughly and correctly," I would also consider routing the final diff
  through Codex (`peer.sh`) as an independent, different-vendor review pass,
  since a worker checking its own move is a weaker guarantee than a second,
  independently-reasoning set of eyes.

In short: what the task calls "the first delegation" is the recon/mapping
pass, not the extraction itself, because right now I don't know enough about
this code to write a safe extraction prompt — and producing a
confident-sounding extraction prompt anyway would be worse than admitting I
need the information-gathering step first. Since no dedicated `scout` subagent
is installed in this session, I'd run this pass as
`Agent(subagent_type: "general-purpose", model: "haiku")`, instructed to be
strictly read-only.

## Full dispatch prompt for the first delegation (verbatim)

This is the prompt I'd send via the `Agent` tool
(`subagent_type: "general-purpose"`, `model: "haiku"`) for the first
delegation — a read-only mapping pass whose output feeds my own boundary
design and the later extraction delegation:

---

```
You are doing reconnaissance only — not refactoring, not designing, not
fixing anything. Do not edit any files. This is a read-only mapping task
whose output will be used by someone else (me) to design a package
extraction, so completeness and precision matter more than speed.

CONTEXT: We are about to extract all session-handling logic out of the
`auth` package (src/auth/handlers.go, src/auth/middleware.go,
src/auth/session.go, src/auth/tokens.go, src/auth/store.go — roughly 2000
lines total) into its own new package. I have not yet read these files and
need an accurate map before making any architectural decisions. The code's
owner describes it as "subtle" — assume there are non-obvious dependencies.
Do not guess or smooth over gaps: report exactly what you find, and flag
explicitly anywhere you're uncertain.

DO THE FOLLOWING, IN ORDER, AND REPORT ON EACH:

1. File inventory: for each of the five files, report its line count and
   every top-level declaration (func, type, const, var) in source order,
   noting exported vs. unexported.

2. Symbol classification: classify every declaration from step 1 as one of:
   (a) SESSION-CORE — directly manages session lifecycle (create, validate,
       refresh, expire, destroy, persist a session)
   (b) SESSION-ADJACENT — not session logic itself, but exists mainly to
       serve it (e.g. a token helper called only from session code)
   (c) NOT-SESSION — auth logic unrelated to sessions (login request
       handling, password/credential checks, unrelated middleware/routing)
   (d) UNCLEAR — cannot confidently classify from local reading; state
       exactly why (e.g. "used in both session and non-session contexts,"
       "name doesn't match observed behavior," "depends on code outside
       these 5 files"). Do not force a classification you're not confident
       in — (d) is a valid and useful answer; guessing wrong here is worse
       than saying "unclear."

3. Cross-file dependency map: for every SESSION-CORE or SESSION-ADJACENT
   symbol, list every reference to it (call, type use, pointer) located in
   NOT-SESSION-classified code, with file:line — this is the seam map for
   where the future package boundary gets crossed. Do the reverse too: every
   SESSION-CORE symbol that itself calls into NOT-SESSION code.

4. Shared mutable state: identify every package-level variable, singleton,
   in-memory store, cache, or lock (mutex/RWMutex/sync.Once/etc.) touched by
   more than one of the five files. For each, list every file and function
   that reads or writes it. This is the highest-risk category for the
   refactor — be exhaustive here even if it costs you time elsewhere.

5. External surface: search the rest of the repository (outside src/auth)
   for anything importing the auth package or referencing its exported
   session-related symbols directly. List every call site with file:line.
   This determines what breaks if symbols move without a compatibility shim.

6. Existing test coverage: list every test file exercising any of the five
   files (by name or import), and roughly what each covers (e.g.
   "TestSessionExpiry — covers session.go expiry logic only," "no test found
   covering store.go persistence"). Explicitly call out which SESSION-CORE
   symbols from step 2 have zero discoverable test coverage — these are the
   riskiest to move without a safety net.

7. Open questions: anything important for someone designing this extraction
   to know, even if it doesn't fit the categories above — naming
   inconsistencies, TODOs, apparent dead code, anything that looks like a
   workaround for a bug.

FORMAT: Use these exact seven numbered section headers so the output is easy
to parse. Use file:line references throughout instead of quoting large code
blocks. Do NOT propose a package design or extraction plan yourself — that
decision is intentionally being made by someone else after reviewing your
report. Your job is strictly to observe and report, not to recommend.

Return your complete findings as your final message text (this will be read
directly — do not write it to a file instead).
```

---

## What happens after this delegation returns

1. I read the recon report in full and personally verify anything marked
   UNCLEAR or flagged as high-risk (shared mutable state, untested
   SESSION-CORE symbols, external callers of soon-to-move symbols) by reading
   those specific sections myself — I don't take the report on faith for the
   risky parts, since surfacing exactly these traps before committing to a
   design was the entire point of doing recon first.
2. I design the new package's boundary and public API, optionally with an
   Opus-pinned `deep-reasoner` pass as a second opinion given the "subtle,
   must be correct" framing — producing a concrete extraction map: which
   symbols move verbatim, which need signature changes, where a
   backward-compatible shim must remain in `auth`, and how any shared mutable
   state from item 4 gets resolved (e.g., does a store's lock move wholesale
   into the new package, or does ownership need to change).
3. I check whether existing test coverage (item 6) is sufficient to trust a
   "no behavior change" refactor. If SESSION-CORE symbols have no coverage, I
   add characterization tests before moving code, not after — subtle,
   security-adjacent code deserves a safety net that predates the move, not
   one retrofitted to match whatever the move happened to produce.
4. Only then do I write a second, fully-specified dispatch prompt — this time
   to a `fast-worker` (Sonnet-pinned) — naming exact symbols, exact source and
   destination files/package paths, and exact import updates, since by that
   point the judgment calls have already been made and what remains is
   genuinely mechanical.
5. After the move, I verify directly: run the full existing test suite plus
   any new characterization tests, diff-review the actual changes myself, and
   likely route the final diff through Codex (`peer.sh`) for an independent,
   cross-vendor review pass before calling this "done" — given the user's
   explicit bar of "thoroughly and correctly," a single same-vendor pass
   checking its own work is not enough independent verification on its own.
