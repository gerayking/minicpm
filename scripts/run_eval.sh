#!/usr/bin/env bash
# 一键测评：正确性（必跑）+ 速度（可选，需在 soar_config.sh 中设置 SPEED 数据集路径）
# 用法: ./scripts/run_eval.sh [--correctness-only] [--num-samples N]
#   --correctness-only  只跑正确性，不跑速度
#   --num-samples N     eval_model 只测前 N 条（调试用）
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/soar_config.sh"

# 解析参数：--correctness-only 只跑正确性；--num-samples N 传给 eval_model（调试用）
CORRECTNESS_ONLY=""
EVAL_EXTRA_ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --correctness-only) CORRECTNESS_ONLY=1 ;;
    --num-samples)
      [ -n "${2:-}" ] && EVAL_EXTRA_ARGS+=(--num_samples "$2") && shift
      ;;
    *) EVAL_EXTRA_ARGS+=("$1") ;;
  esac
  shift
done

# 检查服务
echo "[run_eval] 检查 API: $SOAR_API_BASE"
if ! curl -s -o /dev/null -w "%{http_code}" "${SOAR_API_BASE}/v1/models" 2>/dev/null | grep -q 200; then
  echo "[ERROR] 服务未就绪，请先运行: ./scripts/quick_start_model.sh"
  exit 1
fi

# ---------- 1. 正确性评测 ----------
if [ ! -f "$SOAR_DATA_PUBLIC" ]; then
  echo "[ERROR] 正确性数据集不存在: $SOAR_DATA_PUBLIC"
  exit 1
fi
if [ ! -f "$SOAR_EVAL_SCRIPT" ]; then
  echo "[ERROR] 评测脚本不存在: $SOAR_EVAL_SCRIPT"
  exit 1
fi

echo ""
echo "========== 正确性评测 (perf_public_set) =========="
# 需要 sglang 和 requests，一般在容器内或本机 pip 已装
python3 "$SOAR_EVAL_SCRIPT" \
  --api_base "$SOAR_API_BASE" \
  --model_path "$SOAR_MODEL_PATH" \
  --data_path "$SOAR_DATA_PUBLIC" \
  --concurrency 8 \
  "${EVAL_EXTRA_ARGS[@]}"

echo ""

# ---------- 2. 速度评测（可选） ----------
if [ -n "$CORRECTNESS_ONLY" ]; then
  echo "[run_eval] 已跳过速度评测 (--correctness-only)"
  exit 0
fi

S1="${SOAR_SPEED_S1:-}"
S8="${SOAR_SPEED_S8:-}"
SMAX="${SOAR_SPEED_SMAX:-}"
if [ -z "$S1" ] && [ -z "$S8" ] && [ -z "$SMAX" ]; then
  echo "[run_eval] 未设置速度数据集，跳过 bench_serving。"
  echo "  在 scripts/soar_config.sh 中设置 SOAR_SPEED_S1 / SOAR_SPEED_S8 / SOAR_SPEED_SMAX 可启用。"
  exit 0
fi

if [ ! -f "$SOAR_BENCH_SCRIPT" ]; then
  echo "[WARN] bench_serving.sh 不存在: $SOAR_BENCH_SCRIPT，跳过速度评测"
  exit 0
fi

echo "========== 速度评测 (bench_serving) =========="
export SPEED_DATA_S1="$S1"
export SPEED_DATA_S8="$S8"
export SPEED_DATA_SMAX="$SMAX"
bash "$SOAR_BENCH_SCRIPT" "$SOAR_API_BASE"
