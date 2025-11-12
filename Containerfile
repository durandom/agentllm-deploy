# syntax=docker/dockerfile:1.4

#
# Multi-stage Containerfile for AgentLLM with plugin support
#
# Supports both Docker and Podman
#
# Build arguments:
#   CORE_VERSION    - agentllm-core version (default: 0.1.0)
#   RHDH_VERSION    - agentllm-agents-rhdh version (default: 1.0.0)
#   DEMO_VERSION    - agentllm-agents-demo version (default: 1.0.0)
#   INSTALL_DEMO    - Install demo agents (default: true)
#   PYTHON_VERSION  - Python version (default: 3.11)
#

ARG PYTHON_VERSION=3.11

# ============================================================================
# Stage 1: Base image with system dependencies
# ============================================================================
FROM python:${PYTHON_VERSION}-slim AS base

LABEL maintainer="AgentLLM Team"
LABEL description="AgentLLM proxy with plugin support"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create app user (non-root for security)
RUN useradd -m -u 1000 -s /bin/bash agentllm

WORKDIR /app

# Install uv for faster package management
RUN pip install --no-cache-dir uv

# ============================================================================
# Stage 2: Install agentllm-core
# ============================================================================
FROM base AS with-core

ARG CORE_VERSION=0.1.0

RUN echo "Installing agentllm-core==${CORE_VERSION}"

# Option 1: Install from PyPI (when published)
# RUN pip install --no-cache-dir agentllm-core==${CORE_VERSION}

# Option 2: Install from git repository
RUN pip install --no-cache-dir \
    git+https://github.com/yourorg/agentllm-core.git@v${CORE_VERSION}

# Option 3: Install from local wheel (for air-gapped environments)
# COPY wheels/agentllm_core-${CORE_VERSION}-py3-none-any.whl /tmp/
# RUN pip install --no-cache-dir /tmp/agentllm_core-${CORE_VERSION}-py3-none-any.whl

# Verify installation
RUN python -c "import agentllm; print(f'agentllm-core {agentllm.__version__} installed')"

# ============================================================================
# Stage 3: Install RHDH agents
# ============================================================================
FROM with-core AS with-rhdh

ARG RHDH_VERSION=1.0.0

RUN echo "Installing agentllm-agents-rhdh==${RHDH_VERSION}"

# Option 1: Install from PyPI
# RUN pip install --no-cache-dir agentllm-agents-rhdh==${RHDH_VERSION}

# Option 2: Install from git repository
RUN pip install --no-cache-dir \
    git+https://github.com/yourorg/agentllm-agents-rhdh.git@v${RHDH_VERSION}

# Verify installation
RUN python -c "from agentllm_agents_rhdh import ReleaseManagerFactory; print('RHDH agents installed')"

# ============================================================================
# Stage 4: Optionally install demo agents
# ============================================================================
FROM with-rhdh AS with-demo

ARG DEMO_VERSION=1.0.0
ARG INSTALL_DEMO=true

RUN if [ "$INSTALL_DEMO" = "true" ]; then \
    echo "Installing agentllm-agents-demo==${DEMO_VERSION}" && \
    pip install --no-cache-dir \
        git+https://github.com/yourorg/agentllm-agents-demo.git@v${DEMO_VERSION} && \
    python -c "from agentllm_agents_demo import DemoAgentFactory; print('Demo agents installed')"; \
    else \
    echo "Skipping demo agents installation"; \
    fi

# ============================================================================
# Stage 5: Final production image
# ============================================================================
FROM with-demo AS final

# Copy configuration files
COPY custom_handler.py /app/
COPY proxy_config.yaml /app/

# Create data directory for SQLite database
RUN mkdir -p /app/tmp && chown agentllm:agentllm /app/tmp

# Switch to non-root user
USER agentllm

# Expose LiteLLM proxy port
EXPOSE 8890

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8890/health || exit 1

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    AGENTLLM_DATA_DIR=/app/tmp

# Entry point
CMD ["litellm", "--config", "/app/proxy_config.yaml", "--port", "8890"]

# ============================================================================
# Development target (includes all agents)
# ============================================================================
FROM final AS development

USER root

# Install development tools
RUN pip install --no-cache-dir \
    ipython \
    pytest \
    pytest-asyncio

# Install all agents in editable mode if mounted
# (Expects agent packages to be volume-mounted at /workspace)

USER agentllm

CMD ["litellm", "--config", "/app/proxy_config.yaml", "--port", "8890", "--debug"]
