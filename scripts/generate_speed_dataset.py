#!/usr/bin/env python3
"""
SOAR 2026 速度评测集生成脚本

根据比赛页面公布的 Input/Output Length 分布生成 JSONL 格式速度评测集，
供 bench_serving.sh 自测使用。格式：每行 {"question": "...", "model_response": "..."}

分布来源：https://soar.openbmb.cn/competition

Input Length 分布:
  0-4K     ~25%
  4K-16K   ~10%
  16K-32K  ~15%
  32K-128K ~35%
  128K-160K ~15%

Output Length 分布:
  0-512    ~35%
  512-2K   ~25%
  2K-4K    ~10%
  4K-16K   ~15%
  16K-32K  ~15%
"""

import argparse
import json
import random
import sys
from pathlib import Path

# 默认用字符数近似 token（约 2.5 字符/token，中英混合）
DEFAULT_CHARS_PER_TOKEN = 2.5

INPUT_BUCKETS = [
    (0, 4_000, 0.25),      # 0-4K, 25%
    (4_000, 16_000, 0.10), # 4K-16K, 10%
    (16_000, 32_000, 0.15),# 16K-32K, 15%
    (32_000, 128_000, 0.35), # 32K-128K, 35%
    (128_000, 160_000, 0.15), # 128K-160K, 15%
]

OUTPUT_BUCKETS = [
    (0, 512, 0.35),        # 0-512, 35%
    (512, 2_000, 0.25),    # 512-2K, 25%
    (2_000, 4_000, 0.10),  # 2K-4K, 10%
    (4_000, 16_000, 0.15), # 4K-16K, 15%
    (16_000, 32_000, 0.15),# 16K-32K, 15%
]

# 用于填充的基段（中英混合，使 token 比例更接近真实）
PAD_QUESTION = "请根据以下上下文回答问题。上下文内容如下："
PAD_RESPONSE = "根据分析，结论如下。"


def token_to_chars(tokens: int, chars_per_token: float) -> int:
    """将目标 token 数转为近似字符数。"""
    return max(0, int(tokens * chars_per_token))


def make_text(target_chars: int, prefix: str, pad: str) -> str:
    """生成约 target_chars 字符的文本（用 pad 重复填充）。"""
    if target_chars <= 0:
        return ""
    out = prefix
    while len(out) < target_chars:
        out += pad
    return out[:target_chars]


def sample_length_from_buckets(buckets: list, rng: random.Random) -> int:
    """按占比从 buckets 中先抽区间，再在该区间内均匀抽 token 数。"""
    r = rng.random()
    acc = 0.0
    for low, high, pct in buckets:
        acc += pct
        if r <= acc:
            if low >= high:
                return low
            return rng.randint(low, high - 1)
    low, high, _ = buckets[-1]
    return rng.randint(low, high - 1) if high > low else low


def get_tokenizer_fn(model_path: str | None):
    """若提供 model_path 则返回用该 tokenizer 计数的函数，否则返回 None（用字符近似）。"""
    if not model_path:
        return None
    try:
        from transformers import AutoTokenizer
        tokenizer = AutoTokenizer.from_pretrained(model_path, trust_remote_code=True)
        def _token_len(s: str) -> int:
            return len(tokenizer.encode(s, add_special_tokens=False))
        return _token_len
    except Exception as e:
        print(f"[WARN] 无法加载 tokenizer ({model_path}): {e}，将使用字符近似", file=sys.stderr)
        return None


def generate_with_char_approx(
    num_samples: int,
    chars_per_token: float,
    rng: random.Random,
    out_path: Path,
) -> None:
    """按分布用字符数近似生成 JSONL。"""
    with open(out_path, "w", encoding="utf-8") as f:
        for i in range(num_samples):
            in_tok = sample_length_from_buckets(INPUT_BUCKETS, rng)
            out_tok = sample_length_from_buckets(OUTPUT_BUCKETS, rng)
            in_chars = token_to_chars(in_tok, chars_per_token)
            out_chars = token_to_chars(out_tok, chars_per_token)
            question = make_text(in_chars, PAD_QUESTION, "这是一段用于速度评测的填充文本。")
            model_response = make_text(out_chars, PAD_RESPONSE, "这是模型回答的填充内容。")
            obj = {"question": question, "model_response": model_response}
            f.write(json.dumps(obj, ensure_ascii=False) + "\n")
    print(f"已生成 {num_samples} 条（字符近似，约 {chars_per_token} 字符/token） -> {out_path}")


def generate_with_tokenizer(
    num_samples: int,
    token_len_fn,
    chars_per_token: float,
    rng: random.Random,
    out_path: Path,
) -> None:
    """按分布生成 JSONL，并用 tokenizer 精确控制 token 数。"""
    def grow_to_tokens(prefix: str, pad: str, target_tokens: int) -> str:
        s = prefix
        while token_len_fn(s) < target_tokens:
            s += pad
        if token_len_fn(s) <= target_tokens:
            return s
        # 二分查找最大长度使得 token 数 <= target_tokens
        lo, hi = 0, len(s)
        while lo < hi - 1:
            mid = (lo + hi) // 2
            if token_len_fn(s[:mid]) <= target_tokens:
                lo = mid
            else:
                hi = mid
        return s[:lo]

    with open(out_path, "w", encoding="utf-8") as f:
        for i in range(num_samples):
            in_tok = sample_length_from_buckets(INPUT_BUCKETS, rng)
            out_tok = sample_length_from_buckets(OUTPUT_BUCKETS, rng)
            question = grow_to_tokens(
                PAD_QUESTION,
                "这是一段用于速度评测的填充文本。",
                in_tok,
            )
            model_response = grow_to_tokens(
                PAD_RESPONSE,
                "这是模型回答的填充内容。",
                out_tok,
            )
            obj = {"question": question, "model_response": model_response}
            f.write(json.dumps(obj, ensure_ascii=False) + "\n")
    print(f"已生成 {num_samples} 条（使用 tokenizer 精确 token 数） -> {out_path}")


def main():
    parser = argparse.ArgumentParser(
        description="按 SOAR 2026 速度评测集分布生成 question/model_response JSONL。"
    )
    parser.add_argument(
        "-o", "--output",
        type=Path,
        default=Path("eval_dataset/speed_eval_set.jsonl"),
        help="输出 JSONL 路径",
    )
    parser.add_argument(
        "-n", "--num-samples",
        type=int,
        default=200,
        help="生成样本数（默认 200）",
    )
    parser.add_argument(
        "--model-path",
        type=str,
        default=None,
        help="可选：MiniCPM-SALA 模型路径，用于按 token 精确控制长度",
    )
    parser.add_argument(
        "--chars-per-token",
        type=float,
        default=DEFAULT_CHARS_PER_TOKEN,
        help="未使用 model-path 时，字符与 token 的近似比例（默认 2.5）",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="随机种子",
    )
    args = parser.parse_args()

    rng = random.Random(args.seed)
    args.output.parent.mkdir(parents=True, exist_ok=True)

    token_len_fn = get_tokenizer_fn(args.model_path)
    if token_len_fn is not None:
        generate_with_tokenizer(
            args.num_samples,
            token_len_fn,
            args.chars_per_token,
            rng,
            args.output,
        )
    else:
        generate_with_char_approx(
            args.num_samples,
            args.chars_per_token,
            rng,
            args.output,
        )


if __name__ == "__main__":
    main()
