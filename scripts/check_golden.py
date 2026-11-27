#!/usr/bin/env python3
"""Check R2 cases and stored reference values; this does not evaluate an Agent."""
import argparse
import json
from collections import Counter
from decimal import Decimal, InvalidOperation
from pathlib import Path

import yaml
from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parent.parent


def validate_golden(root=ROOT):
    errors = []
    suite = yaml.safe_load((root / "L5_evals/golden.yaml").read_text())
    schema = json.loads((root / "_schema/golden.schema.json").read_text())
    for error in Draft202012Validator(schema).iter_errors(suite):
        errors.append(f"golden schema {'/'.join(map(str, error.path))}: {error.message}")
    if errors:
        return errors, {"agent_evaluation_run": False}

    metrics = {m["id"]: m for p in (root / "L2_metrics").glob("*.yaml")
               for m in yaml.safe_load(p.read_text())["metrics"]}
    tables = {yaml.safe_load(p.read_text())["id"] for p in (root / "L1_datasets").glob("T-*.yaml")}
    ids, questions = set(), set()
    value_checks = 0
    domains, behaviors = Counter(), Counter()

    def local_file(name, case_id):
        path = (root / name).resolve()
        if root.resolve() not in path.parents or not path.is_file():
            errors.append(f"{case_id}: missing or external file {name}")
            return None
        return path

    for case in suite["cases"]:
        cid, expected = case["id"], case["expected"]
        if cid in ids or case["question"] in questions:
            errors.append(f"{cid}: duplicate ID or question")
        ids.add(cid)
        questions.add(case["question"])
        domains[case["domain"]] += 1
        behaviors[expected["behavior"]] += 1
        for mid in expected["metrics"]:
            if mid not in metrics or metrics[mid]["status"] in ("deprecated", "rejected"):
                errors.append(f"{cid}: unknown or retired metric {mid}")
        for tid in expected["tables"]:
            if tid not in tables:
                errors.append(f"{cid}: unknown table {tid}")
        if expected.get("query"):
            local_file("L4_verified_queries/" + expected["query"] + ".sql", cid)
        for source in case.get("decision_sources", []):
            local_file(source, cid)
        references = case.get("reference", [])
        if isinstance(references, dict):
            references = [references]
        for ref in references:
            path = local_file(ref["file"], cid)
            if path is None:
                continue
            evidence = json.loads(path.read_text())
            if evidence.get("valid_for_current_definition") is False or str(evidence.get("definition_status", "")).startswith("historical_superseded"):
                errors.append(f"{cid}: reference uses superseded evidence {ref['file']}")
            rows = [r for r in evidence.get("data", [])
                    if all(r.get(k) == v for k, v in ref["match"].items())]
            if len(rows) != 1:
                errors.append(f"{cid}: reference must match exactly one row, found {len(rows)}")
                continue
            for key, wanted in ref["values"].items():
                value_checks += 1
                if key not in rows[0]:
                    errors.append(f"{cid}: reference column missing: {key}")
                    continue
                got = rows[0][key]
                if got is None or wanted is None:
                    same = got is wanted
                else:
                    try:
                        same = abs(Decimal(str(got)) - Decimal(str(wanted))) <= Decimal(str(ref["absolute_tolerance"]))
                    except InvalidOperation:
                        same = got == wanted
                if not same:
                    errors.append(f"{cid}: {key}: expected {wanted!r}, stored {got!r}")
    return errors, {"suite_status": suite["status"], "cases": len(suite["cases"]),
                    "domains": dict(domains), "expected_behaviors": dict(behaviors),
                    "stored_value_checks": value_checks, "agent_evaluation_run": False,
                    "note": "Only structure, references and stored values checked; no Agent accuracy or R3 result."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    errors, report = validate_golden()
    report.update(errors=errors, passed=not errors)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    raise SystemExit(1 if errors else 0)


if __name__ == "__main__":
    main()
