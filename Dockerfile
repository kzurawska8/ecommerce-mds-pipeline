# --- Build stage: resolve and install dependencies with uv -------------------
FROM python:3.12-slim AS builder

COPY --from=ghcr.io/astral-sh/uv:0.13.5 /uv /bin/uv

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0

WORKDIR /app

# Dependencies first, in their own layer: rebuilt only when the lockfile
# changes, not on every source edit.
COPY pyproject.toml uv.lock ./
RUN uv sync --locked --no-dev --no-install-project

# Then the project itself, installed as a regular (non-editable) package so
# the runtime image needs only the virtualenv, not the source tree.
COPY src ./src
RUN uv sync --locked --no-dev --no-editable

# --- Runtime stage: just Python + the virtualenv, running as non-root --------
FROM python:3.12-slim

RUN useradd --create-home --uid 1000 app

COPY --from=builder --chown=app:app /app/.venv /app/.venv

ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1

USER app
WORKDIR /home/app

ENTRYPOINT ["ingest"]
