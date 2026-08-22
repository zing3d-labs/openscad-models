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

## Publishing Entry Points (`mw_` files)

A model that has to print as several plates gets a second file beside the geometry:

```
kits/grid_basket/
  grid_basket.scad      # geometry + plate modules, plain names. A library.
  mw_grid_basket.scad   # publishing entry point. The only file with mw_ names.
```

The rule is `mw_<model>.scad is the published entry point; the bare name stays a library`.

MakerWorld's Parametric Model Maker exports one plate per top-level module named
`mw_plate_1()`, `mw_plate_2()`, … and shows `mw_assembly_view()` as a preview it leaves out of
the exported 3MF. A script that defines any `mw_plate_N()` **cannot offer STL downloads** — a
per-model product decision, not just a code change.

**Why the split is mandatory, not stylistic.** `scad-compiler` inlines local includes, so
`mw_plate_*` is contagious: any model that pulled in a library carrying those modules would
inherit them into its own compiled Customizer and silently flip to multi-plate mode, costing
*that* model its STL downloads. Publishing behavior must never live in geometry other kits
include. Splitting costs nothing at publish time, since MakerWorld receives one flat file either
way.

The `mw_` file uses `use <model.scad>`, not `include`. `use` drops the library's top-level
preview render (which would otherwise draw underneath the plates) and keeps its Customizer
variables out of the published UI, so the `mw_` file owns the curated parameter set and passes
every value down as an explicit named argument.

### The decomposition lives in the library, not the entry point

Both consumers render the same plates from the same modules:

```
local:      SCAD -> N STLs -> pack() -> N-plate 3MF   (baked at the chosen parameters)
MakerWorld: SCAD -> Customizer runs mw_plate_1..N()   -> N-plate 3MF (at the user's parameters)
```

If the plates were defined twice — once in the build config, once in `mw_plate_N()` — they would
drift, and the 3MF users download from the listing would stop matching the one uploaded as the
print profile. That is a bug only findable by downloading both and comparing. So plates are plain
modules in the library, and the `mw_` file and the build config are two thin consumers.

The `mw_` file carries a `Render_Plate` parameter (`0` = assembly preview, `1..N` = that plate) so
the build can render one STL per plate headlessly. Keep its `if`/`else` chain **inside a module**:
`scad-compiler` keeps module bodies verbatim but drops the `else` branches of a *top-level* `if`
chain, which would silently pin the published file to one branch.

Plates should fit roughly 240 x 235mm, MakerWorld's practical ceiling before auto-arrange starts
failing. The build pipeline's bed-fit check is the authority on this; do not duplicate it in the
`.scad`, and do not add a flag to bypass it.

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

## Tests

Each part may carry a sidecar `<part>.tests.yaml` beside it, declaring **feature
tests**: a named feature, the camera angle that shows it, and the parameter
combinations that prove it works. A pull request that touches a part renders
those cases on both sides of the change and reports what moved.

The organising unit is the feature rather than the part, so one part has many
tests and a change to a shared module is traced through the dependency graph to
every part it reaches. See [docs/visual-regression-tests.md](docs/visual-regression-tests.md).

## Future

A validation script or CI check to enforce the conventions above (module
definition, Customizer variables, top-level render call) is a planned but not
yet implemented enhancement. The visual regression check covers geometry, not
file structure.
