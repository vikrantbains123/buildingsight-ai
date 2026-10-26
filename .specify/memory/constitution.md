# BuildingSight AI — Constitution

> Every spec, plan, and PR must follow these principles. Reviewer: Claude Code (Opus 5.5) checks specs and PRs against this file.
> Blueprint: [docs/project-blueprint.md](../../docs/project-blueprint.md)

## Principles

1. **Meta models first.** Perception, reasoning, transcription, and judging use Meta models via the Meta Model API (Muse Spark, Muse Wonder, SAM 3.1, Muse Voice Transcribe, Muse Image). Local open-weights models (Llama Guard, Prompt Guard) only for guardrails.
2. **No evidence, no ticket.** Every issue must cite at least one evidence reference — a video frame/timestamp or a transcript span. An issue without evidence is dropped, never filed.
3. **Human approval before any write.** The pipeline produces an `ActionPlan` as data. Nothing writes to the PMS until a human approves that exact plan, verified by SHA-256 hash.
4. **Tests before code; every acceptance criterion has a test.** Specs define `AC-NNN-NN` criteria (Given/When/Then). Claude Code (reviewer) writes the failing tests. `scripts/check_ac_coverage.py` fails CI if any criterion is untested.
5. **The builder (Muse Code) never writes or edits its own tests.** Implementation PRs (label `impl`) may not change `tests/**` or `eval/ground_truth/**` without the `tests-change-approved` label.
6. **Deterministic CI through the replay cache.** CI runs on recorded model responses (`CACHE_MODE=replay`). No API keys, no cost, same result every run. Live models only in evals.
7. **Privacy by default.** People and faces are blurred (SAM 3.1 `person` masks) before any evidence image is saved. Phone numbers and emails are redacted from transcripts and tickets.
8. **No secrets in the repo.** Keys come from `.env` / CI secrets only. `.env.example` documents names, never values.
9. **Scope fits 9 days.** Hackathon: Oct 26 – Nov 4, 2026, submit by afternoon of Nov 4. Cut list (in order): Docs Sync → Red Teamer → Muse Image synthetic set → Test Writer workflow → Muse Wonder judge. Never cut: demo flow, approval gate, face blur, replay mode, `ci.yml`.
10. **Actions are allowlisted.** The executor may only `create` or `update` work orders. No delete, no close. The mock PMS exposes no DELETE endpoint.

## Acceptance criteria format

```
**AC-004-03:** *Given* an open plumbing ticket for Unit 2B's kitchen faucet,
*when* the walkthrough shows a leaking faucet in Unit 2B,
*then* the plan contains `update(ticket_id)` with new evidence and no `create` for that issue.
```

Every criterion must be testable, must name its guardrail impact (or "none"), and must be covered by ≥1 test tagged `@pytest.mark.ac("AC-004-03")`.
