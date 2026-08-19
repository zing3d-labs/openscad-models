"""Markdown for the PR comment and the job summary.

The comment shows changed features only, with before / after / diff inline per
parameter case. Features whose render and numbers did not move collapse to a
one-line summary, so a PR that touches one feature does not bury it under
everything that stayed put.

GitHub caps a comment body at 65536 characters. Rather than truncating in the
middle of a table, the report is built at the richest detail level that fits
and steps down through progressively cheaper forms.
"""

from __future__ import annotations

from pathlib import PurePosixPath
from typing import Any

from .openscad import BACKEND

COMMENT_LIMIT = 65536
# Room for GitHub to be stricter than documented, and for anything a caller
# appends after the fact.
COMMENT_BUDGET = COMMENT_LIMIT - 2048

THUMBNAIL_WIDTH = 300

# Detail levels, richest first. The report is built at the first one that
# fits inside GitHub's comment limit.
FULL, COLLAPSED, LINKS, COMPACT, SUMMARY_ONLY = range(5)


def marker(part: str) -> str:
    """Hidden key the workflow finds an existing comment by, so it can be
    updated in place rather than stacking a new comment on every push."""
    return f"<!-- visual-regression: {part} -->"


def _part_name(part: str) -> str:
    return PurePosixPath(part).stem


def _image_url(base_url: str, part: str, relative: str) -> str:
    slug = _part_name(part)
    return f"{base_url.rstrip('/')}/{slug}/{relative}"


def _short(ref: str) -> str:
    return ref[:7] if len(ref) > 7 else ref


def _format_number(value: float) -> str:
    return f"{value:,.2f}"


def _bbox_phrase(bbox: dict[str, Any]) -> str:
    """Say what actually moved.

    A bounding box can change by growing or by sliding: shifting a part along
    an axis moves both corners and leaves the size alone. Reporting size only
    produces "bbox 112.00 x 112.00 -> 112.00 x 112.00", which reads as a
    contradiction rather than as a translation.
    """
    before, after = bbox["before"], bbox["after"]
    size_before = [hi - lo for lo, hi in zip(before["min"], before["max"])]
    size_after = [hi - lo for lo, hi in zip(after["min"], after["max"])]
    shift = [a - b for b, a in zip(before["min"], after["min"])]
    tolerance = bbox.get("tolerance", 0.0)

    resized = any(abs(a - b) > tolerance for b, a in zip(size_before, size_after))
    moved = any(abs(d) > tolerance for d in shift)

    phrases = []
    if resized:
        phrases.append(
            "**bbox "
            + " × ".join(f"{v:,.2f}" for v in size_before)
            + " → "
            + " × ".join(f"{v:,.2f}" for v in size_after)
            + " mm**"
        )
    if moved:
        phrases.append("**moved by (" + ", ".join(f"{d:+,.2f}" for d in shift) + ") mm**")
    if not phrases:
        # Below the per-axis tolerance on every axis, yet over it on the
        # combined corner comparison. Say so rather than printing nothing.
        phrases.append(f"**bbox shifted by up to {bbox['max_delta']:,.4f} mm**")
    return ", ".join(phrases)


def _metric_sentence(metrics: dict[str, Any] | None) -> str:
    if not metrics:
        return "measurements unavailable"
    parts: list[str] = []
    body = metrics["body_count"]
    if body["changed"]:
        parts.append(f"**bodies {body['before']} → {body['after']}**")
    volume = metrics["volume"]
    if volume["changed"]:
        parts.append(
            f"**volume {_format_number(volume['before'])} → {_format_number(volume['after'])} mm³**"
            f" ({volume['delta']:+,.2f})"
        )
    bbox = metrics["bbox"]
    if bbox["changed"]:
        parts.append(_bbox_phrase(bbox))
    triangles = metrics["triangle_count"]
    if triangles["changed"]:
        parts.append(f"triangles {triangles['before']:,} → {triangles['after']:,} (informational)")
    if not parts:
        return "numbers unchanged"
    return ", ".join(parts)


def _parameter_sentence(parameters: dict[str, Any], baseline: dict[str, Any]) -> str:
    """Show only what this case varies relative to the feature's baseline."""
    varied = {k: v for k, v in parameters.items() if baseline.get(k) != v}
    source = varied or parameters
    return ", ".join(f"`{k}={v}`" for k, v in sorted(source.items())) or "defaults"


def _baseline_parameters(feature: dict[str, Any]) -> dict[str, Any]:
    """Parameters every case in the feature shares, so they can go unmentioned."""
    cases = feature["cases"]
    if not cases:
        return {}
    shared = dict(cases[0]["parameters"])
    for case in cases[1:]:
        for key, value in list(shared.items()):
            if case["parameters"].get(key) != value:
                shared.pop(key)
    return shared


def _case_block(
    case: dict[str, Any],
    feature: dict[str, Any],
    part: str,
    base_url: str | None,
    detail: int,
) -> list[str]:
    lines: list[str] = []
    title = _parameter_sentence(case["parameters"], _baseline_parameters(feature))
    image = case.get("image") or {}
    if image.get("changed"):
        stat = (
            f"{image['changed_pixels']:,} of {image['total_pixels']:,} pixels "
            f"({image['changed_percent']:.3f}%), max channel delta {image['max_channel_delta']}"
        )
    elif case["rendered"]:
        stat = "render identical"
    else:
        stat = "measured only"

    lines.append(f"**{title}** — {stat}")
    lines.append("")
    lines.append(_metric_sentence(case.get("metrics")))
    lines.append("")

    images = case.get("images") or {}
    if images and base_url and detail in (FULL, COLLAPSED):
        columns = [key for key in ("base", "head", "diff") if key in images]
        headers = {"base": "before", "head": "after", "diff": "diff (×16)"}
        lines.append("| " + " | ".join(headers[c] for c in columns) + " |")
        lines.append("| " + " | ".join("---" for _ in columns) + " |")
        cells = [
            f'<img src="{_image_url(base_url, part, images[c])}" width="{THUMBNAIL_WIDTH}">'
            for c in columns
        ]
        lines.append("| " + " | ".join(cells) + " |")
        lines.append("")
    elif images and base_url and detail == LINKS:
        links = [f"[{key}]({_image_url(base_url, part, path)})" for key, path in images.items()]
        lines.append("Images: " + " · ".join(links))
        lines.append("")
    for error in case.get("errors") or []:
        lines.append(f"> ⚠️ {error}")
        lines.append("")
    return lines


def _render(result: dict[str, Any], base_url: str | None, detail: int, notes: list[str]) -> str:
    part = result["part"]
    changed = [f for f in result["features"] if f["changed"]]
    unchanged = [f for f in result["features"] if not f["changed"]]

    lines = [marker(part), ""]
    lines.append(f"### Visual regression — `{_part_name(part)}`")
    lines.append("")
    headline = (
        f"**{len(changed)} of {len(result['features'])} features changed.**"
        if changed
        else "**No feature changed.**"
    )
    lines.append(
        f"{headline} {result['case_count']} cases measured, {result['render_count']} rendered. "
        f"Merge base `{_short(result['base_ref'])}` → `{_short(result['head_ref'])}`."
    )
    lines.append("")
    lines.append("_Advisory: this check reports what moved, it never fails a PR._")
    lines.append("")
    for note in notes:
        lines.append(f"> {note}")
        lines.append("")

    if base_url is None and changed:
        lines.append(
            "> Images are not published for this run — a pull request from a fork gets a "
            "read-only token, so there is nowhere to host them. Every image is in the "
            "run's artifact."
        )
        lines.append("")

    for feature in changed:
        heading = f"#### {feature['label']} — changed"
        if detail == COMPACT:
            lines.append(f"<details><summary>{feature['label']} — changed</summary>")
            lines.append("")
            for case in feature["cases"]:
                if case["changed"]:
                    lines.append(
                        f"- {_parameter_sentence(case['parameters'], _baseline_parameters(feature))}"
                        f" — {_metric_sentence(case.get('metrics'))}"
                    )
            lines.append("")
            lines.append("</details>")
            lines.append("")
            continue
        if detail == SUMMARY_ONLY:
            lines.append(
                f"- **{feature['label']}** — "
                f"{sum(1 for c in feature['cases'] if c['changed'])} of {len(feature['cases'])} cases changed"
            )
            continue
        body: list[str] = []
        if feature["description"]:
            body += [feature["description"], ""]
        for case in feature["cases"]:
            if case["changed"]:
                body += _case_block(case, feature, part, base_url, detail)
        steady = sum(1 for c in feature["cases"] if not c["changed"])
        if steady:
            body.append(f"_{steady} other case(s) in this feature did not change._")
            body.append("")
        if detail == FULL:
            lines.append(heading)
            lines.append("")
            lines += body
        else:
            lines.append(f"<details><summary>{feature['label']} — changed</summary>")
            lines.append("")
            lines += body
            lines.append("</details>")
            lines.append("")

    if unchanged:
        lines.append(f"<details><summary>Unchanged features ({len(unchanged)})</summary>")
        lines.append("")
        for feature in unchanged:
            lines.append(f"- **{feature['label']}** — {len(feature['cases'])} cases, no change")
        lines.append("")
        lines.append("</details>")
        lines.append("")

    if result.get("errors"):
        lines.append("<details><summary>Errors</summary>")
        lines.append("")
        for error in dict.fromkeys(result["errors"]):
            lines.append(f"- {error}")
        lines.append("")
        lines.append("</details>")
        lines.append("")

    lines.append(
        f"<sub>OpenSCAD `{result['openscad'].splitlines()[0] if result['openscad'] else 'unknown'}`, "
        f"backend `{BACKEND}` · {result['duration_seconds']}s · "
        "full-resolution images are attached to the workflow run as an artifact.</sub>"
    )
    return "\n".join(lines).rstrip() + "\n"


def build_comment(result: dict[str, Any], base_url: str | None, notes: list[str] | None = None) -> str:
    """The richest form of the report that fits inside GitHub's comment limit."""
    notes = list(notes or [])
    for detail in (FULL, COLLAPSED, LINKS, COMPACT, SUMMARY_ONLY):
        extra = list(notes)
        if detail != FULL:
            extra.append(
                "This report was shortened to fit GitHub's comment size limit. "
                "The workflow artifact has every image at full resolution."
            )
        body = _render(result, base_url, detail, extra)
        if len(body) <= COMMENT_BUDGET:
            return body
    truncated = _render(result, base_url, SUMMARY_ONLY, notes + ["Report truncated."])
    return truncated[: COMMENT_BUDGET - 200] + "\n\n_…truncated. See the workflow artifact._\n"


def canary_note(canary: dict[str, Any]) -> str | None:
    """One line about the determinism check, for the top of the report."""
    if not canary.get("ran"):
        return None
    if canary.get("passed"):
        if canary.get("triangle_count_stable") is False:
            # Not a failure: triangle count is informational precisely because a
            # mesh generator may tessellate the same solid differently. Worth
            # saying once, so nobody reads a count change below as a finding.
            return (
                "Note: the same commit meshed twice produced different triangle counts, so "
                "triangle count is noise in this environment. The other measurements held."
            )
        return None
    problems = []
    if canary.get("image_stable") is False:
        image = canary.get("image") or {}
        problems.append(
            f"the same commit rendered twice produced different images "
            f"({image.get('changed_pixels', '?')} pixels)"
        )
    if canary.get("metrics_stable") is False:
        problems.append("the same commit measured twice produced different numbers")
    for error in canary.get("errors") or []:
        problems.append(error)
    return (
        "⚠️ **The determinism canary failed**: "
        + "; ".join(problems)
        + ". Exact comparison assumes an identical commit renders identically, so "
        "every 'changed' below may be noise rather than a real difference."
    )
