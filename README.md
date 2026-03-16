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
  BOSL2/          # BOSL2 OpenSCAD library (BelfrySCAD)
  QuackWorks/     # QuackWorks connector modules
```

## Using the Models

Open any `.scad` file directly in OpenSCAD. Each part file renders a preview by default and exposes parameters via the built-in Customizer.

See [ARCHITECTURE.md](ARCHITECTURE.md) for design conventions.

## License

[CC BY-NC-SA 4.0](LICENSE)
