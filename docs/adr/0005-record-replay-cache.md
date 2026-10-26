# ADR-0005: Record/replay cache for deterministic CI

**Status:** Accepted (Day 0) · **Deciders:** Vikrant Bains · **Reviewer:** Claude Code (Opus 5.5)

## Context

CI must be fast, free, and deterministic — but the pipeline calls paid, non-deterministic models (Muse Spark, Muse Wonder, SAM 3.1, Transcribe). Live calls in CI would need API keys, cost money, and flake.

## Decision

All model clients go through `src/buildingsight/clients/cache.py`, keyed by a hash of the normalized request:

- `CACHE_MODE=record` — call the live API, save the response under `tests/fixtures/cassettes/`.
- `CACHE_MODE=replay` — return the recorded response; **fail loudly** if no cassette matches (never silently call the API).
- `CACHE_MODE=off` — always call live (local exploration only).

CI always runs `replay`. Evals (`eval/`) always run live. The demo can run in `replay` as a resilience fallback if the venue network or API fails.

## Consequences

- Prompt or model changes require re-recording cassettes (`make replay` after a `record` run) — this is intentional friction that surfaces behavior changes in review.
- Cassettes are test fixtures: `impl` PRs may not edit `eval/ground_truth/**`, and cassette changes must be called out in the PR description for the Claude Code reviewer.
