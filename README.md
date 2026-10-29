# BuildingSight AI

**Walk the Property. AI Handles the Work.**

BuildingSight AI turns a routine property walkthrough into finished maintenance work — no manual ticket entry. A staff member records a short walkthrough (today: an iPhone video; tomorrow: Meta AI glasses). The system spots issues, pulls visual evidence, checks for duplicate tickets, drafts department-ready work orders, and files them after **one human approval**.

Built for the **Meta Global AI Developer Hackathon 2026** (Indie track · *Build for Your World*) with Meta SAM 3.1, Muse Spark, and Muse Wonder via the Meta Model API.

> **Status:** Day 0 scaffold (Oct 26, 2026). Specs and architecture are in place; implementation follows the spec-driven plan in [docs/project-blueprint.md](docs/project-blueprint.md). Demo GIF and screenshots land Day 7.

<!-- Demo GIF: docs/images/demo.gif (Day 7) -->

## The demo

One 60-second walkthrough finds **4 issues → 3 new work orders + 1 update**:

| # | What the walkthrough shows | What BuildingSight AI does |
|---|---|---|
| 1 | Packages blocking the building entrance | New safety work order → Safety & Compliance |
| 2 | Leaking faucet in Unit 2B | Finds the **existing** open plumbing ticket and updates it with fresh evidence — no duplicate |
| 3 | Damaged wall paint | New work order → Painting & Drywall |
| 4 | Broken thermostat (mentioned only in speech) | Transcribed, triaged → HVAC — no photo needed |

Every issue links to its evidence (frame or transcript span). **No evidence, no ticket.** Nothing is filed until a person approves the plan.

## How it works

```
Walkthrough video ──► Ingest ──► Perception ──► Agent pipeline ──► Approval ──► PMS
 (iPhone today,      ffmpeg +    Muse Spark      extract → triage    1 click    mock
  glasses tomorrow)  Transcribe  + SAM 3.1       → dedupe → write   + hash     FastAPI
                                                (blur faces)       ActionPlan  + audit
```

- **Muse Spark** reads keyframes + transcript and names candidate issues.
- **SAM 3.1** segments and tracks the issue objects, producing annotated evidence images — and masks people so faces are blurred before anything is saved.
- **Agent pipeline** extracts issues, triages category/priority, and routes deterministically via [config/departments.yaml](config/departments.yaml) (the model picks the category, never the department).
- **Muse Wonder** judges duplicate-vs-create against open tickets in the mock PMS.
- **Executor** applies only the approved, hash-verified plan (create/update only — no delete, ever) and writes an append-only audit log.

Details: [docs/architecture.md](docs/architecture.md) · Decisions: [docs/adr/](docs/adr/) · Guardrails: blueprint §6d (catalog in `docs/guardrails.md`, Day 2).

## Tech stack

| Layer | Choice |
|---|---|
| Perception / reasoning | Muse Spark, SAM 3.1, Muse Voice Transcribe (Meta Model API) |
| Duplicate judgment / eval judge | Muse Wonder (a different model judges, to avoid self-grading) |
| Guardrails | Llama Guard 4 + Prompt Guard 2 (local, open weights) |
| Backend | Python 3.11, FastAPI + SQLite (mock PMS), Pydantic schemas |
| UI | Streamlit approval UI + `buildingsight` CLI |
| Tooling | uv, ruff, pyrefly, pytest; record/replay cache for deterministic CI |

## Quickstart

Prerequisites: Python 3.11+, [uv](https://docs.astral.sh/uv/), ffmpeg.

```bash
git clone https://github.com/vikrantbains123/buildingsight-ai.git
cd buildingsight-ai
cp .env.example .env        # add your META_API_KEY
make setup                  # uv sync + pre-commit hooks
make pms                    # mock property-management system → http://localhost:8000
make ui                     # approval UI (Streamlit)
make test                   # deterministic tests (replay cache, no API keys)
```

CLI (Specs 004–005): `buildingsight analyze <video.mp4>`, then approve the plan — see [AGENTS.md](AGENTS.md) for all commands and [docs/runbook.md](docs/runbook.md) (Day 7) for demo/replay troubleshooting.

## How this project is built

Spec-driven, test-first, two-agent workflow ([AGENTS.md](AGENTS.md) · [constitution](.specify/memory/constitution.md)):

1. **Spec** — every feature starts as `specs/NNN-*/spec.md` with numbered acceptance criteria (`AC-001-01`, Given/When/Then).
2. **Tests first** — Claude Code (Opus 5.5, reviewer) writes failing tests from the criteria. **Muse Code (muse-wonder-1.0, builder)** implements until they pass and may not edit the tests — no passing by writing easy tests.
3. **Gates** — deterministic CI (replay cache), eval thresholds (`eval/thresholds.yaml`), and a tested guardrail catalog gate every merge.

| Spec | Feature | Status |
|---|---|---|
| 001 | Mock PMS (FastAPI + SQLite, seeded faucet ticket) | Spec drafted |
| 002 | Ingest + transcribe (keyframes, timestamped transcript) | Planned Day 2 |
| 003 | Perception (scene analysis, SAM grounding, face blur) | Planned Day 3 |
| 004 | Agent pipeline (extract → triage → dedupe → write) | Planned Day 4 |
| 005 | Approval UI, executor, audit log | Planned Day 5 |
| 006 | Evals + guardrails | Planned Day 4–6 |

Full blueprint, day-by-day plan, and cut list: [docs/project-blueprint.md](docs/project-blueprint.md).

## Why it matters

Property teams lose ~118 staff hours per property per year to inspection paperwork — roughly **$5,500 per 300-unit property, $550K across 100 properties** (assumptions in `docs/roi.md`, Day 7). BuildingSight AI gives that time back: staff walk and observe; AI documents, routes, and follows up. Longer term: hands-free inspections on Meta AI glasses across multifamily, commercial, hospitality, and facilities portfolios.

## Repo layout

`src/buildingsight/` (clients, ingest, perception, agents, guardrails, orchestrator, executor) · `pms_mock/` · `ui/` · `specs/` · `tests/` · `eval/` · `config/` · `data/seed/` · `docs/`

## License

MIT — see [LICENSE](LICENSE).
