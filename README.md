# openscad-models

Parametric OpenSCAD models for 3D printing. Organized by system, designed to be opened directly in OpenSCAD or used as build targets with the [openscad-toolkit](https://github.com/zing3d-labs/openscad-toolkit) compiler.

## Setup

Clone with submodules:

```bash
git clone --recurse-submodules https://github.com/zing3d-labs/openscad-models.git
```

Or if already cloned:

```bash
git submodule update --init --recursive
```

## Structure

```
opengrid/         # openGrid modular mounting system
  parts/          # Individual parametric components
  kits/           # Multi-part assemblies
external/
  BOSL2/              # BOSL2 OpenSCAD library (BelfrySCAD)
  QuackWorks/         # QuackWorks connector modules (pinned to a fork — see ARCHITECTURE.md)
  opengrid-projects/  # openConnect connector library (mitufy)
```

## Using the Models

Open any `.scad` file directly in OpenSCAD. Each part file renders a preview by default and exposes parameters via the built-in Customizer.

See [ARCHITECTURE.md](ARCHITECTURE.md) for design conventions.

## License

[CC BY-NC-SA 4.0](LICENSE)

Models in this repository build on third-party libraries under their own terms. In particular, the openConnect connector library in `external/opengrid-projects/lib/` is by [mitufy](https://github.com/mitufy/opengrid-projects) under CC BY 4.0, and openGrid is by David D. Parts that mount via openConnect must credit both. Note that mitufy's holder, drawer, shelf, hook, label, and gadget *generators* are CC BY-SA 4.0 — deriving geometry from those would impose ShareAlike terms that conflict with this repository's license, so depend on the connector library only.
