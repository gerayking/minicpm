# SOAR 2026 提交目录

将**所有要提交的代码和资源**放在本目录下，然后执行：

```bash
./scripts/pack_submit.sh        # 打包为 soar_submit.tar.gz，检查 ≤2GB
./scripts/pack_submit.sh --open # 打包并打开赛事提交页面
```

## 必须包含

- **prepare_env.sh**：环境构建脚本（必选）。平台会先执行此脚本，请使用 `uv pip install` 安装依赖。

## 可选

- **prepare_model.sh**：模型预处理脚本。若提供，须支持：
  ```bash
  bash prepare_model.sh --input <原始模型路径> --output <处理后模型路径>
  ```
- 其他：自定义 SGLang 代码、量化脚本等。

## 参考

- 官方 Demo：[SOAR-Toolkit demos/demo-sala.tar.gz](https://github.com/OpenBMB/SOAR-Toolkit)
- 本仓库规则与待办：根目录下 `SOAR-2026-比赛规则总结.md`、`SOAR-2026-待办清单.md`
