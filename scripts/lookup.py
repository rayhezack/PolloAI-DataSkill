#!/usr/bin/env python3
"""Look up an exact business term or metric ID; this is not a question-answering Agent."""
import argparse
import json
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent


def normalize(value):
    return "".join(value.split()).casefold()


def lookup(term):
    glossary = yaml.safe_load((ROOT / "L3_glossary.yaml").read_text())
    metrics = {m["id"]: m for p in (ROOT / "L2_metrics").glob("*.yaml")
               for m in yaml.safe_load(p.read_text())["metrics"]}
    key = normalize(term)
    for section in ("unsupported_terms", "ambiguous_terms", "terms"):
        matched = [entry for entry in glossary.get(section, [])
                   if key in {normalize(v) for v in [entry["term"], *entry.get("aliases", [])]}]
        if matched:
            ids = set()
            for entry in matched:
                ids.update(entry.get("candidate_metrics", []))
                if entry.get("metric"):
                    ids.add(entry["metric"])
            return {"term": term, "source": "L3_glossary.yaml", "rule_group": section,
                    "rules": matched, "metrics": [metrics[i] for i in sorted(ids)]}
    matched = [m for m in metrics.values()
               if key in {normalize(v) for v in [m["id"], m["name"], *m.get("synonyms", [])]}]
    return {"term": term, "source": "L2_metrics", "rule_group": "metric_aliases" if matched else "not_found",
            "metrics": matched, "action": "read_contract" if len(matched) == 1 else "clarify",
            "note": "Exact terms only. Read definition, filters, status and evidence; never infer a new metric from a near match."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("term", help="明确的业务词、同义词或M-ID；完整问题先提取关键词")
    args = parser.parse_args()
    print(json.dumps(lookup(args.term), ensure_ascii=False, indent=2, default=str))


if __name__ == "__main__":
    main()
