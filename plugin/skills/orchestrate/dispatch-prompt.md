# Dispatch Prompt Templates — orchestrate skill

The authoritative templates for every delegation. A dispatch prompt is never
improvised: pick the tier template, fill the brackets, delete fields that are
genuinely N/A — never the Acceptance check. Good dispatch prompts are
**focused** (one problem domain), **self-contained** (the executor has none of
your conversation history), and **specific about output** (status + format
stated up front).

## Skeleton — every dispatch, in this order

1. **Role preamble** — ONLY on the `general-purpose` fallback path and for the
   peer. Named subagents (deep-reasoner / fast-worker / scout) already carry
   their operating contract as a system prompt; repeating it is noise.
2. **Scene-setting** — one line: where this piece fits in the larger job.
3. **The contract** — the six fields.
4. **Inputs handoff** — ≤20 lines inline; anything bigger goes in as a file
   path introduced as *"Read this first — it is your requirements."*
5. **Operating skill** — ONLY when the custom roster injected a skill whose
   domain matches this dispatch: add to the Inputs — *"Read this first — it
   is your operating procedure; follow it: `<path>/SKILL.md`"*. The tier's
   contract and return format still bind. On the blind-parallel path this
   line is part of the verbatim task body both executors receive.
6. **Before-you-begin clause** — questions surface now, not mid-work.
7. **Report contract** — status vocabulary + final-message cap (+ report file
   for implement-type work).

## Status vocabulary — every executor, every dispatch

**The FIRST LINE of the final message is the status token — nothing before it, not even one sentence of narration** (field-tested: executors drift into preamble unless this is stated absolutely):

| Status | Meaning | Orchestrator's move |
|---|---|---|
| `DONE` | completed; acceptance check passed (evidence included) | verify, integrate |
| `DONE_WITH_CONCERNS` | completed, but doubts — listed | read concerns before using the result |
| `NEEDS_CONTEXT` | missing information — names exactly what | supply it, re-dispatch same tier (not a failure) |
| `BLOCKED` | cannot complete — what was tried, what would unblock | climb the escalation ladder |

Never silently deliver work you are unsure about: bad work is worse than no
work, and escalating is not penalized.

## Template — recon (scout)

```
[Fallback-path preamble only:
You are acting as a read-only scout. Collect, don't judge — no fixes, no
design opinions. Your final message IS the return value.]

Context: [one line — what decision this recon feeds]

Goal:             [what map/inventory/summary you need]
Inputs:           [exact paths / globs / search terms]
Constraints:      read-only; cover [scope]; if too large, say what you
                  covered and what you did not
Acceptance check: every claim carries a path:line anchor
Return format:    Status first, then ≤20 lines, grouped, path:line anchored.
                  If the question needs judgment, return the facts plus
                  "requires reasoning — route to deep-reasoner".
```

**Data-handoff recon:** if the recon output is an inventory feeding another
executor (not you), the ≤20-line cap does not apply — request the full
structured listing, never let it be truncated to fit a summary. You relay it
verbatim into the next dispatch (inline or via a file) and do not re-read it
yourself afterward.

## Template — mechanical (fast-worker)

```
[Fallback-path preamble only:
You are acting as the fast-worker — a mechanical executor. Execute
efficiently; do not redesign, second-guess the spec, or expand scope. Your
final message IS the return value. If a real design decision surfaces, stop
and return NEEDS_CONTEXT naming it — do not invent an answer.]

Context: [one line — where this fits]

Goal:             [one sentence — what done looks like]
Inputs:           [≤20 lines inline, or: "Read this first — it is your
                  requirements: /path/to/brief.md"]
Constraints:      [what must NOT change; files out of scope]
Interface:        [signatures / invariants — frozen, not yours to redesign]
Acceptance check: [command or objective test — REQUIRED; run it, paste output]
Return format:    Status first; final message ≤15 lines — what changed,
                  acceptance-check output, concerns. Write the full report
                  (files changed, test output, self-review) to
                  /path/to/report.md and return only status + summary + path.

Before you begin: if the goal, acceptance check, or inputs are unclear,
return NEEDS_CONTEXT now naming exactly what's missing — do not guess.
```

## Template — reasoning (deep-reasoner)

```
[Fallback-path preamble only:
You are acting as the deep-reasoner. Think thoroughly — alternatives, edge
cases, failure modes — that depth is why you were called. Your final message
IS the return value: lead with the answer, attach a checkable artifact for
anything the orchestrator can't cheaply verify, state your confidence and
what would make you wrong.]

Context: [one line — where this fits; what was already tried]

Goal:             [the decision/design/diagnosis needed — not the whole project]
Inputs:           [the digest — scout's map, error text, failed attempts;
                  >20 lines → file path, "Read this first"]
Constraints:      [hard requirements; what's already frozen]
Acceptance check: [what would prove the answer right — a test to write, a
                  property to hold, a reproduction to explain]
Return format:    Status first, then conclusion + the one or two load-bearing
                  reasons + "what would make this wrong", ≤20 lines.

If under-specified: state the assumption you made and proceed; return
NEEDS_CONTEXT only if genuinely blocked.
```

## Template — peer (Codex via peer.sh)

The peer has **no system prompt at all** — this framing is mandatory, every time:

```
You are a senior engineer giving an independent second opinion. Assume no
shared context: everything you need is in this prompt.

Context: [one line]
Task: [the task body — on the blind-parallel path this text must be
      VERBATIM identical to what deep-reasoner received]
Constraints: [same constraints the other executor got]
Return: conclusion first, then the load-bearing reasons, then what would
make you wrong. Conclusion + evidence, ≤20 lines.
```

## Template — blind reviewer (verification gate)

For the Verification-stage reviewer. **Fresh context — never the
implementer's conversation.** Pick the model tier by the calibration in
SKILL.md: Sonnet for a mid-size diff; **Opus, security focus, for a large or
any risk-domain diff** (and even when tests pass). On the Codex/fallback
path, prepend the peer preamble.

```
Context: blind review of a change you did not write; you have not seen the
         implementation conversation.

Goal:             Find defects and judge the approach of the change in <diff>.
Inputs:           The diff: <path>. The original contract's acceptance
                  criteria ONLY — nothing else from the build conversation.
Constraints:      Review the changed code PLUS its callers and callees.
                  [risk-domain:] explicit security/correctness focus.
Acceptance check: n/a — you are the check.
Return format:    Status first, then a DEFECT LIST — each item `path:line`
                  + why it is wrong — AND an explicit answer to: is there a
                  meaningfully simpler or safer approach? No approve/reject
                  verdict. A clean pass must still enumerate the specific
                  properties / attack classes you checked — not "LGTM".
```

## Worked example — mechanical tier, fallback path, filled

```
Agent(subagent_type: "general-purpose", model: "sonnet", prompt: "
You are acting as the fast-worker — a mechanical executor. Execute
efficiently; do not redesign, second-guess the spec, or expand scope. Your
final message IS the return value. If a real design decision surfaces, stop
and return NEEDS_CONTEXT naming it — do not invent an answer.

Context: part of extracting session logic out of src/auth (design frozen by
deep-reasoner; you are moving code, not designing).

Goal:             Move the five session-* functions listed in the brief from
                  src/auth/session.go to the new package src/session, updating
                  all imports.
Inputs:           Read this first — it is your requirements:
                  /tmp/session-extract-brief.md (symbol list + target layout)
Constraints:      Do not modify function bodies. Do not touch
                  src/auth/tokens.go or src/auth/store.go.
Interface:        Exported names stay identical; package name is `session`.
Acceptance check: `go build ./... && go test ./src/auth/... ./src/session/...`
                  — run it, paste the tail of the output.
Return format:    Status first; ≤15 lines — files changed, check output,
                  concerns. Full report to /tmp/session-extract-report.md.

Before you begin: if the brief's symbol list conflicts with what you find in
the code, return NEEDS_CONTEXT with the mismatch — do not resolve it yourself.
")
```

## Common mistakes

| Mistake | Fix |
|---|---|
| Too broad ("fix all the tests") | One problem domain per dispatch |
| No context ("fix the race condition") | Paste the error text, name exact files |
| No constraints | State what must NOT change — executors expand scope otherwise |
| Vague output ("fix it") | Acceptance check + status + return format, always |
| Pasting session history | A dispatch describes one task; bulk goes in as a file path |
| Broadcasting an injected skill into every dispatch | Inject only where the task matches the skill's described domain |
| Repeating the role contract to a *named* subagent | Preamble is for the fallback path and the peer only |
| Different task wording per executor on the blind-parallel path | Task body verbatim identical; only the preamble differs |
