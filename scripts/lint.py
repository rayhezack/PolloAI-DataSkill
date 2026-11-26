#!/usr/bin/env python3
"""Lint the semantic knowledge base.

Checks: JSON-schema validity, unique IDs, cross references (T/D/P/OQ/M),
and that pilot/verified entries carry evidence + reviewed_by/at.
Usage: python3 scripts/lint.py   (exit 1 on any error)
"""
import json
import re
import sys
from pathlib import Path

import yaml
from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parent.parent
errors, warnings = [], []


def load_schema(name):
    common = json.loads((ROOT / "_schema/common.json").read_text())
    raw = (ROOT / f"_schema/{name}.schema.json").read_text()
    raw = raw.replace('{"$ref": "common#/status"}', json.dumps(common["status"]))
    return Draft202012Validator(json.loads(raw))


def load_items(path, key=None):
    # YAML 会把 2026-11-25 解析成 date，这里统一转成字符串
    data = json.loads(json.dumps(yaml.safe_load(path.read_text()) or {}, default=str))
    items = data.get(key, []) if key else [data]
    return [(path.relative_to(ROOT), it) for it in items]


tables = [i for p in sorted((ROOT / "L1_datasets").glob("T-*.yaml")) for i in load_items(p)]
dims = load_items(ROOT / "L2_dimensions.yaml", "dimensions") if (ROOT / "L2_dimensions.yaml").exists() else []
metrics = [i for p in sorted((ROOT / "L2_metrics").glob("*.yaml")) for i in load_items(p, "metrics")]

rules_text = (ROOT / "L3_rules.md").read_text() if (ROOT / "L3_rules.md").exists() else ""
p_ids = set(re.findall(r"^\|\s*(P-\d{2})\s*\|", rules_text, re.M))
oq_text = (ROOT / "governance/open_questions.md").read_text()
oq_ids = set(re.findall(r"^\|\s*(OQ-\d{2})\s*\|", oq_text, re.M))

for kind, items in (("table", tables), ("dimension", dims), ("metric", metrics)):
    v = load_schema(kind)
    for path, it in items:
        for e in v.iter_errors(it):
            errors.append(f"{path} [{it.get('id')}] schema: {'/'.join(map(str, e.path))} {e.message}")

all_ids = {}
for path, it in tables + dims + metrics:
    i = it.get("id")
    if i in all_ids:
        errors.append(f"{path}: duplicate id {i} (also in {all_ids[i]})")
    all_ids[i] = path
t_ids = {it["id"] for _, it in tables}
d_ids = {it["id"] for _, it in dims}
m_ids = {it["id"] for _, it in metrics}

for path, it in tables + dims + metrics:
    iid = it.get("id")
    is_table = str(iid).startswith("T-")
    refs = []
    if it.get("table") and it["table"] != "TBD" and str(it["table"]).startswith("T-"):
        refs.append(("T", it["table"]))
    refs += [("T", t) for t in it.get("applies_to", [])]
    refs += [("D", d) for d in it.get("dimensions", [])]
    refs += [("P", p) for p in it.get("traps", [])]
    for k in ("numerator", "denominator"):
        if str(it.get(k, "")).startswith("M-"):
            refs.append(("M", it[k]))
    if it.get("open_question"):
        refs.append(("OQ", it["open_question"]))
    pools = {"T": t_ids, "D": d_ids, "P": p_ids, "M": m_ids, "OQ": oq_ids}
    for kind, ref in refs:
        if ref not in pools[kind]:
            errors.append(f"{path} [{iid}]: unknown reference {ref}")
    st = it.get("status")
    if st in ("pilot", "verified"):
        if not it.get("evidence"):
            errors.append(f"{path} [{iid}]: status {st} requires evidence")
        if not (it.get("reviewed_by") and it.get("reviewed_at")):
            errors.append(f"{path} [{iid}]: status {st} requires reviewed_by/reviewed_at")
    if it.get("table") == "TBD" and not it.get("open_question"):
        errors.append(f"{path} [{iid}]: table TBD requires open_question")
    if st in ("draft", "pending_review") and not is_table and not it.get("evidence"):
        warnings.append(f"{path} [{iid}]: no evidence yet")

for w in warnings:
    print("WARN ", w)
for e in errors:
    print("ERROR", e)
print(f"tables={len(tables)} dimensions={len(dims)} metrics={len(metrics)} traps={len(p_ids)} "
      f"errors={len(errors)} warnings={len(warnings)}")
sys.exit(1 if errors else 0)
