"""Numeric geometry measurements taken from an exported mesh.

Cheap enough to run on every parameter case, and they see what a single camera
angle cannot — a change on the far side of the model, or a solid that has come
apart into pieces.

Connected body count is the highest-value measurement here: it is what catches
a model that has silently split into separate solids. It is computed directly
from the mesh rather than read out of a CGAL summary, because that summary
reports bodies + 1 (Nef counts the unbounded outer volume) and omits the field
entirely for simple models that never go through Nef.

Mesh *bytes* are never compared: CGAL emits triangles in a nondeterministic
order, so identical solids routinely produce different file hashes.
"""

from __future__ import annotations

import struct
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

import numpy as np

# Tolerances are relative to the model's own size — an absolute envelope flaps
# in a parametric repository where one case is 30 mm across and the next is 300.
BBOX_TOLERANCE_FRACTION = 1e-6  # of the bounding-box diagonal
VOLUME_TOLERANCE_FRACTION = 1e-6  # of the volume itself


class MeshError(Exception):
    """A mesh file could not be read."""


@dataclass(frozen=True)
class Measurements:
    triangle_count: int
    body_count: int
    volume: float
    bbox_min: tuple[float, float, float]
    bbox_max: tuple[float, float, float]

    @property
    def bbox_size(self) -> tuple[float, float, float]:
        return tuple(float(hi - lo) for lo, hi in zip(self.bbox_min, self.bbox_max))  # type: ignore[return-value]

    @property
    def bbox_diagonal(self) -> float:
        return float(np.linalg.norm(np.array(self.bbox_size)))

    def to_dict(self) -> dict[str, Any]:
        data = asdict(self)
        data["bbox_size"] = list(self.bbox_size)
        data["bbox_min"] = list(self.bbox_min)
        data["bbox_max"] = list(self.bbox_max)
        return data

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Measurements":
        return cls(
            triangle_count=int(data["triangle_count"]),
            body_count=int(data["body_count"]),
            volume=float(data["volume"]),
            bbox_min=tuple(float(v) for v in data["bbox_min"]),  # type: ignore[arg-type]
            bbox_max=tuple(float(v) for v in data["bbox_max"]),  # type: ignore[arg-type]
        )


def read_triangles(path: Path) -> np.ndarray:
    """Return an (N, 3, 3) array of triangle vertices from a binary or ASCII STL."""
    data = path.read_bytes()
    if len(data) < 84:
        raise MeshError(f"{path}: too short to be an STL ({len(data)} bytes)")

    (count,) = struct.unpack_from("<I", data, 80)
    if len(data) == 84 + count * 50:
        raw = np.frombuffer(data, dtype=np.uint8, count=count * 50, offset=84).reshape(count, 50)
        # 12 little-endian float32: normal, then the three vertices.
        floats = raw[:, :48].copy().view("<f4").reshape(count, 12)
        return floats[:, 3:].reshape(count, 3, 3).astype(np.float64)

    text = data.decode("utf-8", errors="replace")
    if "vertex" not in text:
        raise MeshError(f"{path}: not a recognisable binary or ASCII STL")
    values = [
        [float(part) for part in line.split()[1:4]]
        for line in text.splitlines()
        if line.strip().startswith("vertex")
    ]
    if not values or len(values) % 3:
        raise MeshError(f"{path}: ASCII STL has {len(values)} vertices, not a whole number of triangles")
    return np.array(values, dtype=np.float64).reshape(-1, 3, 3)


def _connected_bodies(triangles: np.ndarray) -> int:
    """Count connected components, joining triangles that share a vertex.

    Vertices are matched on their exact exported coordinates. Shared vertices
    come out of the mesh generator bit-identical, so no quantisation is needed,
    and quantising would risk splitting a shared vertex that happened to sit on
    a rounding boundary.
    """
    if triangles.size == 0:
        return 0
    flat = triangles.reshape(-1, 3)
    _unique, inverse = np.unique(flat, axis=0, return_inverse=True)
    inverse = inverse.reshape(-1, 3)

    parent = np.arange(int(inverse.max()) + 1)

    def find(node: int) -> int:
        root = node
        while parent[root] != root:
            root = parent[root]
        while parent[node] != root:  # path compression
            parent[node], node = root, parent[node]
        return root

    for a, b, c in inverse:
        root_a = find(int(a))
        for other in (int(b), int(c)):
            root_other = find(other)
            if root_a != root_other:
                parent[root_other] = root_a
    return len({find(int(v)) for v in np.unique(inverse)})


def measure(path: Path) -> Measurements:
    triangles = read_triangles(path)
    if triangles.size == 0:
        raise MeshError(f"{path}: mesh has no triangles")
    vertices = triangles.reshape(-1, 3)
    # Signed volume as the sum of tetrahedra from the origin.
    v0, v1, v2 = triangles[:, 0], triangles[:, 1], triangles[:, 2]
    volume = float(abs(np.einsum("ij,ij->i", v0, np.cross(v1, v2)).sum() / 6.0))
    return Measurements(
        triangle_count=int(triangles.shape[0]),
        body_count=_connected_bodies(triangles),
        volume=volume,
        bbox_min=tuple(float(v) for v in vertices.min(axis=0)),  # type: ignore[arg-type]
        bbox_max=tuple(float(v) for v in vertices.max(axis=0)),  # type: ignore[arg-type]
    )


def compare(before: Measurements, after: Measurements) -> dict[str, dict[str, Any]]:
    """Per-metric comparison. Each entry says whether it changed, and by how much.

    Triangle count is reported but flagged `informational`: mesh generators are
    free to tessellate the same solid differently, so a bare count change is a
    hint rather than a finding. The same-commit canary is what establishes
    whether it is trustworthy in a given environment.
    """
    diagonal = max(before.bbox_diagonal, after.bbox_diagonal, 1e-9)
    bbox_tolerance = BBOX_TOLERANCE_FRACTION * diagonal
    volume_tolerance = VOLUME_TOLERANCE_FRACTION * max(abs(before.volume), abs(after.volume), 1e-9)

    bbox_deltas = [
        abs(a - b)
        for b, a in zip(
            (*before.bbox_min, *before.bbox_max),
            (*after.bbox_min, *after.bbox_max),
        )
    ]
    return {
        "body_count": {
            "before": before.body_count,
            "after": after.body_count,
            "changed": before.body_count != after.body_count,
            "informational": False,
        },
        "volume": {
            "before": before.volume,
            "after": after.volume,
            "delta": after.volume - before.volume,
            "tolerance": volume_tolerance,
            "changed": abs(after.volume - before.volume) > volume_tolerance,
            "informational": False,
        },
        "bbox": {
            "before": {"min": list(before.bbox_min), "max": list(before.bbox_max)},
            "after": {"min": list(after.bbox_min), "max": list(after.bbox_max)},
            "max_delta": max(bbox_deltas),
            "tolerance": bbox_tolerance,
            "changed": max(bbox_deltas) > bbox_tolerance,
            "informational": False,
        },
        "triangle_count": {
            "before": before.triangle_count,
            "after": after.triangle_count,
            "changed": before.triangle_count != after.triangle_count,
            "informational": True,
        },
    }


def changed_metrics(comparison: dict[str, dict[str, Any]], *, include_informational: bool = False) -> list[str]:
    return [
        name
        for name, result in comparison.items()
        if result["changed"] and (include_informational or not result["informational"])
    ]
