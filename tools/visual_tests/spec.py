"""Loading and validation for `<part>.tests.yaml` sidecar specs.

The organising unit is a **feature**, not a part: one part has many feature
tests, each with the camera angle that shows that feature and the parameter
combinations that prove it works. See docs/visual-regression-tests.md.

Each feature has two axes. Every case is *measured* (bounding box, volume,
triangle count, connected body count — cheap), and the cases marked
`render: true` are additionally *pictured* from the feature's camera.
"""

from __future__ import annotations

import itertools
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml

SCHEMA_VERSION = 1

DEFAULT_IMGSIZE = (1000, 750)
DEFAULT_COLORSCHEME = "Tomorrow Night"


class SpecError(Exception):
    """A sidecar spec is missing, malformed, or self-inconsistent."""


@dataclass(frozen=True)
class Camera:
    eye: tuple[float, float, float]
    center: tuple[float, float, float]

    def as_argument(self) -> str:
        """The six-value `--camera` form: eye position then look-at point."""
        return ",".join(f"{v:g}" for v in (*self.eye, *self.center))


@dataclass(frozen=True)
class Case:
    name: str
    parameters: dict[str, Any]
    render: bool


@dataclass(frozen=True)
class Feature:
    key: str
    label: str
    description: str
    camera: Camera
    imgsize: tuple[int, int]
    colorscheme: str
    cases: tuple[Case, ...]

    @property
    def rendered_cases(self) -> tuple[Case, ...]:
        return tuple(c for c in self.cases if c.render)


@dataclass(frozen=True)
class Spec:
    path: Path
    part: Path
    description: str
    features: tuple[Feature, ...] = field(default=())

    @property
    def case_count(self) -> int:
        return sum(len(f.cases) for f in self.features)

    @property
    def render_count(self) -> int:
        return sum(len(f.rendered_cases) for f in self.features)


def _slug(value: Any) -> str:
    text = re.sub(r"[^A-Za-z0-9]+", "-", str(value)).strip("-")
    return text or "none"


def case_name(parameters: dict[str, Any]) -> str:
    """A stable, filename-safe name derived from the parameters themselves.

    Derived rather than required so a sweep of two dozen cases does not need
    two dozen hand-written names. Sorted so the name does not depend on the
    order the keys happen to appear in the YAML.
    """
    if not parameters:
        return "default"
    return "_".join(f"{_slug(k)}-{_slug(v)}" for k, v in sorted(parameters.items()))


def _as_vec3(value: Any, where: str) -> tuple[float, float, float]:
    if not isinstance(value, (list, tuple)) or len(value) != 3:
        raise SpecError(f"{where}: expected three numbers, got {value!r}")
    try:
        return (float(value[0]), float(value[1]), float(value[2]))
    except (TypeError, ValueError) as exc:
        raise SpecError(f"{where}: expected three numbers, got {value!r}") from exc


def _as_camera(value: Any, where: str) -> Camera:
    if not isinstance(value, dict):
        raise SpecError(f"{where}: expected a mapping with 'eye' and 'center'")
    missing = {"eye", "center"} - set(value)
    if missing:
        raise SpecError(f"{where}: missing {', '.join(sorted(missing))}")
    unknown = set(value) - {"eye", "center"}
    if unknown:
        raise SpecError(f"{where}: unknown key(s) {', '.join(sorted(unknown))}")
    return Camera(
        eye=_as_vec3(value["eye"], f"{where}.eye"),
        center=_as_vec3(value["center"], f"{where}.center"),
    )


def _as_imgsize(value: Any, where: str) -> tuple[int, int]:
    if not isinstance(value, (list, tuple)) or len(value) != 2:
        raise SpecError(f"{where}: expected [width, height], got {value!r}")
    try:
        width, height = int(value[0]), int(value[1])
    except (TypeError, ValueError) as exc:
        raise SpecError(f"{where}: expected [width, height], got {value!r}") from exc
    if width <= 0 or height <= 0:
        raise SpecError(f"{where}: width and height must be positive")
    return (width, height)


def _as_parameters(value: Any, where: str) -> dict[str, Any]:
    if value is None:
        return {}
    if not isinstance(value, dict):
        raise SpecError(f"{where}: expected a mapping of OpenSCAD variable to value")
    for key in value:
        if not isinstance(key, str) or not re.fullmatch(r"[A-Za-z_$][A-Za-z0-9_]*", key):
            raise SpecError(f"{where}: {key!r} is not a valid OpenSCAD variable name")
    return dict(value)


def _expand_matrix(matrix: Any, where: str) -> list[dict[str, Any]]:
    """Cartesian product of a `matrix:` block, in declaration order."""
    if matrix is None:
        return []
    if not isinstance(matrix, dict) or not matrix:
        raise SpecError(f"{where}: expected a non-empty mapping of variable to value list")
    keys = list(matrix)
    value_lists = []
    for key in keys:
        values = matrix[key]
        if not isinstance(values, (list, tuple)) or not values:
            raise SpecError(f"{where}.{key}: expected a non-empty list of values")
        value_lists.append(list(values))
    return [dict(zip(keys, combo)) for combo in itertools.product(*value_lists)]


def _build_cases(raw: dict[str, Any], base_parameters: dict[str, Any], where: str) -> tuple[Case, ...]:
    ordered: dict[str, Case] = {}

    for parameters in _expand_matrix(raw.get("matrix"), f"{where}.matrix"):
        merged = {**base_parameters, **parameters}
        name = case_name(parameters)
        ordered[name] = Case(name=name, parameters=merged, render=False)

    raw_cases = raw.get("cases") or []
    if not isinstance(raw_cases, list):
        raise SpecError(f"{where}.cases: expected a list")
    for index, entry in enumerate(raw_cases):
        location = f"{where}.cases[{index}]"
        if not isinstance(entry, dict):
            raise SpecError(f"{location}: expected a mapping")
        unknown = set(entry) - {"name", "params", "render"}
        if unknown:
            raise SpecError(f"{location}: unknown key(s) {', '.join(sorted(unknown))}")
        parameters = _as_parameters(entry.get("params"), f"{location}.params")
        name = entry.get("name") or case_name(parameters)
        if not isinstance(name, str) or not name.strip():
            raise SpecError(f"{location}.name: expected a non-empty string")
        render = entry.get("render", False)
        if not isinstance(render, bool):
            raise SpecError(f"{location}.render: expected true or false")
        merged = {**base_parameters, **parameters}
        # A named case restates a matrix combination when it wants a render;
        # the explicit entry wins so `render: true` is not silently dropped.
        ordered[name] = Case(name=name, parameters=merged, render=render)

    if not ordered:
        raise SpecError(f"{where}: define at least one case, via 'cases' or 'matrix'")
    return tuple(ordered.values())


def load_spec(path: Path, repo_root: Path) -> Spec:
    """Read and validate one sidecar spec."""
    try:
        raw = yaml.safe_load(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise SpecError(f"{path}: no such file") from exc
    except yaml.YAMLError as exc:
        raise SpecError(f"{path}: not valid YAML — {exc}") from exc
    if not isinstance(raw, dict):
        raise SpecError(f"{path}: expected a mapping at the top level")

    unknown = set(raw) - {"version", "part", "description", "defaults", "features"}
    if unknown:
        raise SpecError(f"{path}: unknown top-level key(s) {', '.join(sorted(unknown))}")

    version = raw.get("version")
    if version != SCHEMA_VERSION:
        raise SpecError(
            f"{path}: version {version!r} is not supported (this tooling reads version {SCHEMA_VERSION})"
        )

    part_name = raw.get("part") or path.name.replace(".tests.yaml", ".scad")
    part = (path.parent / part_name).resolve()
    if not part.is_file():
        raise SpecError(f"{path}: part {part_name!r} does not exist beside the spec")

    defaults = raw.get("defaults") or {}
    if not isinstance(defaults, dict):
        raise SpecError(f"{path}: 'defaults' must be a mapping")
    unknown = set(defaults) - {"camera", "imgsize", "colorscheme", "parameters"}
    if unknown:
        raise SpecError(f"{path}: unknown defaults key(s) {', '.join(sorted(unknown))}")
    default_camera = _as_camera(defaults["camera"], f"{path}: defaults.camera") if "camera" in defaults else None
    default_imgsize = (
        _as_imgsize(defaults["imgsize"], f"{path}: defaults.imgsize")
        if "imgsize" in defaults
        else DEFAULT_IMGSIZE
    )
    default_colorscheme = str(defaults.get("colorscheme", DEFAULT_COLORSCHEME))
    default_parameters = _as_parameters(defaults.get("parameters"), f"{path}: defaults.parameters")

    raw_features = raw.get("features")
    if not isinstance(raw_features, dict) or not raw_features:
        raise SpecError(f"{path}: 'features' must be a non-empty mapping of feature key to definition")

    features: list[Feature] = []
    for key, definition in raw_features.items():
        where = f"{path}: features.{key}"
        if not isinstance(definition, dict):
            raise SpecError(f"{where}: expected a mapping")
        unknown = set(definition) - {
            "label",
            "description",
            "camera",
            "imgsize",
            "colorscheme",
            "parameters",
            "cases",
            "matrix",
        }
        if unknown:
            raise SpecError(f"{where}: unknown key(s) {', '.join(sorted(unknown))}")
        camera = _as_camera(definition["camera"], f"{where}.camera") if "camera" in definition else default_camera
        if camera is None:
            raise SpecError(f"{where}: no camera, and no defaults.camera to fall back on")
        imgsize = (
            _as_imgsize(definition["imgsize"], f"{where}.imgsize")
            if "imgsize" in definition
            else default_imgsize
        )
        base_parameters = {
            **default_parameters,
            **_as_parameters(definition.get("parameters"), f"{where}.parameters"),
        }
        features.append(
            Feature(
                key=str(key),
                label=str(definition.get("label") or key),
                description=str(definition.get("description") or ""),
                camera=camera,
                imgsize=imgsize,
                colorscheme=str(definition.get("colorscheme", default_colorscheme)),
                cases=_build_cases(definition, base_parameters, where),
            )
        )

    return Spec(
        path=path.relative_to(repo_root) if path.is_relative_to(repo_root) else path,
        part=part.relative_to(repo_root) if part.is_relative_to(repo_root) else part,
        description=str(raw.get("description") or ""),
        features=tuple(features),
    )
