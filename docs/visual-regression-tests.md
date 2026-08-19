# Visual regression tests

Every model in this repository is parametric, which means a small edit to a
shared module can quietly change the shape of something several files away. The
visual regression check renders the affected models on both sides of a pull
request and reports what moved — a picture of the difference, plus numbers for
the parameter combinations that are not pictured.

Think of these as **unit tests for geometry, organised by feature**. A test
case is not "the cup holder"; it is "handle slots", with the camera angle that
shows handle slots and the parameter combinations that prove they work.

The check is **advisory**. Most model changes are supposed to change the render,
so a difference is reported, never punished: the check does not go red because
geometry moved.

## What runs on a pull request

1. **Selection.** Every part's transitive `include`/`use` graph is walked and
   intersected with the files the pull request changes, measured against the
   **merge base** rather than the tip of `main`. `opengrid_cupholder.scad` does
   `use <opengrid_facade.scad>`, so a facade change re-renders the cup holder
   too. A submodule pin bump matches any part whose dependencies reach into
   that submodule.
2. **A determinism canary.** One case is rendered twice from the same commit
   and the two results must be identical. See [Why comparison is
   exact](#why-comparison-is-exact).
3. **Numbers on every case.** Bounding box, volume, connected body count and
   triangle count, taken from an exported mesh.
4. **Pictures on the designated cases.** Before, after, and an amplified diff.
5. **A pull request comment**, one per part, updated in place on each push.
   It shows the features that changed and collapses the ones that did not.
   Full-resolution images are also attached to the run as an artifact.

## Adding a feature test

Specs live beside the part they test: `opengrid/parts/<part>.tests.yaml` next to
`<part>.scad`. They are sidecars rather than one central file so that a pull
request touching a model shows the model and its tests in the same diff.

```yaml
version: 1
part: opengrid_cupholder.scad
description: What this part is.

defaults:
  imgsize: [900, 700]
  colorscheme: Tomorrow Night
  camera:
    eye: [330, -330, -10]      # where the camera sits
    center: [0, 0, -50]        # what it looks at
  parameters:
    Smoothing: 40              # applied to every case

features:
  handle_slots:
    label: Handle slots
    description: One sentence on what this feature is.
    camera:                    # overrides defaults.camera for this feature
      eye: [150, -420, 30]
      center: [0, 0, -55]
    parameters:                # applied to every case in this feature
      Handle_Slot_Start_Angle: 270
    matrix:                    # cartesian product; measured, not pictured
      Handle_Slot_Count: [0, 1, 2, 3, 4, 6, 8]
    cases:                     # explicit cases; these may ask to be pictured
      - params: {Handle_Slot_Count: 3}
        render: true
      - name: wide-slot
        params: {Handle_Slot_Count: 2, Handle_Slot_Width: 60}
        render: true
```

### The two axes

Numbers are cheap and pictures are not, so a feature declares both:

- **`matrix`** sweeps a parameter space. Every combination is *measured*.
- **`cases`** names individual combinations. These are measured too, and the
  ones with `render: true` are additionally *pictured* from the feature's
  camera.

A `cases` entry whose parameters match a `matrix` combination replaces it, so
asking for a render inside a swept space does not duplicate the case.

### Field reference

| Key | Where | Meaning |
| --- | --- | --- |
| `version` | top level | Must be `1`. |
| `part` | top level | The `.scad` beside this file. Defaults to the matching name. |
| `defaults.camera` | top level | `eye` and `center`, both `[x, y, z]` in model units. |
| `defaults.imgsize` | top level | `[width, height]` in pixels. Default `[1000, 750]`. |
| `defaults.colorscheme` | top level | Any OpenSCAD colour scheme. Default `Tomorrow Night`. |
| `defaults.parameters` | top level | Applied under every case. |
| `label` | feature | Human name, used as the heading in the comment. |
| `camera`, `imgsize`, `colorscheme` | feature | Override the defaults. |
| `parameters` | feature | Applied under every case in this feature. |
| `matrix` | feature | Mapping of variable to list of values. Measured only. |
| `cases[].params` | feature | Parameters for one case, over the feature's. |
| `cases[].name` | feature | Optional. Derived from the parameters otherwise. |
| `cases[].render` | feature | `true` to picture this case. Default `false`. |

### Choosing a camera

Pick the angle that makes the feature obvious, not the angle that shows the
whole part. A 5 mm corner fillet is a handful of pixels from across the plate
and unmistakable from 60 mm away. It helps to fix a parameter in the feature's
`parameters` block so the feature always faces the camera — the handle slot
tests set `Handle_Slot_Start_Angle: 270` for exactly that reason.

To find coordinates, render by hand and adjust:

```bash
OPENSCADPATH=$PWD/external openscad \
  -o /tmp/probe.png --backend=Manifold --render \
  --imgsize=900,700 --camera=150,-420,30,0,0,-55 \
  --colorscheme="Tomorrow Night" --projection=perspective \
  -D Smoothing=40 -D Handle_Slot_Count=3 \
  opengrid/parts/opengrid_cupholder.scad
```

The six `--camera` values are `eye` then `center`, in that order.

### Keeping the cost down

Renders dominate the run. Turn `Smoothing` down in `defaults.parameters` — both
sides of the comparison use the same value, so nothing is lost — sweep broadly
in `matrix` where it is only arithmetic, and reserve `render: true` for the
cases a reviewer would actually want to look at.

## When a part changes and has no spec

A model that changes is meant to carry the feature test that covers it, and a
pull request that adds or changes a feature should add or change that feature's
test. A part affected by a change but carrying no `.tests.yaml` is therefore
**not** a silent pass: it is called out in the run's job summary, listed by
name.

It does not fail the check today. Whether it should is deliberately a separate
question, to be answered once there is real evidence of how noisy the check is
in practice.

## Why comparison is exact

Two renders are compared pixel for pixel. Any differing pixel marks the case
changed. There is no threshold to tune and no perceptual metric.

That is only safe because **both sides are rendered by the same binary in the
same job**. Projects that compare a render against a committed baseline have to
fuzzy-match, because the baseline was produced by a different machine on a
different day. Here a toolchain change moves before and after together and
cancels out.

The assumption underneath is that an identical commit renders identically. The
canary is what keeps that honest: it renders one case twice and asserts the
results match. Unlike a geometry difference, **a failed canary does fail the
check** — it means the comparison itself is unsound, and a quiet failure would
show up as every case changing on every run.

Mesh *bytes* are never compared. Identical solids routinely export in a
different triangle order, so a mesh hash says nothing. Triangle count is
reported for the same reason but marked informational; bounding box, volume and
connected body count are the measurements worth acting on. Body count is the
most valuable of the four — it is what catches a solid that has silently come
apart into pieces.

Numeric tolerances are relative to the model's own bounding box diagonal rather
than absolute, because a parametric repository renders the same part at wildly
different scales.

## Running it locally

```bash
python3 -m venv .venv && .venv/bin/pip install -r tools/visual_tests/requirements.txt

# Check every spec parses.
.venv/bin/python -m tools.visual_tests validate

# Which parts would this branch re-render?
.venv/bin/python -m tools.visual_tests select --base origin/main

# Is rendering deterministic on this machine?
.venv/bin/python -m tools.visual_tests canary \
  --part opengrid/parts/opengrid_cupholder.scad --out /tmp/vr

# Compare against another checkout of the same repository.
git worktree add --detach /tmp/base origin/main
git -C /tmp/base submodule update --init
.venv/bin/python -m tools.visual_tests run \
  --part opengrid/parts/opengrid_cupholder.scad \
  --base-root /tmp/base --out /tmp/vr/opengrid_cupholder

# Turn the result into the Markdown the comment is built from.
.venv/bin/python -m tools.visual_tests report \
  --result /tmp/vr/opengrid_cupholder/result.json --out /tmp/vr/comment.md
```

`OPENSCAD` selects the binary if `openscad` is not on `PATH`. Note that
`git submodule update` is deliberately **not** `--recursive`: QuackWorks carries
a gitlink it does not declare in its own `.gitmodules`, and recursing into it
fails.

## The OpenSCAD pin

`.github/openscad-pin.env` names the snapshot CI renders with, and its SHA-256.

It is a dated development snapshot, not a numbered release: the last numbered
stable is 2021.01, which predates both the Manifold backend and headless EGL
rendering. Manifold is pinned as well — CGAL and Manifold disagree on facet
count and on the low-order bits of a bounding box for an identical model, so the
backend is part of the measurement.

To bump it, pick a snapshot from <https://files.openscad.org/snapshots/>, put
its date in `OPENSCAD_SNAPSHOT`, and copy the checksum from the matching
`.sha256` file. Snapshots are eventually removed from that server; when the
pinned one disappears the install step fails with a message saying so.

## Where the images live

GitHub strips `data:` URIs out of comment bodies and serves workflow artifacts
as authenticated zips, so neither can be shown inline. Images are pushed to an
orphan `ci-renders` branch in this repository and linked from the comment over
`raw.githubusercontent.com`.

That branch is rewritten as a single root commit on every run, so its history
never grows, and directories for pull requests untouched for 90 days are swept
up. Nothing on it is source; it can be deleted at any time and the next run will
recreate it.

## Prior art

The sidecar format was drawn up against
[looooo/freecad.visual_tests](https://github.com/looooo/freecad.visual_tests),
which is the closest existing shape: a per-project `metafile.yaml` declaring a
model, a set of views with per-view cameras, and per-view overrides of the
project defaults. Borrowed from it: the explicit `version`, the
defaults-plus-overrides layout, and naming each entry with both a key and a
human `label`.

Where this format differs is that it is organised by **feature** rather than by
view, and that a feature carries two axes — the parameter space to measure and
the subset to picture. That falls out of these models being parametric: there is
no single "the model" to photograph from three angles, there is a feature that
has to keep working across a range of settings.

The rest of the design follows
[shaiss/print-bench](https://github.com/shaiss/print-bench), which does the same
merge-base checkout, same-binary comparison and sticky marker comment for
numeric geometry rather than pixels;
[reg-viz/reg-actions](https://github.com/reg-viz/reg-actions) for the orphan
branch image hosting and the comment size guard; and Blender's image regression
suite for amplifying the diff image rather than leaving it nearly black.

## Pull requests from forks

A workflow triggered by a pull request from a fork gets a read-only token, so it
cannot push images or post a comment. Those runs still render everything and
still run the numeric checks: the full report goes to the run's job summary and
every image is in the uploaded artifact.

`pull_request_target` is **not** used, and must not be. This workflow executes
code from the pull request — the contributor's `.scad` files and their
`.tests.yaml` — and combining that with a write token is the classic
pwn-request vulnerability. Bringing inline images to fork pull requests needs
the `pull_request` + `workflow_run` split, which is tracked separately.
