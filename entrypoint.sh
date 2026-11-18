#!/bin/bash
set -e

PORT="${COMFYUI_PORT:-8188}"
EXTRA_ARGS="${COMMANDLINE_ARGS:-}"

echo "================================================="
echo " Starting ComfyUI in Docker Container"
echo " Port: ${PORT}"
echo " Extra Arguments: ${EXTRA_ARGS}"
echo "================================================="

# Ensure persistent mount directories exist
mkdir -p /app/models /app/custom_nodes /app/input /app/output /app/user

# If custom command was passed to container, run it directly
if [ "$#" -gt 0 ]; then
    exec "$@"
fi

# Default execution: run ComfyUI listening on all container interfaces
exec python3 main.py --listen 0.0.0.0 --port "${PORT}" ${EXTRA_ARGS}
