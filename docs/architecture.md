# Architecture

> Day 1 draft; updated Day 7. Blueprint: [project-blueprint.md](project-blueprint.md) §2, §5a.

## Data flow (one run)

```
iPhone walkthrough video (future: Ray-Ban Meta glasses)
  → [002] Ingest: ffmpeg keyframes + audio → Muse Voice Transcribe (timestamped)
  → [003] Perception: Muse Spark scene analysis → SAM 3.1 grounding/tracking → privacy blur
  → [004] Agents: Issue Extractor → Triage (category → departments.yaml) →
        Duplicate Checker (Muse Wonder + PMS search) → Work Order Writer → ActionPlan
  → [005] Human approval (Streamlit UI / CLI) → Executor (hash-verified, idempotent) → Mock PMS
  → Audit log (append-only JSONL, plan hash) at every step
```

## Components

| Component | Path | Spec |
|---|---|---|
| Mock PMS (FastAPI + SQLite) | `pms_mock/` | 001 |
| Ingest + transcribe + replay cache | `src/buildingsight/ingest/`, `clients/` | 002 |
| Perception (scene, grounding, privacy) | `src/buildingsight/perception/` | 003 |
| Agent pipeline + orchestrator | `src/buildingsight/agents/`, `orchestrator.py` | 004 |
| Approval UI + executor + audit | `ui/app.py`, `executor.py`, `audit.py` | 005 |
| Evals + guardrails | `eval/`, `src/buildingsight/guardrails/` | 006 |

## Key decisions

- [ADR-0001: Meta model stack](adr/0001-meta-model-stack.md) — Muse Spark / Wonder / SAM 3.1 / Transcribe; Llama Guard + Prompt Guard locally.
- ADR-0002 (Day 1): Muse Spark names issues; SAM 3.1 segments and tracks them.
- ADR-0003 (Day 1): Model classifies category; `config/departments.yaml` maps it to a department.
- ADR-0004 (Day 1): Plan as data, single approval, hash-verified execution.
- [ADR-0005: Record/replay cache](adr/0005-record-replay-cache.md) — deterministic CI, demo resilience.

_Diagram + run sequence diagram: add Day 7 (`docs/images/`)._
