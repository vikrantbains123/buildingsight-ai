# Spec 001: Mock Property-Management System (PMS)

**Status:** Draft — awaiting Claude Code (Opus 5.5) spec review, then test authoring
**Blueprint:** §2 (`pms_mock/`), §5a (Executor), §6b (contract tests) · **Constitution:** #3, #10
**Depends on:** — (first spec; Day 1 build) · **Blocks:** 004 (duplicate checker), 005 (executor)

## Goal

A small FastAPI + SQLite service that stands in for an enterprise property-management
platform. It stores units, departments, and work orders; the BuildingSight pipeline
reads it (duplicate check) and — only after human approval — writes to it (executor).
It deliberately has **no DELETE endpoint**: the action allowlist (create/update only)
is enforced by the API surface itself, not just by client code.

## Data model

Stored in SQLite (`pms_mock/pms.db`, created from `data/seed/pms_seed.json` on first boot).

### Unit
| Field | Type | Notes |
|---|---|---|
| `id` | string (PK) | e.g. `unit-2b` |
| `label` | string | e.g. `Unit 2B` |
| `building` | string | e.g. `Building A` |

### Department
| Field | Type | Notes |
|---|---|---|
| `id` | string (PK) | e.g. `dept-plumbing` |
| `name` | string | Must match a value in `config/departments.yaml` |

### WorkOrder
| Field | Type | Notes |
|---|---|---|
| `id` | string (PK) | Server-generated, e.g. `wo-1001` |
| `unit_id` | string (FK → Unit) | |
| `department_id` | string (FK → Department) | |
| `category` | string (enum) | One of the keys in `config/departments.yaml` |
| `title` | string | 1–120 chars |
| `description` | string | 1–2000 chars |
| `priority` | enum | `low` \| `medium` \| `high` \| `urgent` |
| `status` | enum | `open` \| `in_progress` \| `done` (no `deleted`) |
| `evidence_refs` | list[string] | Frame paths / transcript spans; may be empty on create, appended on update |
| `notes` | list[string] | Append-only update notes (audit-friendly) |
| `idempotency_key` | string \| null | Unique when present; re-POST with same key returns the original order |
| `created_at` / `updated_at` | ISO-8601 UTC | Server-set |

### Seed data (`data/seed/pms_seed.json`)
- Units: `unit-2b` (Unit 2B), `unit-1a` (Unit 1A), `unit-lobby` (Main Lobby / Entrance).
- Departments: one per value in `config/departments.yaml`.
- **One pre-existing open work order:** leaking kitchen faucet, Unit 2B, category `plumbing`,
  priority `high`, status `open` — the duplicate-check demo case (Spec 004, AC-004-03).

## API contract

Source of truth: [docs/api/pms-openapi.yaml](../../docs/api/pms-openapi.yaml) (written with this spec; contract tests derive from it).

| Method & path | Purpose |
|---|---|
| `GET /health` | Liveness: `{"status": "ok"}` |
| `GET /units` | List units |
| `GET /departments` | List departments |
| `GET /work-orders` | List; filters: `unit_id`, `category`, `status`, `q` (title/description substring) — used by the Duplicate Checker |
| `GET /work-orders/{id}` | One work order; `404` if unknown |
| `POST /work-orders` | Create (`201`); honors `Idempotency-Key` header |
| `PATCH /work-orders/{id}` | Partial update: `status`, `priority`, append `evidence_refs` / `notes`; `404` if unknown |
| `DELETE /work-orders/{id}` | **Must return `405`** — endpoint does not exist by design |

Validation: unknown `unit_id`/`department_id`/`category`/`priority`/`status` → `422` with a field-level error body. No endpoint ever deletes or hard-closes a work order.

## Acceptance criteria

> Reviewer (Claude Code): write one failing test per criterion in `tests/contract/` (API behavior) or `tests/unit/` (seed/schema), tagged `@pytest.mark.ac("AC-001-NN")`. Builder (Muse Code): implement until green; do not edit the tests.

- **AC-001-01:** *Given* a freshly seeded PMS, *when* `GET /units` and `GET /departments` are called, *then* both return `200` with the seeded units and one department per `config/departments.yaml` value. Guardrail impact: none.
- **AC-001-02:** *Given* the seed data, *when* `GET /work-orders?unit_id=unit-2b&category=plumbing&status=open` is called, *then* exactly the pre-existing leaking-faucet work order is returned. Guardrail impact: duplicate-check correctness depends on this filter.
- **AC-001-03:** *Given* a valid payload, *when* `POST /work-orders` is called, *then* it returns `201` with a server-generated `id` and timestamps, and a subsequent `GET /work-orders/{id}` returns the same record. Guardrail impact: none.
- **AC-001-04:** *Given* an existing work order, *when* `PATCH /work-orders/{id}` appends an evidence ref and a note, *then* `200` is returned, the appended values are present, and prior `evidence_refs`/`notes` are preserved (append-only, never replaced). Guardrail impact: audit integrity (Spec 005).
- **AC-001-05:** *Given* any work-order id, *when* `DELETE /work-orders/{id}` is called, *then* the response is `405` and the record still exists. Guardrail impact: **action allowlist** — `test_delete_action_blocked` (blueprint §6d).
- **AC-001-06:** *Given* an unknown id, *when* `GET` or `PATCH /work-orders/{id}` is called, *then* the response is `404`. Guardrail impact: none.
- **AC-001-07:** *Given* a payload with an unknown `unit_id`, `category`, or `priority`, *when* `POST /work-orders` is called, *then* the response is `422` and no record is created. Guardrail impact: schema rejection (blueprint §6d).
- **AC-001-08:** *Given* a create request with an `Idempotency-Key` header, *when* the identical request is POSTed twice, *then* both responses return the same work-order `id` and exactly one record exists. Guardrail impact: idempotent execution — `test_rerun_is_noop` (Spec 005).
- **AC-001-09:** *Given* the running PMS, *when* `GET /health` is called, *then* it returns `200 {"status": "ok"}` without authentication. Guardrail impact: none.

## Out of scope

Auth/multi-tenancy, pagination beyond a simple `limit`, real PMS integrations (Yardi/AppFolio), UI. Those are post-hackathon.
