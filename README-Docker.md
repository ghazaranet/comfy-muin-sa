# Running ComfyUI with Docker & WSL2 on Windows

This guide provides instructions for running this ComfyUI project (v0.45.5) in Docker using Docker Desktop and the WSL2 backend on Windows.

---

## 1. Architecture & Storage

All large models, inputs, outputs, custom nodes, and user database files reside **outside** the container on your Windows host filesystem and are mounted as persistent volumes:

| Host Directory | Container Mount | Purpose |
| :--- | :--- | :--- |
| `./models` | `/app/models` | AI checkpoints, LoRAs, VAEs, text encoders, etc. |
| `./custom_nodes` | `/app/custom_nodes` | User-installed custom nodes & extensions |
| `./input` | `/app/input` | Input images and videos for workflows |
| `./output` | `/app/output` | Generated renders and saved media |
| `./user` | `/app/user` | SQLite database (`comfyui.db`), user settings, and UI configurations |

AI models and heavy outputs are excluded from the Docker build context via `.dockerignore`.

---

## 2. Prerequisites

1. **Docker Desktop:** Installed with the **WSL 2 based engine** enabled (*Settings > General > Use the WSL 2 based engine*).
2. **GPU Mode (NVIDIA):**
   * Windows NVIDIA Display Driver installed on host.
   * WSL2 GPU support active in Docker Desktop (*Settings > Resources > WSL Integration*).
3. **CPU Fallback Mode:**
   * If an NVIDIA GPU is not present (e.g., Intel / AMD GPUs or CPU only), use the provided CPU fallback compose file (`docker-compose.cpu.yml`).

---

## 3. Configuration (.env)

Copy the sample environment file to create `.env`:

```powershell
cp .env.example .env
```

Key configuration variables:
* `COMFYUI_PORT`: Host port (default: `8188`). Change if another service is already using port 8188.
* `NVIDIA_VISIBLE_DEVICES`: Specify which GPUs to expose (default: `all` or `0`).
* `COMMANDLINE_ARGS`: Extra launch flags passed to `main.py` (e.g. `--highvram`, `--lowvram`, `--preview-method auto`).

---

## 4. Quick Start Commands

### A. GPU Mode (NVIDIA CUDA)
Validate, build, and start the container with GPU passthrough:

```powershell
# 1. Validate configuration
docker compose config

# 2. Build the Docker image
docker compose build

# 3. Start ComfyUI in the background
docker compose up -d

# 4. View live logs
docker compose logs -f
```

Open your browser to: **http://localhost:8188**

---

### B. CPU Fallback Mode (No NVIDIA GPU)
> [!WARNING]
> **Performance Note:** Generating images/videos entirely on CPU is functional but substantially slower (typically 10x–50x slower) than using dedicated NVIDIA Tensor cores.

To start with the CPU fallback:

```powershell
# 1. Validate CPU configuration
docker compose -f docker-compose.cpu.yml config

# 2. Build the Docker image
docker compose -f docker-compose.cpu.yml build

# 3. Start ComfyUI in CPU mode
docker compose -f docker-compose.cpu.yml up -d

# 4. View live logs
docker compose -f docker-compose.cpu.yml logs -f
```

---

## 5. Daily Operations

### Checking Status & Health
```powershell
# Container status and healthcheck result
docker compose ps
```

### Viewing Logs
```powershell
# Tail the last 100 lines and follow live output
docker compose logs -f --tail=100
```

### Stopping the Container
```powershell
# Gracefully stop ComfyUI
docker compose stop

# Stop and remove container (persistent volumes remain intact)
docker compose down
```

### Restarting ComfyUI
```powershell
docker compose restart
```

### Executing a Shell inside the Container
```powershell
docker compose exec comfyui bash
```

---

## 6. Updating & Installing Dependencies

### Installing Python Requirements for New Custom Nodes
If a custom node in `./custom_nodes` requires extra Python libraries, install them into the running container without rebuilding:
```powershell
docker compose exec comfyui pip install -r /app/custom_nodes/<node_name>/requirements.txt
```
Or rebuild the image after adding pins to your requirements:
```powershell
docker compose build --no-cache
docker compose up -d
```

---

## 7. Troubleshooting

### 1. Port 8188 is already allocated
If ComfyUI Desktop is running on Windows, port 8188 will be occupied. Either close ComfyUI Desktop or change the port in `.env`:
```env
COMFYUI_PORT=8189
```
Then start the container: `docker compose up -d`.

### 2. "WSL environment detected but no adapters were found"
This error indicates that Docker attempted to allocate an NVIDIA GPU on a machine that does not possess an NVIDIA GPU or lacks the WSL2 NVIDIA driver.
* **Resolution:** Use the CPU-only fallback:
  ```powershell
  docker compose -f docker-compose.cpu.yml up -d
  ```

### 3. Container restarting or unhealthy
Inspect the container logs and system statistics:
```powershell
docker compose logs comfyui
docker inspect --format='{{json .State.Health}}' comfyui
```
Ensure the `user/` and `models/` folders have appropriate read/write permissions.
