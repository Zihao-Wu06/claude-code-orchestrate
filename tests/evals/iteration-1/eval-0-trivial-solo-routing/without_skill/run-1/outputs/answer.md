I'll work through this as the orchestrator would, then save the plan.

The plan:

1. **Read** `/Users/zihaowu/skill/README.md` (just enough to confirm line 3 and the exact surrounding text) — a single targeted read, not a full-file dump if avoidable, though for a 3-line check reading the whole file is cheap and fine.
2. **Edit** the file directly: `old_string: "teh quick brown fox"`, `new_string: "the quick brown fox"`.
3. **Bash**: `git diff README.md` (or just re-read the line) to confirm the change landed correctly.
4. Report back to the user in one sentence that it's done.

**No delegation.** I will not spawn `deep-reasoner`, `fast-worker`, or `scout`, and I will not call `peer.sh`/Codex. Reasoning: orchestration has fixed overhead (subagent spin-up, context handoff, a synthesis step to fold results back in) that only pays off when the task has enough surface area — multiple files, ambiguity, or domain judgment — to amortize it. A single-word, single-line, unambiguous string replacement in a known file is below that threshold on every axis: scope (1 file), ambiguity (0 — the fix is fully specified), and risk (trivial to verify by rereading the line). Routing it through `scout` to "locate" a file whose path the user already gave me, or through `fast-worker` for a one-string `Edit` call I can make myself, would add latency and indirection without adding correctness or speed. The right call for a solo-sized task is to solo it.
