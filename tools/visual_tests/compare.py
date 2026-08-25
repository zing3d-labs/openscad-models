"""Image comparison.

Comparison is exact: any differing pixel marks the case changed. There is no
tolerance to tune, which is only safe because both images come out of the same
binary in the same job — see openscad.py.

The same-commit canary in `cli.py` is what keeps that honest. It renders one
commit twice and asserts the two images are identical, so if byte-stability
ever stops holding the check says so loudly instead of quietly reporting every
case as changed.

Comparison is on decoded pixels rather than file bytes, so a PNG metadata
chunk cannot masquerade as a geometry change.
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image

# A raw absolute difference of a subtle geometry change is nearly black and
# unreadable in a review pane, so the diff image is amplified. Borrowed from
# Blender's image regression suite (`oiiotool --sub --abs --mulc 16`).
DIFF_AMPLIFICATION = 16


@dataclass(frozen=True)
class ImageComparison:
    changed: bool
    reason: str
    size_before: tuple[int, int]
    size_after: tuple[int, int]
    changed_pixels: int
    total_pixels: int
    max_channel_delta: int
    bounds: tuple[int, int, int, int] | None

    @property
    def changed_fraction(self) -> float:
        return self.changed_pixels / self.total_pixels if self.total_pixels else 0.0

    def to_dict(self) -> dict[str, Any]:
        return {
            "changed": self.changed,
            "reason": self.reason,
            "size_before": list(self.size_before),
            "size_after": list(self.size_after),
            "changed_pixels": self.changed_pixels,
            "total_pixels": self.total_pixels,
            "changed_percent": round(100 * self.changed_fraction, 4),
            "max_channel_delta": self.max_channel_delta,
            "bounds": list(self.bounds) if self.bounds else None,
        }


def _load(path: Path) -> np.ndarray:
    with Image.open(path) as image:
        return np.asarray(image.convert("RGB"), dtype=np.uint8)


def pixel_hash(path: Path) -> str:
    """Hash of the decoded pixels, ignoring PNG container metadata."""
    return hashlib.sha256(_load(path).tobytes()).hexdigest()


def compare_images(before: Path, after: Path, diff_output: Path | None = None) -> ImageComparison:
    lhs, rhs = _load(before), _load(after)
    size_before = (lhs.shape[1], lhs.shape[0])
    size_after = (rhs.shape[1], rhs.shape[0])

    if lhs.shape != rhs.shape:
        return ImageComparison(
            changed=True,
            reason="image size changed",
            size_before=size_before,
            size_after=size_after,
            changed_pixels=0,
            total_pixels=0,
            max_channel_delta=0,
            bounds=None,
        )

    delta = np.abs(lhs.astype(np.int16) - rhs.astype(np.int16))
    differing = delta.any(axis=2)
    changed_pixels = int(differing.sum())
    total_pixels = int(differing.size)

    bounds: tuple[int, int, int, int] | None = None
    if changed_pixels:
        rows = np.flatnonzero(differing.any(axis=1))
        cols = np.flatnonzero(differing.any(axis=0))
        bounds = (int(cols[0]), int(rows[0]), int(cols[-1]), int(rows[-1]))

    if diff_output is not None and changed_pixels:
        amplified = np.clip(delta * DIFF_AMPLIFICATION, 0, 255).astype(np.uint8)
        diff_output.parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(amplified).save(diff_output)

    return ImageComparison(
        changed=changed_pixels > 0,
        reason="pixels differ" if changed_pixels else "identical",
        size_before=size_before,
        size_after=size_after,
        changed_pixels=changed_pixels,
        total_pixels=total_pixels,
        max_channel_delta=int(delta.max()) if changed_pixels else 0,
        bounds=bounds,
    )
