#!/usr/bin/env python3
"""
MiniCPM NVFP4 (ModelOpt FP4) 量化脚本

NVFP4 是 NVIDIA 的 FP4 格式，在 Blackwell (SM100) 上推理性能最佳。
本脚本封装 SGLang 的 ModelOpt modelopt_fp4 流程，对 MiniCPM 进行离线量化并导出，
便于后续使用 --quantization modelopt_fp4 或 modelopt 部署。

依赖:
  pip install nvidia-modelopt
  或
  pip install sglang[modelopt]

推理端: 需 NVIDIA Blackwell (SM100) 才能充分发挥 NVFP4 内核。
"""

from __future__ import annotations

import argparse
import os
import sys


def _find_sglang_example():
    """定位 sglang 仓库中的 modelopt_quantize_and_export.py。"""
    # 从 submit/quant 出发，可能的结构: minicpm/sglang/examples/usage/modelopt_quantize_and_export.py
    script_name = "modelopt_quantize_and_export.py"
    candidates = [
        os.path.join(os.path.dirname(__file__), "..", "..", "sglang", "examples", "usage", script_name),
        os.path.join(os.path.dirname(__file__), "..", "..", "..", "sglang", "examples", "usage", script_name),
    ]
    for path in candidates:
        if os.path.isfile(path):
            return path
    return None


def run_modelopt_fp4(
    model_path: str,
    export_dir: str,
    checkpoint_save_path: str | None = None,
    device: str = "cuda",
) -> None:
    """
    使用 ModelOpt modelopt_fp4 (NVFP4) 量化 MiniCPM 并导出。

    Args:
        model_path: 原始模型路径或 HuggingFace 模型 ID，如 openbmb/MiniCPM-SALA
        export_dir: 量化后模型导出目录
        checkpoint_save_path: 可选，保存 ModelOpt 校准 checkpoint，便于以后只做 export
        device: 量化时使用的设备
    """
    script_path = _find_sglang_example()
    if script_path is None:
        print(
            "[gpt_q] 未找到 sglang/examples/usage/modelopt_quantize_and_export.py，"
            "请在本仓库中保留 sglang 子目录，或手动执行以下命令：",
            file=sys.stderr,
        )
        print(
            "  python -m sglang.examples.usage.modelopt_quantize_and_export quantize \\",
            file=sys.stderr,
        )
        print(f"    --model-path {model_path} \\", file=sys.stderr)
        print(f"    --export-dir {export_dir} \\", file=sys.stderr)
        print("    --quantization-method modelopt_fp4", file=sys.stderr)
        sys.exit(1)

    argv = [
        sys.executable,
        script_path,
        "quantize",
        "--model-path",
        model_path,
        "--export-dir",
        export_dir,
        "--quantization-method",
        "modelopt_fp4",
        "--device",
        device,
    ]
    if checkpoint_save_path:
        argv.extend(["--checkpoint-save-path", checkpoint_save_path])

    os.execv(sys.executable, argv)


def main():
    parser = argparse.ArgumentParser(
        description="MiniCPM NVFP4 (ModelOpt FP4) 量化：调用 ModelOpt 进行 modelopt_fp4 量化并导出",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--model-path",
        default="openbmb/MiniCPM-SALA",
        help="原始模型路径或 HF 模型 ID (默认: openbmb/MiniCPM-SALA)",
    )
    parser.add_argument(
        "--export-dir",
        required=True,
        help="量化后模型导出目录（必填）",
    )
    parser.add_argument(
        "--checkpoint-save-path",
        default=None,
        help="可选：保存 ModelOpt 校准 checkpoint，便于后续仅做 export",
    )
    parser.add_argument(
        "--device",
        default="cuda",
        help="量化时使用的设备 (默认: cuda)",
    )
    args = parser.parse_args()

    run_modelopt_fp4(
        model_path=args.model_path,
        export_dir=args.export_dir,
        checkpoint_save_path=args.checkpoint_save_path,
        device=args.device,
    )


if __name__ == "__main__":
    main()
