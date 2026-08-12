# Architecture

## Parts vs Kits

### Part

A parametric OpenSCAD module file. A part file:

- Contains a `module foo(param1, param2, ...)` with all configuration exposed in its signature
- Has Customizer-compatible variables at the top — the *curated public interface*, a deliberate subset of what the module accepts
- Has a top-level render call, placed after the Customizer variables and before the module definition (e.g., `dualSidedSnap(...);`), so the file renders as a preview in OpenSCAD and can be used as a build target directly. The call wires the Customizer variables to the module's named parameters, which is why it reads best directly below them — OpenSCAD hoists module definitions, so the module it calls may be defined further down the file.

### Kit

Only exists when genuinely combining multiple parts into a multi-part assembly. The `grid_basket` is a real kit — it assembles beams, connectors, and panels. A single-part product like the dual-sided snap is **not** a kit; the part file is the build target directly.

## Directory Structure

```
{system}/
  parts/      # Individual parametric components
  kits/       # Multi-part assemblies (only when genuinely multi-part)
```

Each top-level folder represents an independent system (e.g., `opengrid/`). This allows future systems to coexist without restructuring.

## File Naming

Part files keep their system prefix (e.g., `opengrid_beam.scad`) so they are self-documenting when opened in isolation or imported by a kit.

## Module API

The **module signature is the public API** of a part. All configuration a consumer might need must be exposed as named parameters with sensible defaults. Customizer variables are a curated subset of those parameters for the end-user UI — they are not the API.

Because `use <file.scad>` imports only module and function definitions (not variables), Customizer variable names are strictly file-local. There is no requirement that variable names match across files. A kit that imports a part calls its module with explicit named arguments:

```openscad
use <../../parts/opengrid_beam.scad>
opengrid_beam(lengthUnits=4, tileThickness=tileThickness, corner1="Extended");
```

The local variable `tileThickness` in the kit file is unrelated to any variable inside `opengrid_beam.scad`.

## Measurement Conventions

All named measurements (offsets, distances, thicknesses) must be defined as positive values. Apply a minus sign at the call site when a negative coordinate is needed. If a value must be stored as negative for a specific reason, document why inline.

## External Libraries

`external/` is shared across all systems. BOSL2, QuackWorks, and opengrid-projects (mitufy's openConnect connector library) are referenced via git submodules. Files use relative paths to import from `external/`.

External libraries carry their own licenses, and some are more restrictive than others. Before depending on a new external file, check its license against the repository license and record the conclusion in the part's file header — see `opengrid/parts/opengrid_inbox.scad` for the pattern.

### Why QuackWorks points at a fork

QuackWorks is pinned to [jhuizingh/QuackWorks](https://github.com/jhuizingh/QuackWorks), not to [upstream](https://github.com/AndyLevesque/QuackWorks), because it carries two openGrid snap fixes that upstream does not have yet:

- **Lite snap connectivity** — increases the click hole bridge thickness so lite snaps stay connected.
- **Nub overlap** — overlaps the nub geometry with the core body so snaps do not split into separate bodies in slicers.

Both touch `openGrid/opengrid-snap.scad`, which `opengrid_facade.scad` and `opengrid_dual_sided_snap.scad` depend on. They are proposed upstream in [PR #127](https://github.com/AndyLevesque/QuackWorks/pull/127) and remain unmerged.

The pin tracks the `zing3d-integration` branch, which exists to give those commits a stable home. It is deliberately *not* the PR branch `fix/lite-snap-click-hole-bridge`: a PR branch can be deleted on merge, rebased, or force-pushed, any of which would orphan the pinned commit and break the submodule. `zing3d-integration` is only ever moved on purpose.

The branch is upstream's `main` plus those two commits. When upstream moves, rebase `zing3d-integration` onto it and bump the pin here. Upstream has been dormant — three commits in the nine months to 2026-08 — so this is rare. If the fixes land upstream, the fork and this note can go away.

## Future

A validation script or CI check to enforce these conventions (module definition, Customizer variables, top-level render call) is a planned but not yet implemented enhancement.
