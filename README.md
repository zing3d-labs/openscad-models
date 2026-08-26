# openscad-models

Parametric OpenSCAD models for 3D printing. Organized by system, designed to be opened directly in OpenSCAD or used as build targets with the [openscad-toolkit](https://github.com/zing3d-labs/openscad-toolkit) compiler.

## Setup

Clone, then pull the submodules in:

```bash
git clone https://github.com/zing3d-labs/openscad-models.git
cd openscad-models
git submodule update --init
```

## Structure

```
opengrid/         # openGrid modular mounting system
  parts/          # Individual parametric components, each with an optional
                  #   <part>.tests.yaml declaring its visual feature tests
  kits/           # Multi-part assemblies
external/
  BOSL2/              # BOSL2 OpenSCAD library (BelfrySCAD)
  QuackWorks/         # QuackWorks connector modules (AndyLevesque)
  opengrid-projects/  # openConnect connector library (mitufy)
tools/
  visual_tests/       # The renderer and comparison tooling used by CI
docs/
```

## Using the Models

Open any `.scad` file directly in OpenSCAD. Each part file renders a preview by default and exposes parameters via the built-in Customizer.

See [ARCHITECTURE.md](ARCHITECTURE.md) for design conventions.

## Changing a Model

Pull requests that touch a `.scad` file get an automatic before/after
comparison: the affected parts are rendered on both sides of the change and any
visual or geometric difference is posted to the pull request. It is advisory —
it reports what moved, it never fails a pull request.

A part's feature tests live in `<part>.tests.yaml` beside it. If you add or
change a feature, add or change its test.
[docs/visual-regression-tests.md](docs/visual-regression-tests.md) explains the
format.

## License

[CC BY-NC-SA 4.0](LICENSE)

Models in this repository build on third-party libraries under their own terms. In particular, the openConnect connector library in `external/opengrid-projects/lib/` is by [mitufy](https://github.com/mitufy/opengrid-projects) under CC BY 4.0, and openGrid is by David D. Parts that mount via openConnect must credit both. Note that mitufy's holder, drawer, shelf, hook, label, and gadget *generators* are CC BY-SA 4.0 — deriving geometry from those would impose ShareAlike terms that conflict with this repository's license, so depend on the connector library only.
