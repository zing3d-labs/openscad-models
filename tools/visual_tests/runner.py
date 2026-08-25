"""Running a part's feature tests across two checkouts and collecting results."""

from __future__ import annotations

import json
import os
import time
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .compare import ImageComparison, compare_images, pixel_hash
from .measure import MeshError, Measurements, changed_metrics, compare as compare_measurements, measure
from .openscad import OpenSCAD, RenderError
from .spec import Case, Feature, Spec, load_spec

RESULT_FILENAME = "result.json"


@dataclass
class Side:
    """One end of the comparison: a checkout, and the OpenSCAD that reads it."""

    name: str
    root: Path
    openscad: OpenSCAD
    ref: str = ""

    @classmethod
    def create(cls, name: str, root: Path, binary: str | None, ref: str = "") -> "Side":
        return cls(name=name, root=root.resolve(), openscad=OpenSCAD(root, binary), ref=ref)


def _render_case(
    side: Side,
    part: Path,
    feature: Feature,
    case: Case,
    work: Path,
    *,
    want_image: bool,
) -> tuple[Path | None, Measurements | None, list[str]]:
    """Render one case on one side. Returns (image path, measurements, errors)."""
    errors: list[str] = []
    source = side.root / part
    if not source.is_file():
        return None, None, [f"{side.name}: {part} does not exist in this checkout"]

    image_path: Path | None = None
    if want_image:
        image_path = work / "images" / feature.key / case.name / f"{side.name}.png"
        try:
            side.openscad.render_image(
                source,
                image_path,
                camera=feature.camera,
                imgsize=feature.imgsize,
                colorscheme=feature.colorscheme,
                parameters=case.parameters,
            )
        except RenderError as exc:
            errors.append(f"{side.name}: image render failed — {exc}")
            image_path = None

    measurements: Measurements | None = None
    mesh_path = work / "meshes" / feature.key / case.name / f"{side.name}.stl"
    try:
        side.openscad.export_mesh(source, mesh_path, parameters=case.parameters)
        measurements = measure(mesh_path)
    except (RenderError, MeshError) as exc:
        errors.append(f"{side.name}: measurement failed — {exc}")
    finally:
        # The mesh is an intermediate: never compared byte-for-byte, never
        # published. Dropping it keeps the artifact to images and numbers.
        mesh_path.unlink(missing_ok=True)

    return image_path, measurements, errors


def default_jobs() -> int:
    """One OpenSCAD per core. Rendering is a single-threaded CPU grind, so the
    cheapest speed-up available is to run the cases alongside each other."""
    return max(1, (os.cpu_count() or 2))


def _compare_case(
    part: Path,
    feature: Feature,
    case: Case,
    base: Side,
    head: Side,
    work: Path,
) -> dict[str, Any]:
    want_image = case.render
    base_image, base_measurements, errors = _render_case(
        base, part, feature, case, work, want_image=want_image
    )
    head_image, head_measurements, head_errors = _render_case(
        head, part, feature, case, work, want_image=want_image
    )
    errors = errors + head_errors

    metrics: dict[str, Any] | None = None
    if base_measurements and head_measurements:
        metrics = compare_measurements(base_measurements, head_measurements)

    image: dict[str, Any] | None = None
    images: dict[str, str] = {}
    if want_image and base_image and head_image:
        diff_path = work / "images" / feature.key / case.name / "diff.png"
        comparison: ImageComparison = compare_images(base_image, head_image, diff_path)
        image = comparison.to_dict()
        images = {
            "base": str(base_image.relative_to(work)),
            "head": str(head_image.relative_to(work)),
        }
        if diff_path.is_file():
            images["diff"] = str(diff_path.relative_to(work))
    elif want_image and head_image:
        # No before to compare against — a brand new part, or a base render
        # that failed. Still show what the head looks like.
        images = {"head": str(head_image.relative_to(work))}

    changed = bool(image and image["changed"]) or bool(metrics and changed_metrics(metrics))
    return {
        "name": case.name,
        "parameters": case.parameters,
        "rendered": want_image,
        "changed": changed,
        "image": image,
        "images": images,
        "metrics": metrics,
        "base": base_measurements.to_dict() if base_measurements else None,
        "head": head_measurements.to_dict() if head_measurements else None,
        "errors": errors,
    }


def run_part(
    part: Path,
    spec: Spec,
    base: Side,
    head: Side,
    work: Path,
    jobs: int | None = None,
) -> dict[str, Any]:
    """Measure every case and picture the designated ones, on both sides."""
    work.mkdir(parents=True, exist_ok=True)
    started = time.monotonic()
    features: list[dict[str, Any]] = []
    workers = jobs or default_jobs()

    with ThreadPoolExecutor(max_workers=workers) as pool:
        pending = {
            feature.key: [
                pool.submit(_compare_case, part, feature, case, base, head, work)
                for case in feature.cases
            ]
            for feature in spec.features
        }
        results = {key: [future.result() for future in futures] for key, futures in pending.items()}

    for feature in spec.features:
        case_results = results[feature.key]
        features.append(
            {
                "key": feature.key,
                "label": feature.label,
                "description": feature.description,
                "camera": {"eye": list(feature.camera.eye), "center": list(feature.camera.center)},
                "changed": any(c["changed"] for c in case_results),
                "errors": [e for c in case_results for e in c["errors"]],
                "cases": case_results,
            }
        )

    return {
        "part": str(part),
        "spec": str(spec.path),
        "description": spec.description,
        "base_ref": base.ref,
        "head_ref": head.ref,
        "openscad": head.openscad.version(),
        "duration_seconds": round(time.monotonic() - started, 1),
        "jobs": workers,
        "case_count": spec.case_count,
        "render_count": spec.render_count,
        "changed": any(f["changed"] for f in features),
        "errors": [e for f in features for e in f["errors"]],
        "features": features,
    }


def canary(part: Path, spec: Spec, side: Side, work: Path) -> dict[str, Any]:
    """Render one case twice from the same commit and assert nothing moved.

    Exact comparison rests on the renderer being deterministic. This is the
    cheap check that says so out loud, on the machine that is about to do the
    comparing, rather than leaving the assumption to decay silently into
    "every case changed, every time".
    """
    feature = next((f for f in spec.features if f.rendered_cases), None)
    if feature is None:
        return {"ran": False, "reason": "no rendered case in the spec to canary with"}
    case = feature.rendered_cases[0]

    first = Side(name="canary-1", root=side.root, openscad=side.openscad, ref=side.ref)
    second = Side(name="canary-2", root=side.root, openscad=side.openscad, ref=side.ref)
    first_image, first_measurements, errors = _render_case(
        first, part, feature, case, work, want_image=True
    )
    second_image, second_measurements, more_errors = _render_case(
        second, part, feature, case, work, want_image=True
    )
    errors += more_errors

    result: dict[str, Any] = {
        "ran": True,
        "feature": feature.key,
        "case": case.name,
        "errors": errors,
        "image_stable": None,
        "metrics_stable": None,
        "triangle_count_stable": None,
    }
    if first_image and second_image:
        comparison = compare_images(first_image, second_image, work / "images" / "canary-diff.png")
        result["image_stable"] = not comparison.changed
        result["image"] = comparison.to_dict()
        result["hashes"] = [pixel_hash(first_image), pixel_hash(second_image)]
    if first_measurements and second_measurements:
        metrics = compare_measurements(first_measurements, second_measurements)
        result["metrics"] = metrics
        result["metrics_stable"] = not changed_metrics(metrics)
        result["triangle_count_stable"] = not metrics["triangle_count"]["changed"]
    result["passed"] = bool(
        not errors and result["image_stable"] and result["metrics_stable"]
    )
    return result


def load_part_spec(repo_root: Path, part: Path) -> Spec:
    from .deps import spec_path_for

    return load_spec(repo_root / spec_path_for(part), repo_root)


def write_result(work: Path, result: dict[str, Any]) -> Path:
    path = work / RESULT_FILENAME
    path.write_text(json.dumps(result, indent=2, sort_keys=False) + "\n", encoding="utf-8")
    return path
