# openGrid

Parametric components and kits for the [openGrid](https://makerworld.com/en/models/1179191-opengrid-wall-desk-mounting-framework-ecosystem) modular mounting system by David D.

openGrid uses a standardized 28mm grid with a snap connector spec that keeps accessories interchangeable across the ecosystem.

## Parts

| File | Description |
|------|-------------|
| `parts/opengrid_beam.scad` | Corner beam for building basket frames |
| `parts/opengrid_connector.scad` | Grid connector hardware |
| `parts/opengrid_dual_sided_snap.scad` | Dual-sided snap connector for mounting objects to openGrid tiles |
| `parts/opengrid_facade.scad` | Flat panel that snaps onto openGrid tiles for a finished look ([docs](parts/opengrid_facade.md)) |
| `parts/opengrid_cupholder.scad` | Cup holder that mounts to openGrid by openConnect slots or by snaps, on a square or circular base, with optional handle slots for mugs |
| `parts/opengrid_inbox.scad` | Wall-mounted paper, envelope, and file inbox with optional perforated panels, mounted via openConnect slots ([docs](parts/opengrid_inbox.md)) |

## Kits

| File | Description |
|------|-------------|
| `kits/grid_basket/grid_basket.scad` | Modular snap-together storage basket — geometry and printable plate modules |
| `kits/grid_basket/mw_grid_basket.scad` | Publishing entry point for the basket: multi-plate 3MF output ([convention](../ARCHITECTURE.md)) |
