# ==============================================================================
# Production Dockerfile for ComfyUI v0.45.5
# Target: Python 3.12 on Ubuntu 24.04 with NVIDIA CUDA 12.6 Runtime
# ==============================================================================
ARG BASE_IMAGE=nvidia/cuda:12.6.3-runtime-ubuntu24.04
FROM ${BASE_IMAGE}

LABEL maintainer="ComfyUI Docker Setup"
LABEL description="ComfyUI container with Python 3.12, CUDA acceleration, and external persistent storage"

# Configure environment settings
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_PREFER_BINARY=1 \
    PATH="/opt/venv/bin:$PATH" \
    COMFYUI_PORT=8188 \
    NVIDIA_VISIBLE_DEVICES=all \
    COMMANDLINE_ARGS=""

WORKDIR /app

# Install system dependencies (Python 3.12, git, ffmpeg, OpenGL/GLib libraries, build essentials)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create and activate an isolated Python 3.12 virtual environment
RUN python3 -m venv /opt/venv && \
    pip install --upgrade pip setuptools wheel

# Install PyTorch with CUDA support (defaults to CUDA 12.4 / 12.6 compatible wheels)
# For CPU-only builds: pass --build-arg TORCH_INDEX_URL=https://download.pytorch.org/whl/cpu
ARG TORCH_INDEX_URL="https://download.pytorch.org/whl/cu124"
RUN pip install torch torchvision torchaudio --index-url ${TORCH_INDEX_URL}

# Copy dependency specifications first to leverage Docker layer caching
COPY requirements.txt /app/requirements.txt
RUN pip install -r requirements.txt

# Copy application source code (filtered strictly by .dockerignore)
COPY . /app

# Install sitecustomize shim into virtual environment and configure directories
RUN cat /app/sitecustomize.py >> /usr/lib/python3.12/sitecustomize.py && \
    cp /app/sitecustomize.py /opt/venv/lib/python3.12/site-packages/sitecustomize.py && \
    mkdir -p /app/models /app/custom_nodes /app/input /app/output /app/user && \
    cp /app/entrypoint.sh /entrypoint.sh && \
    sed -i 's/\r$//' /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Expose ComfyUI default web port
EXPOSE 8188

# Healthcheck to verify ComfyUI web server response
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=40s \
  CMD curl -f "http://127.0.0.1:${COMFYUI_PORT}/system_stats" || curl -f "http://127.0.0.1:${COMFYUI_PORT}/" || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD []
