# 协作指南

本仓库用于共同建设 Pollo AI 取数知识库。业务定义、来源证据和 DS 评审结论一起维护；文件已提交不代表口径已评审。

## 拉取与校验

使用 Python 3.9 或以上版本，在仓库根目录运行：

```bash
git clone https://github.com/rayhezack/PolloAI-DataSkill.git
cd PolloAI-DataSkill
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python scripts/lint.py
```

Windows 环境使用 `.venv\Scripts\activate` 激活虚拟环境。

## 修改与评审

1. 从最新 `main` 创建工作分支，例如 `docs/creation-review`。
2. 在对应域的 `review/R1_*.md` 中补充业务结论，注明评审人、日期和涉及条目。
3. 将已确认的结论同步到表卡、维度、指标和规则；纠错及口径变更同时记录到 `governance/corrections.md`、`governance/changelog.md`。
4. 运行 `python scripts/lint.py`，通过后提交 Pull Request。说明修改的业务含义、涉及条目、证据和校验结果。
5. 经 DS 评审后合并。需要数仓确认的实现差异，在 `governance/open_questions.md` 或 `governance/dw_issues.md` 中跟踪。

AI 新增或修改的条目最多推进到 `pending_review`；进入 `pilot` / `verified` 必须有 DS 评审依据和评审元数据。更完整的状态及变更规则见 [治理规范](governance/conventions.md)。

## 从哪里开始

- [接续与评审路线](review/00_Codex接续与评审路线.md)：当前进度、剩余文档和评审顺序。
- [存量知识对照](governance/legacy_alignment.md)：本库与数仓既有口径的差异。
- [待拍板事项](governance/open_questions.md)：尚未裁决的业务问题。
- [数仓待办](governance/dw_issues.md)：字段和加工逻辑的修复进度。

指标及表卡的评审状态以对应文件为准。存在冲突或未覆盖的业务语义时，记录问题并提交评审。
