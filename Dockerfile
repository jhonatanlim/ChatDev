# ---- Builder: install deps with compilers and uv ----
FROM python:3.12-slim AS builder
ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /app

# System deps required to build Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    build-essential \
    python3-dev \
    libcairo2-dev \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir uv

ENV UV_PROJECT_ENVIRONMENT=/opt/venv

COPY pyproject.toml ./
COPY uv.lock ./
RUN uv sync --no-cache --frozen

# ---- Runtime ----
FROM python:3.12-slim AS runtime
ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcairo2 \
 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/venv /opt/venv
COPY . .

ENV PATH="/opt/venv/bin:${PATH}" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    BACKEND_BIND=0.0.0.0

RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Render injects PORT at runtime; 10000 is a local/default fallback.
EXPOSE 10000
CMD ["sh", "-c", "python server_main.py --port ${PORT:-10000} --host 0.0.0.0"]
