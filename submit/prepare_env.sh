#!/usr/bin/env bash
# SOAR 2026 环境构建脚本（必选）
# 平台会在基础环境启动后 source 本脚本，请使用 uv pip install 安装依赖。
# 参考：https://github.com/OpenBMB/SOAR-Toolkit 提交 Demo
set -e

# 示例：不修改镜像内 sglang 时，仅追加推理参数（可选）
# export SGLANG_SERVER_ARGS="${SGLANG_SERVER_ARGS:-} --log-level info"

# 示例：安装额外 Python 包
# uv pip install xxx

# 示例：用自备 sglang 替换镜像内置版本（editable）
# uv pip install --no-deps -e ./sglang/python
# export SGLANG_SERVER_ARGS="${SGLANG_SERVER_ARGS:-} --log-level info"

echo "[prepare_env.sh] 执行完毕"
