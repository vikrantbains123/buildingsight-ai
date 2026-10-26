# ADR-0001: Meta model stack

**Status:** Accepted (Day 0) · **Deciders:** Vikrant Bains · **Reviewer:** Claude Code (Opus 5.5)

## Context

BuildingSight AI must understand a property walkthrough (video + speech), ground issues visually, reason about duplicates, and produce work orders — within a 9-day hackathon (Oct 26 – Nov 4, 2026), using the Meta Global AI Developer Hackathon stack.

## Decision

| Capability | Choice | Why |
|---|---|---|
| Scene analysis, issue extraction, work-order writing | **Muse Spark 1.1** (Meta Model API) | Vision-capable; listed with image input. Check on Day 0 whether 1.2/1.3 also accept images. |
| Duplicate judgment + eval judge | **Muse Wonder** (Meta Model API) | Multi-step reasoning with PMS tool calls; a *different* model judging evals reduces self-grading bias. |
| Segmentation + video tracking + people masks | **SAM 3.1** (Meta Model API) | Text-prompted segmentation and tracking for evidence images; `person` masks drive privacy blur. |
| Speech-to-text | **Muse Voice Transcribe** (Meta Model API) | Timestamped segments — required for the voice-only thermostat issue. |
| Synthetic eval images | **Muse Image** (Meta Model API) | Generates issue/negative stills and adversarial signage for guardrail tests. |
| Content safety / injection detection | **Llama Guard 4**, **Prompt Guard 2** (open weights, PyTorch) | Local guardrails on generated text, transcripts, and text read from frames. Fall back to Llama Guard 3-1B if too slow locally. |
| Builder / reviewer | **Muse Code** builds; **Claude Code (Opus 5.5)** reviews | Separation of test authorship from implementation. See [AGENTS.md](../../AGENTS.md). |

All Meta Model API access goes through the OpenAI-compatible Python SDK (`clients/meta_llm.py`), so model IDs are configuration, not code.

## Consequences

- Day 0 spike must confirm: exact model IDs, which Muse Spark versions accept images, structured-JSON support, SAM 3.1 video input limits, and Transcribe timestamp granularity (blueprint §9).
- If Muse Wonder is unavailable, the cut list falls back to Muse Spark for judging (noted as a bias risk in eval docs).
