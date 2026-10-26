# Dev workflow: SDD + TDD + agentic review

> Blueprint §1, §6, §7. Agent rules: [AGENTS.md](../AGENTS.md).

## Roles

- **Builder — Muse Code** (`muse-wonder-1.0`, local): Spec Kit specs/plans/tasks; implements code until tests pass. Never edits `tests/**` or `eval/ground_truth/**` on `impl` PRs.
- **Reviewer — Claude Code** (Opus 5.5): writes failing tests from AC IDs; local `/code-review` before every push; `engine: claude` for all agentic workflows. Needs `ANTHROPIC_API_KEY` repo secret.
- **Decider — you:** approve specs, merge PRs, own the demo.

## Spec Kit flow (per spec 001–006)

1. `specify init . --integration muse` (Day 0 — confirm Muse slash-command syntax).
2. `/speckit-constitution` → Muse Code drafts, Claude Code reviews against the blueprint.
3. Per spec: `specify` → `clarify` → `plan` → `tasks` → `implement` → `converge`.
4. Acceptance criteria: Given/When/Then with IDs (`AC-004-03`). Every AC gets ≥1 test tagged `@pytest.mark.ac("AC-004-03")`.

## Labels

| Label | Meaning |
|---|---|
| `impl` | Muse Code implementation PR — CI blocks changes to `tests/**`, `eval/ground_truth/**` |
| `tests-change-approved` | You approve a test change on an `impl` PR (exception to the above) |
| `needs-tests` | Issue ready for the Test Writer workflow (Claude Code writes failing tests) |
| `run-evals` | Triggers live evals (`evals.yml`) |

## CI gates (must pass to merge)

- `ci.yml`: ruff → pyrefly → unit + contract + integration (replay) + guardrail tests → `scripts/check_ac_coverage.py` → test-integrity check.
- `evals.yml` (when it runs): live evals vs `eval/thresholds.yaml`.
- `aw-compile.yml`: `gh aw compile` output is up to date.

## Review checklist (Claude Code, every PR)

1. Each claimed AC (`AC-xxx-yy`) → the test covering it.
2. No PMS write path bypassing `policy.py` + approval hash check.
3. New prompts have a guardrail test in `tests/guardrails/`.
4. Cassette changes (if any) explained in the PR description.
