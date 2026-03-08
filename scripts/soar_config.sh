#!/usr/bin/env bash
# SOAR 2026 统一配置：模型路径、API、GPU、镜像等
# 其他脚本通过 source scripts/soar_config.sh 使用
set -e

# ---------- 路径（请按本机修改） ----------
# 主机上的 MiniCPM-SALA 模型目录（挂载到容器 /models/MiniCPM-SALA）
export SOAR_MODEL_PATH="${SOAR_MODEL_PATH:-$HOME/models/MiniCPM-SALA}"

# 本仓库根目录（自动推断：脚本在 scripts/ 下）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
export SOAR_REPO_ROOT="${SOAR_REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# SOAR-Toolkit 内的评测资源
export SOAR_TOOLKIT="${SOAR_REPO_ROOT}/SOAR-Toolkit"
export SOAR_DATA_PUBLIC="${SOAR_TOOLKIT}/eval_dataset/perf_public_set.jsonl"
export SOAR_EVAL_SCRIPT="${SOAR_TOOLKIT}/eval_model.py"
export SOAR_BENCH_SCRIPT="${SOAR_TOOLKIT}/bench_serving.sh"

# ---------- 服务 ----------
export SOAR_API_BASE="${SOAR_API_BASE:-http://127.0.0.1:30000}"
export SOAR_HOST="${SOAR_HOST:-0.0.0.0}"
export SOAR_PORT="${SOAR_PORT:-30000}"

# ---------- Docker ----------
export SOAR_GPU="${SOAR_GPU:-0}"
export SOAR_CONTAINER_NAME="${SOAR_CONTAINER_NAME:-soar-sglang-server}"
# 国内 / 海外 二选一
export SOAR_DOCKER_IMAGE="${SOAR_DOCKER_IMAGE:-modelbest-registry.cn-beijing.cr.aliyuncs.com/public/soar-toolkit:latest}"
# export SOAR_DOCKER_IMAGE="ghcr.io/openbmb/soar-toolkit:latest"

# 可选：覆盖默认 SGLang 启动参数（示例：加 --log-level info）
# export SOAR_SERVER_ARGS_EXTRA="--log-level info"

# ---------- 提交目录（打包用） ----------
export SOAR_SUBMIT_DIR="${SOAR_SUBMIT_DIR:-$SOAR_REPO_ROOT/submit}"
export SOAR_SUBMIT_MAX_MB="${SOAR_SUBMIT_MAX_MB:-2048}"
export SOAR_SUBMIT_TAR="${SOAR_SUBMIT_TAR:-$SOAR_REPO_ROOT/soar_submit.tar.gz}"

# ---------- 速度评测（可选，不设则 run_eval 只跑正确性） ----------
# export SOAR_SPEED_S1="/path/to/s1.jsonl"
# export SOAR_SPEED_S8="/path/to/s8.jsonl"
# export SOAR_SPEED_SMAX="/path/to/smax.jsonl"
