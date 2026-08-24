"""Transitive dependency scanning for .scad files, and part selection.

A part is affected by a change when the change touches any file the part
depends on, directly or transitively. `opengrid_cupholder.scad` does
`use <opengrid_facade.scad>`, so a facade change has to re-render the cup
holder too — matching on the changed paths alone would miss every shared
module case, which is most of the interesting ones.
"""

from __future__ import annotations

import re
from pathlib import Path

# `include <path>` / `use <path>`. OpenSCAD allows these anywhere a statement
# is allowed, so this is a scan rather than a line-anchored match.
INCLUDE_RE = re.compile(r"\b(include|use)\s*<([^>]*)>")

BLOCK_COMMENT_RE = re.compile(r"/\*.*?\*/", re.DOTALL)
LINE_COMMENT_RE = re.compile(r"//[^\n]*")

# Directories under a system folder that hold buildable models.
MODEL_DIRS = ("parts", "kits")


def _strip_comments(text: str) -> str:
    return LINE_COMMENT_RE.sub("", BLOCK_COMMENT_RE.sub("", text))


def _resolve(target: str, from_dir: Path, library_roots: list[Path]) -> Path | None:
    """Resolve an include target the way OpenSCAD does.

    Relative to the including file first, then against each library root
    (what OPENSCADPATH means to the binary).
    """
    candidate = (from_dir / target).resolve()
    if candidate.is_file():
        return candidate
    for root in library_roots:
        candidate = (root / target).resolve()
        if candidate.is_file():
            return candidate
    return None


def scad_dependencies(
    entry: Path,
    library_roots: list[Path] | None = None,
) -> tuple[set[Path], set[str]]:
    """Return (transitive dependency set including *entry*, unresolved targets).

    Unresolved targets are returned rather than raised on: a missing include is
    a build error OpenSCAD will report far more clearly than we can, and the
    caller may legitimately be scanning a tree with submodules uninitialised.
    """
    library_roots = library_roots or []
    entry = entry.resolve()
    seen: set[Path] = set()
    unresolved: set[str] = set()
    queue = [entry]
    while queue:
        current = queue.pop()
        if current in seen:
            continue
        seen.add(current)
        try:
            text = current.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for _kind, target in INCLUDE_RE.findall(_strip_comments(text)):
            resolved = _resolve(target, current.parent, library_roots)
            if resolved is None:
                unresolved.add(target)
            elif resolved not in seen:
                queue.append(resolved)
    return seen, unresolved


def discover_parts(repo_root: Path) -> list[Path]:
    """Every buildable model in the repo, as repo-relative paths.

    Any `<system>/parts/*.scad` or `<system>/kits/*.scad`, excluding
    `external/`, which holds third-party libraries rather than our models.
    """
    parts: list[Path] = []
    for scad in sorted(repo_root.glob("*/*/*.scad")):
        rel = scad.relative_to(repo_root)
        if rel.parts[0] == "external":
            continue
        if rel.parts[1] not in MODEL_DIRS:
            continue
        parts.append(rel)
    return parts


def spec_path_for(part: Path) -> Path:
    """The sidecar spec that sits beside a part file."""
    return part.with_suffix(".tests.yaml")


def submodule_paths(repo_root: Path) -> list[str]:
    """Submodule paths from .gitmodules, as repo-relative strings."""
    gitmodules = repo_root / ".gitmodules"
    if not gitmodules.is_file():
        return []
    return re.findall(
        r"^\s*path\s*=\s*(.+?)\s*$",
        gitmodules.read_text(encoding="utf-8"),
        re.MULTILINE,
    )


def affected_parts(
    repo_root: Path,
    changed_files: list[str],
) -> tuple[list[Path], dict[str, list[str]]]:
    """Select the parts a set of changed files affects.

    Returns (selected parts, {part: [changed files that reached it]}).

    A changed submodule shows up in `git diff` as a single gitlink path, so it
    is matched as a directory prefix: bumping the QuackWorks pin re-renders
    every part whose dependency set reaches into `external/QuackWorks/`, and
    nothing else.
    """
    changed = set(changed_files)
    submodules = [s for s in submodule_paths(repo_root) if s in changed]
    library_roots = [repo_root / "external"]

    selected: list[Path] = []
    reasons: dict[str, list[str]] = {}
    for part in discover_parts(repo_root):
        deps, _unresolved = scad_dependencies(repo_root / part, library_roots)
        rel_deps = set()
        for dep in deps:
            try:
                rel_deps.add(str(dep.relative_to(repo_root)))
            except ValueError:
                continue  # outside the repo; cannot be in a git diff
        # The sidecar spec is part of the test definition, so editing it alone
        # is enough to want the part re-run.
        rel_deps.add(str(spec_path_for(part)))

        hits = sorted(rel_deps & changed)
        for submodule in submodules:
            prefix = submodule.rstrip("/") + "/"
            if any(dep.startswith(prefix) for dep in rel_deps):
                hits.append(submodule)
        if hits:
            selected.append(part)
            reasons[str(part)] = sorted(set(hits))
    return selected, reasons
