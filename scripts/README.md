# SOAR 2026 迭代脚本说明

## 1. 配置

首次使用前编辑 **`soar_config.sh`**，按本机环境修改：

- `SOAR_MODEL_PATH`：主机上 MiniCPM-SALA 模型目录（如 `$HOME/models/MiniCPM-SALA`）
- `SOAR_GPU`：使用的 GPU 编号（默认 0）
- `SOAR_DOCKER_IMAGE`：国内用阿里云镜像，海外可改为 `ghcr.io/openbmb/soar-toolkit:latest`
- 可选 `SOAR_SERVER_ARGS`：覆盖 SGLang 默认启动参数
- 可选 `SOAR_SPEED_S1` / `SOAR_SPEED_S8` / `SOAR_SPEED_SMAX`：速度评测 JSONL 路径（不设则只跑正确性）

## 2. 快速启动模型

```bash
./scripts/quick_start_model.sh          # 启动 Docker 服务，已运行则跳过
./scripts/quick_start_model.sh --restart # 强制重启容器
```

需已拉取镜像并下载好 MiniCPM-SALA（见 [SOAR-Toolkit README](../SOAR-Toolkit/README.md)）。

## 3. 一键测评

**先确保模型服务已启动**（见上）。本机需已安装可调用 SGLang API 的 Python 环境（如 `pip install sglang requests`，或使用 SOAR-Toolkit 镜像内环境）。

```bash
./scripts/run_eval.sh                    # 正确性 + 速度（若已配置 SPEED 数据集）
./scripts/run_eval.sh --correctness-only # 只跑正确性
./scripts/run_eval.sh --num-samples 5    # 正确性只测 5 条（调试）
```

- 正确性：使用 `SOAR-Toolkit/eval_dataset/perf_public_set.jsonl`，结果关注相对 80 分的表现。
- 速度：需在 `soar_config.sh` 中设置 `SOAR_SPEED_S1` 等，JSONL 格式见 Toolkit 文档。

## 4. 一键打包与上传

提交物放在 **`submit/`** 目录（或通过 `SOAR_SUBMIT_DIR` 指定），必须包含 `prepare_env.sh`。

```bash
./scripts/pack_submit.sh       # 打包为 soar_submit.tar.gz，检查 ≤2GB
./scripts/pack_submit.sh --open    # 打包并打开赛事提交页
./scripts/pack_submit.sh --dir /path/to/my_submit  # 指定提交目录
```

输出默认：`soar_submit.tar.gz`（路径见 `SOAR_SUBMIT_TAR`）。超过 2GB 会报错并退出。

## 5. 推荐迭代流程

1. 修改代码或配置后：`./scripts/quick_start_model.sh --restart`
2. 自测正确性：`./scripts/run_eval.sh --correctness-only`（或带 `--num-samples 5` 快速试跑）
3. 需要时自测速度：在 config 中设好 SPEED 数据集后 `./scripts/run_eval.sh`
4. 确认无误：`./scripts/pack_submit.sh`，检查大小与包内文件后上传 [soar.openbmb.cn](https://soar.openbmb.cn/)
