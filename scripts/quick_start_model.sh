#!/usr/bin/env bash
# 快速启动 SOAR 模型服务（Docker 方式）
# 用法: ./scripts/quick_start_model.sh [--restart]
#   --restart  若容器已存在则先 stop/rm 再启动
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/soar_config.sh"

RESTART=""
for x in "$@"; do
  [ "$x" = "--restart" ] && RESTART=1
done

# 检查模型目录
if [ ! -d "$SOAR_MODEL_PATH" ]; then
  echo "[ERROR] 模型目录不存在: $SOAR_MODEL_PATH"
  echo "请设置 SOAR_MODEL_PATH 或将 MiniCPM-SALA 下载到 \$HOME/models/MiniCPM-SALA"
  exit 1
fi

# 检查端口是否已被占用（可能是已有服务）
check_port() {
  if command -v nc &>/dev/null; then
    nc -z 127.0.0.1 "$SOAR_PORT" 2>/dev/null && return 0
  fi
  return 1
}

# 若已有同名容器在跑，根据参数决定是否重启
if docker ps -q -f "name=^${SOAR_CONTAINER_NAME}$" | grep -q .; then
  if [ -n "$RESTART" ]; then
    echo "[quick_start] 停止并删除已有容器: $SOAR_CONTAINER_NAME"
    docker stop "$SOAR_CONTAINER_NAME" 2>/dev/null || true
    docker rm "$SOAR_CONTAINER_NAME" 2>/dev/null || true
  else
    echo "[quick_start] 容器已在运行: $SOAR_CONTAINER_NAME"
    echo "[quick_start] API: $SOAR_API_BASE"
    echo "如需重启请加参数: $0 --restart"
    exit 0
  fi
fi

# 若端口已被占用且不是我们刚停掉的容器，提示
if check_port; then
  echo "[WARN] 端口 $SOAR_PORT 已被占用，可能已有服务在运行。可先检查: curl -s $SOAR_API_BASE/v1/models"
  read -p "是否仍启动新容器并可能失败? [y/N] " -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

# 可选：在 soar_config.sh 中设置 SOAR_SERVER_ARGS 覆盖默认启动参数
RUN_ARGS=(-d --name "$SOAR_CONTAINER_NAME" --gpus "device=${SOAR_GPU}" \
  -p "${SOAR_PORT}:30000" \
  -v "${SOAR_MODEL_PATH}:/models/MiniCPM-SALA:ro")
[ -n "${SOAR_SERVER_ARGS}" ] && RUN_ARGS+=(-e "SGLANG_SERVER_ARGS=${SOAR_SERVER_ARGS}")

echo "[quick_start] 启动容器: $SOAR_CONTAINER_NAME"
echo "[quick_start] 镜像: $SOAR_DOCKER_IMAGE"
echo "[quick_start] 挂载模型: $SOAR_MODEL_PATH -> /models/MiniCPM-SALA"
echo "[quick_start] 端口: $SOAR_PORT"

docker run "${RUN_ARGS[@]}" "$SOAR_DOCKER_IMAGE"

echo "[quick_start] 容器已启动，等待服务就绪..."
for i in {1..60}; do
  if curl -s -o /dev/null -w "%{http_code}" "${SOAR_API_BASE}/v1/models" 2>/dev/null | grep -q 200; then
    echo "[quick_start] 服务已就绪: $SOAR_API_BASE"
    echo "查看日志: docker logs -f $SOAR_CONTAINER_NAME"
    exit 0
  fi
  sleep 5
done
echo "[WARN] 等待超时，请手动检查: docker logs $SOAR_CONTAINER_NAME"
exit 1
