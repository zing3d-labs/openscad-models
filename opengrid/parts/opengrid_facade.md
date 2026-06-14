# opengrid_facade.scad

A flat panel that snaps onto openGrid tiles, useful as a mounting base for accessories or as a finished wall surface. The module is fully BOSL2-attachable, so other parts can attach to it using `attach()`.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `xUnits` | int | 4 | Width in openGrid units (28mm each) |
| `yUnits` | int | 3 | Height in openGrid units (28mm each) |
| `facadeThickness` | float | 1 | Thickness of the flat panel in mm |
| `liteSnap` | bool | false | Use Lite snaps (3.4mm) instead of Full (6.8mm) |
| `includeCornerSnaps` | bool | true | Place snaps at the four corners |
| `includeEdgeSnaps` | bool | false | Place snaps along all four edges (excluding corners) |
| `includeInternalSnaps` | bool | false | Place snaps at all interior grid positions |
| `cornerRefinementType` | string | "None" | Corner style: `"None"`, `"Chamfer"`, or `"Fillet"` |
| `cornerRefinementSize` | float | 1 | Size of the chamfer or fillet in mm |
| `topCornerDirectionalSnaps` | bool | false | Make top corner snaps directional |
| `topEdgeDirectionalSnaps` | bool | false | Make top edge snaps directional |
| `includeRemovalNotches` | bool | — | Cut notches into all four sides for prying the facade off |
| `removalNotchWidth` | float | — | Width of each notch along the side (mm) |
| `removalNotchDepth` | float | — | Depth of each notch into the panel (mm) |
| `anchor`, `orient`, `spin` | — | — | Standard BOSL2 attachment parameters |

## Snap orientation

Snaps face **away from** the flat panel (toward the grid). The panel itself is on the back, and the snaps protrude from the front face.

## Named anchors

The facade exposes named anchors so children can be positioned relative to snap locations or the back face.

### `bottom_center`

The center of the back face of the panel (opposite side from the snaps). Use this to attach accessories that hang behind the facade:

```scad
openGridFacade(xUnits=3, yUnits=3, anchor=BOTTOM) {
  attach("bottom_center", TOP)
    myPart();
}
```

### Snap anchors

Every snap position has a named anchor on the snap's top face (the tip that engages the grid). Anchors use a **0-based grid coordinate** system where `(0, 0)` is the bottom-left snap and `(xUnits-1, yUnits-1)` is the top-right snap.

Anchor name format: `snap_<gx>_<gy>`

**Example — 4×3 grid with all snaps enabled:**

```
(0,2) (1,2) (2,2) (3,2)   ← top row    (y = yUnits-1 = 2)
(0,1)       (2,1) (3,1)   ← middle row (y = 1, no snap at 1,1 unless internal enabled)
(0,0) (1,0) (2,0) (3,0)   ← bottom row (y = 0)
```

Corner snaps additionally have directional aliases:

| Alias | Grid coord |
|-------|-----------|
| `snap_bl` | `snap_0_0` |
| `snap_br` | `snap_<xUnits-1>_0` |
| `snap_tl` | `snap_0_<yUnits-1>` |
| `snap_tr` | `snap_<xUnits-1>_<yUnits-1>` |

Edge and internal snap anchors are only present when `includeEdgeSnaps` or `includeInternalSnaps` are enabled respectively.

## Example usage

### Standalone facade

```scad
openGridFacade(
  xUnits=4,
  yUnits=3,
  facadeThickness=2,
  liteSnap=true,
  includeCornerSnaps=true,
  includeEdgeSnaps=true,
  cornerRefinementType="Fillet",
  cornerRefinementSize=5,
  includeRemovalNotches=true,
  removalNotchWidth=7,
  removalNotchDepth=2,
);
```

### As a mounting base for an accessory

```scad
openGridFacade(xUnits=4, yUnits=4, facadeThickness=3, anchor=BOTTOM) {
  attach("bottom_center", TOP)
    myAccessory();
}
```

### Attaching to a specific snap position

```scad
openGridFacade(xUnits=4, yUnits=3, includeEdgeSnaps=true) {
  attach("snap_1_0", BOTTOM)   // second snap along bottom edge
    label();
}
```
