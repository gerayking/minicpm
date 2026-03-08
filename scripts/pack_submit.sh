#!/usr/bin/env bash
# 一键打包提交目录为 .tar.gz，检查 ≤2GB，可选打开提交页面
# 用法: ./scripts/pack_submit.sh [--open] [--dir /path/to/submit]
#   --open  打包完成后用浏览器打开赛事提交页
#   --dir   指定提交目录，默认用 soar_config.sh 中的 SOAR_SUBMIT_DIR
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/soar_config.sh"

OPEN_PAGE=""
SUBMIT_DIR="$SOAR_SUBMIT_DIR"
while [ $# -gt 0 ]; do
  case "$1" in
    --open) OPEN_PAGE=1 ;;
    --dir)
      [ -n "${2:-}" ] && SUBMIT_DIR="$2" && shift
      ;;
    *) echo "未知参数: $1"; exit 1 ;;
  esac
  shift
done

# 必须包含 prepare_env.sh
if [ ! -f "${SUBMIT_DIR}/prepare_env.sh" ]; then
  echo "[ERROR] 提交目录必须包含 prepare_env.sh: ${SUBMIT_DIR}"
  echo "请先创建 prepare_env.sh（见 SOAR-Toolkit 提交 Demo）"
  exit 1
fi

# 检查目录存在
if [ ! -d "$SUBMIT_DIR" ]; then
  echo "[ERROR] 提交目录不存在: $SUBMIT_DIR"
  exit 1
fi

OUTPUT_TAR="${SOAR_SUBMIT_TAR}"
MAX_MB="${SOAR_SUBMIT_MAX_MB}"
REPO_ROOT="$SOAR_REPO_ROOT"

# 打包为解压后根目录即 prepare_env.sh 等（平台要求）
echo "[pack_submit] 打包目录: $SUBMIT_DIR"
echo "[pack_submit] 输出文件: $OUTPUT_TAR"
echo "[pack_submit] 大小限制: ${MAX_MB} MB"

rm -f "$OUTPUT_TAR"
tar -czvf "$OUTPUT_TAR" -C "$SUBMIT_DIR" .

SIZE_BYTES="$(stat -f%z "$OUTPUT_TAR" 2>/dev/null || stat -c%s "$OUTPUT_TAR" 2>/dev/null)"
SIZE_MB="$((SIZE_BYTES / 1024 / 1024))"
echo ""
echo "========== 打包结果 =========="
echo "  文件: $OUTPUT_TAR"
echo "  大小: ${SIZE_MB} MB / ${MAX_MB} MB"

if [ "$SIZE_MB" -gt "$MAX_MB" ]; then
  echo "[ERROR] 超过 2GB 限制，无法提交。请精简提交内容。"
  exit 1
fi
echo "  通过大小检查。"

echo ""
echo "包内文件概览:"
tar -tzvf "$OUTPUT_TAR" | head -30
echo "  ..."
echo ""

if [ -n "$OPEN_PAGE" ]; then
  URL="https://soar.openbmb.cn/"
  if command -v open &>/dev/null; then
    open "$URL"
    echo "[pack_submit] 已打开: $URL"
  elif command -v xdg-open &>/dev/null; then
    xdg-open "$URL"
    echo "[pack_submit] 已打开: $URL"
  else
    echo "请手动打开提交页面: $URL"
  fi
fi

echo ""
echo "下一步: 登录 https://soar.openbmb.cn/ 上传 $OUTPUT_TAR"
