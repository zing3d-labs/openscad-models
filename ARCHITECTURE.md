# Architecture

## Parts vs Kits

### Part

A parametric OpenSCAD module file. A part file:

- Contains a `module foo(param1, param2, ...)` with all configuration exposed in its signature
- Has Customizer-compatible variables at the top — the *curated public interface*, a deliberate subset of what the module accepts
- Has a top-level render call at the bottom (e.g., `opengrid_dual_sided_snap();`) so the file renders as a preview in OpenSCAD and can be used as a build target directly

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

## Measurement Conventions

All named measurements (offsets, distances, thicknesses) must be defined as positive values. Apply a minus sign at the call site when a negative coordinate is needed. If a value must be stored as negative for a specific reason, document why inline.

## External Libraries

`external/` is shared across all systems. BOSL2 and QuackWorks are referenced via git submodules. Files use relative paths to import from `external/`.

## Future

A validation script or CI check to enforce these conventions (module definition, Customizer variables, top-level render call) is a planned but not yet implemented enhancement.
