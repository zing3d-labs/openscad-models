"""Invoking the OpenSCAD binary to produce a picture and a mesh.

Both sides of a comparison are rendered by this module, in the same job, with
the same binary. That is what makes exact comparison safe: a toolchain upgrade
moves before and after together and cancels out, so it cannot show up as a
false geometry change.
"""

from __future__ import annotations

import os
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .spec import Camera

# Pinned in one place. CGAL and Manifold disagree on facet count and on the
# low-order bits of a bounding box for an identical model, so the backend is
# part of the measurement, not an implementation detail.
BACKEND = "Manifold"

DEFAULT_TIMEOUT_SECONDS = 900


class RenderError(Exception):
    """OpenSCAD failed, or produced no output."""


@dataclass(frozen=True)
class Invocation:
    """What was run, kept so a failure can be reproduced by hand."""

    argv: list[str]
    returncode: int
    stdout: str
    stderr: str

    @property
    def command(self) -> str:
        return " ".join(_quote(a) for a in self.argv)


def _quote(arg: str) -> str:
    return arg if all(c.isalnum() or c in "-_=/.,:" for c in arg) else f"'{arg}'"


def format_parameter(value: Any) -> str:
    """Render a Python value as OpenSCAD source for `-D`."""
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return f"{value:g}" if isinstance(value, float) else str(value)
    if isinstance(value, (list, tuple)):
        return "[" + ",".join(format_parameter(v) for v in value) + "]"
    if value is None:
        return "undef"
    escaped = str(value).replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def parameter_arguments(parameters: dict[str, Any]) -> list[str]:
    return [f"{key}={format_parameter(value)}" for key, value in sorted(parameters.items())]


def find_binary(explicit: str | None = None) -> str:
    """Locate the OpenSCAD binary, preferring an explicit path or $OPENSCAD."""
    for candidate in (explicit, os.environ.get("OPENSCAD"), "openscad"):
        if not candidate:
            continue
        resolved = shutil.which(candidate) or (candidate if Path(candidate).is_file() else None)
        if resolved:
            return resolved
    raise RenderError(
        "OpenSCAD binary not found. Set $OPENSCAD or pass --openscad. "
        "See docs/visual-regression-tests.md for the version this repository pins."
    )


class OpenSCAD:
    def __init__(self, repo_root: Path, binary: str | None = None, timeout: int = DEFAULT_TIMEOUT_SECONDS):
        self.repo_root = repo_root.resolve()
        self.binary = find_binary(binary)
        self.timeout = timeout

    @property
    def env(self) -> dict[str, str]:
        env = dict(os.environ)
        # `include <BOSL2/std.scad>` is a library reference; everything else in
        # this repository reaches into external/ by relative path.
        env["OPENSCADPATH"] = str(self.repo_root / "external")
        return env

    def version(self) -> str:
        result = subprocess.run(
            [self.binary, "--version"],
            capture_output=True,
            text=True,
            env=self.env,
            timeout=60,
            check=False,
        )
        # OpenSCAD has historically printed its version on stderr.
        return (result.stdout + result.stderr).strip()

    def _run(self, argv: list[str], output: Path) -> Invocation:
        output.parent.mkdir(parents=True, exist_ok=True)
        try:
            result = subprocess.run(
                argv,
                capture_output=True,
                text=True,
                env=self.env,
                cwd=self.repo_root,
                timeout=self.timeout,
                check=False,
            )
        except subprocess.TimeoutExpired as exc:
            raise RenderError(f"OpenSCAD timed out after {self.timeout}s: {' '.join(argv)}") from exc
        invocation = Invocation(argv, result.returncode, result.stdout, result.stderr)
        if result.returncode != 0:
            raise RenderError(
                f"OpenSCAD exited {result.returncode}\n  command: {invocation.command}\n"
                f"  stderr: {result.stderr.strip()[-2000:]}"
            )
        if not output.is_file() or output.stat().st_size == 0:
            raise RenderError(
                f"OpenSCAD reported success but wrote no output to {output}\n"
                f"  command: {invocation.command}\n  stderr: {result.stderr.strip()[-2000:]}"
            )
        return invocation

    def render_image(
        self,
        source: Path,
        output: Path,
        *,
        camera: Camera,
        imgsize: tuple[int, int],
        colorscheme: str,
        parameters: dict[str, Any],
    ) -> Invocation:
        argv = [
            self.binary,
            "-o",
            str(output),
            f"--backend={BACKEND}",
            "--render",
            f"--camera={camera.as_argument()}",
            f"--imgsize={imgsize[0]},{imgsize[1]}",
            f"--colorscheme={colorscheme}",
            "--projection=perspective",
        ]
        for argument in parameter_arguments(parameters):
            argv += ["-D", argument]
        argv.append(str(source))
        return self._run(argv, output)

    def export_mesh(self, source: Path, output: Path, *, parameters: dict[str, Any]) -> Invocation:
        argv = [self.binary, "-o", str(output), "--export-format=binstl", f"--backend={BACKEND}"]
        for argument in parameter_arguments(parameters):
            argv += ["-D", argument]
        argv.append(str(source))
        return self._run(argv, output)
