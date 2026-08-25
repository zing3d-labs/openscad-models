"""Command line entry point: `python -m tools.visual_tests <command>`.

Commands
    validate  Check every sidecar spec in the repository parses.
    select    Work out which parts a set of changes affects.
    canary    Render one commit twice and assert the renderer is deterministic.
    run       Compare a part between two checkouts.
    report    Turn a run's result.json into Markdown.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

from .deps import affected_parts, discover_parts, spec_path_for
from .report import build_comment, canary_note, marker
from .runner import Side, canary, load_part_spec, run_part, write_result
from .spec import SpecError, load_spec


def _git(repo: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(repo), *args],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise SystemExit(f"git {' '.join(args)} failed: {result.stderr.strip()}")
    return result.stdout.strip()


def _emit(payload: dict[str, Any], output: Path | None) -> None:
    text = json.dumps(payload, indent=2) + "\n"
    if output:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(text, encoding="utf-8")
    print(text, end="")


def _github_output(values: dict[str, str]) -> None:
    """Append step outputs when running inside GitHub Actions."""
    import os

    path = os.environ.get("GITHUB_OUTPUT")
    if not path:
        return
    with open(path, "a", encoding="utf-8") as handle:
        for key, value in values.items():
            handle.write(f"{key}={value}\n")


def command_validate(args: argparse.Namespace) -> int:
    repo = args.repo.resolve()
    failures = 0
    checked = 0
    for part in discover_parts(repo):
        path = repo / spec_path_for(part)
        if not path.is_file():
            print(f"no spec: {spec_path_for(part)}")
            continue
        try:
            spec = load_spec(path, repo)
        except SpecError as exc:
            failures += 1
            print(f"INVALID {spec_path_for(part)}: {exc}", file=sys.stderr)
            continue
        checked += 1
        print(
            f"ok {spec.path}: {len(spec.features)} feature(s), "
            f"{spec.case_count} case(s), {spec.render_count} rendered"
        )
    if failures:
        print(f"\n{failures} spec(s) failed validation", file=sys.stderr)
    elif not checked:
        print("\nno specs found")
    return 1 if failures else 0


def command_select(args: argparse.Namespace) -> int:
    repo = args.repo.resolve()
    if args.changed_files_from:
        changed = [
            line.strip()
            for line in Path(args.changed_files_from).read_text(encoding="utf-8").splitlines()
            if line.strip()
        ]
        merge_base, head = args.base or "", args.head or ""
    else:
        head = _git(repo, "rev-parse", args.head or "HEAD")
        merge_base = _git(repo, "merge-base", args.base, head)
        # Two-dot from the merge base is the change the PR actually introduces;
        # comparing against the tip of the base branch would also fold in
        # everything that landed on it since the branch started.
        changed = [
            line for line in _git(repo, "diff", "--name-only", merge_base, head).splitlines() if line
        ]

    parts, reasons = affected_parts(repo, changed)
    with_spec: list[str] = []
    missing: list[str] = []
    for part in parts:
        (with_spec if (repo / spec_path_for(part)).is_file() else missing).append(str(part))

    payload = {
        "merge_base": merge_base,
        "head": head,
        "changed_files": changed,
        "parts": with_spec,
        "missing_specs": missing,
        "reasons": reasons,
        "matrix": [{"part": p, "slug": Path(p).stem} for p in with_spec],
    }
    _emit(payload, args.output)
    _github_output(
        {
            "matrix": json.dumps({"include": payload["matrix"]}),
            "any": "true" if with_spec else "false",
            "merge_base": merge_base,
            "missing_specs": json.dumps(missing),
        }
    )
    return 0


def command_canary(args: argparse.Namespace) -> int:
    repo = args.repo.resolve()
    part = Path(args.part)
    spec = load_part_spec(repo, part)
    side = Side.create("head", repo, args.openscad, ref=args.head_ref or "")
    # Its own subtree, so canary renders never mix in with the comparison
    # images that get published.
    result = canary(part, spec, side, (args.out / "canary").resolve())
    _emit(result, args.out / "canary.json")
    if not result.get("ran"):
        print(f"canary skipped: {result.get('reason')}")
        return 0
    if result.get("passed"):
        print("canary passed: the same commit rendered twice is identical")
        return 0
    print(
        "CANARY FAILED — rendering is not deterministic in this environment, so exact "
        "comparison cannot be trusted. See docs/visual-regression-tests.md.",
        file=sys.stderr,
    )
    return 1


def command_run(args: argparse.Namespace) -> int:
    repo = args.repo.resolve()
    part = Path(args.part)
    spec = load_part_spec(repo, part)
    base = Side.create("base", args.base_root, args.openscad, ref=args.base_ref or "")
    head = Side.create("head", repo, args.openscad, ref=args.head_ref or "")
    result = run_part(part, spec, base, head, args.out.resolve(), jobs=args.jobs)
    path = write_result(args.out.resolve(), result)
    print(f"wrote {path}")
    print(
        f"{sum(1 for f in result['features'] if f['changed'])} of {len(result['features'])} "
        f"feature(s) changed"
    )
    _github_output({"changed": "true" if result["changed"] else "false"})
    return 0


def command_report(args: argparse.Namespace) -> int:
    result = json.loads(Path(args.result).read_text(encoding="utf-8"))
    notes: list[str] = []
    if args.canary and Path(args.canary).is_file():
        note = canary_note(json.loads(Path(args.canary).read_text(encoding="utf-8")))
        if note:
            notes.append(note)
    notes.extend(args.note or [])
    body = build_comment(result, args.image_base_url or None, notes)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(body, encoding="utf-8")
    print(f"wrote {args.out} ({len(body)} characters)")
    _github_output({"marker": marker(result["part"])})
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="visual-tests", description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path("."), help="repository root (default: .)")
    sub = parser.add_subparsers(dest="command", required=True)

    validate = sub.add_parser("validate", help="check every sidecar spec parses")
    validate.set_defaults(func=command_validate)

    select = sub.add_parser("select", help="work out which parts a change affects")
    select.add_argument("--base", default="origin/main", help="base ref to take the merge base against")
    select.add_argument("--head", default="HEAD")
    select.add_argument("--changed-files-from", type=Path, help="read changed paths from a file instead of git")
    select.add_argument("--output", type=Path)
    select.set_defaults(func=command_select)

    canary_parser = sub.add_parser("canary", help="assert the renderer is deterministic")
    canary_parser.add_argument("--part", required=True)
    canary_parser.add_argument("--out", type=Path, required=True)
    canary_parser.add_argument("--head-ref", default="")
    canary_parser.add_argument("--openscad")
    canary_parser.set_defaults(func=command_canary)

    run = sub.add_parser("run", help="compare a part between two checkouts")
    run.add_argument("--part", required=True)
    run.add_argument("--base-root", type=Path, required=True)
    run.add_argument("--out", type=Path, required=True)
    run.add_argument("--base-ref", default="")
    run.add_argument("--head-ref", default="")
    run.add_argument("--openscad")
    run.add_argument("--jobs", type=int, help="concurrent OpenSCAD processes (default: one per core)")
    run.set_defaults(func=command_run)

    report = sub.add_parser("report", help="turn a result.json into Markdown")
    report.add_argument("--result", required=True)
    report.add_argument("--canary")
    report.add_argument("--image-base-url", default="")
    report.add_argument("--note", action="append")
    report.add_argument("--out", type=Path, required=True)
    report.set_defaults(func=command_report)

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        return args.func(args)
    except SpecError as exc:
        print(f"spec error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
