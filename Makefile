.PHONY: setup pms run ui test eval guardrails replay lint typecheck

setup: ## Install deps (uv) + pre-commit hooks
	uv sync --extra dev --extra ui
	uv run pre-commit install

pms: ## Run mock property-management system
	uv run uvicorn pms_mock.app:app --reload --port 8000

run: ## Analyze a video: make run VIDEO=path/to/video.mp4
	uv run buildingsight analyze $(VIDEO)

ui: ## Streamlit approval UI
	uv run streamlit run ui/app.py

test: ## Deterministic tests (replay cache, no API keys)
	CACHE_MODE=replay uv run pytest tests/ -x -q

eval: ## Live evals (needs META_API_KEY)
	uv run python eval/run_eval.py

guardrails: ## Guardrail test suite only
	CACHE_MODE=replay uv run pytest tests/guardrails/ -q

replay: ## Integration replay run
	CACHE_MODE=replay uv run pytest tests/integration/ -q

lint:
	uv run ruff check src/ pms_mock/ ui/ tests/
	uv run ruff format --check src/ pms_mock/ ui/ tests/

typecheck:
	uv run pyrefly check src/
