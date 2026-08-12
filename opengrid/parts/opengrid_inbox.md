# opengrid_inbox.scad

A wall-mounted paper, envelope, and file inbox that hangs on an openGrid wall using openConnect slots cut into its back panel. The pocket is a wedge — a tall back panel flat against the wall, a shorter front panel raked outward so sheets lean back and stay readable, closed at the sides by tapering panels, with a finger cutout in the front edge so a stack can be grabbed. Panels can optionally be perforated with a hex honeycomb or a square lattice. The module is BOSL2-attachable.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `paperWidth` | float | 215.9 | Sheet width in mm; sets the interior width |
| `paperHeight` | float | 279.4 | Sheet height in mm; sets both panel heights via the percentages below |
| `paperClearance` | float | 3 | Extra interior width beyond the sheet, total across both sides; a lower bound when width snapping is on |
| `pocketDepth` | float | 25 | Interior depth at the floor — the stack capacity |
| `rakeAngle` | float | 12 | Outward lean of the front panel, degrees from vertical |
| `backHeightPercent` | float | 50 | Back panel height as a percentage of `paperHeight` |
| `frontHeightPercent` | float | 30 | Front panel height as a percentage of `paperHeight`; must be shorter than the back panel |
| `wallThickness` | float | 2.4 | Thickness of the front and side panels |
| `backThickness` | float | 4 | Thickness of the back panel; must contain the openConnect slots |
| `floorThickness` | float | 2.4 | Thickness of the pocket floor |
| `fingerCutoutStyle` | string | `"Scallop"` | Grab cutout shape: `"Scallop"`, `"Notch"`, or `"None"` |
| `fingerCutoutWidth` | float | 70 | Width of the grab cutout |
| `fingerCutoutDepth` | float | 22 | How far the cutout reaches down from the front panel top edge |
| `perforationPattern` | string | `"None"` | Pattern cut through the panels: `"None"`, `"Hex"`, or `"Square"` |
| `perforationCellSize` | float | 12 | One cell across the flats (hex) or on a side (square) |
| `perforationWallThickness` | float | 2 | Material left between neighbouring cells |
| `perforationBorder` | float | 8 | Solid margin around every perforated area |
| `perforateBack` | bool | false | Perforate the back panel |
| `perforateFront` | bool | true | Perforate the raked front panel |
| `perforateSides` | bool | true | Perforate the tapering side panels |
| `snapWidthToGrid` | bool | true | Round the outer width up to a whole 28mm tile |
| `snapHeightToGrid` | bool | true | Round the back panel height to the nearest whole 28mm tile |
| `mountHorizontalGrids` | int | 0 | Slot columns; `0` fits as many whole tiles as the width allows |
| `mountVerticalGrids` | int | 0 | Slot rows; `0` fits as many whole tiles as the height allows |
| `mountVerticalAlignment` | string | `"Center"` | Where the grid sits in the leftover height: `"Center"`, `"Top"`, `"Bottom"` |
| `slotPosition` | string | `"All"` | Which grid positions get a slot |
| `slotLockDistribution` | string | `"Corners"` | Which slots get the locking nub |
| `slotLockSide` | string | `"Left"` | Side the nubs sit on, as seen from the wall side |
| `slotEntryRampFlip` | bool | false | Flip the slot entry ramp for side-on printing |
| `anchor`, `orient`, `spin` | — | — | Standard BOSL2 attachment parameters |

## Sizing

The sheet drives everything. `paperWidth` sets the interior width; both panel heights are percentages of `paperHeight`. The `Paper_Size` Customizer preset (A4 / US Letter / A5 / Custom) sets the pair, and `Paper_Orientation` swaps them — presets are stated portrait, so Landscape gives a wide, short pocket for sheets on their side.

Panel dimensions are then snapped to the 28mm openConnect tile so the slot grid reaches the panel edges with nothing left over:

- **Width rounds up.** Rounding to nearest could shrink the pocket and pinch the sheet, so the surplus becomes extra clearance instead. This makes `paperClearance` a *lower bound* — raising it past a tile boundary adds a full 28mm of width in one step. Watch the echoed clearance figure.
- **Height rounds to nearest**, since nothing constrains it.

Both can be turned off with `snapWidthToGrid` / `snapHeightToGrid`, which gives exact percentage-derived dimensions and a grid that leaves a partial tile unused.

At the defaults — US Letter portrait, 50% back, 30% front — that is a 224 × 49.3 × 140mm part with a full 8 × 5 tile grid, a 219.2mm pocket (3.3mm clearance), and 195.6mm of the sheet visible above the front panel. The rendered part echoes all of this.

## Perforation

`perforationPattern` cuts a hex honeycomb or a square lattice through the panel faces. It defaults to `"None"`, which leaves the part solid and byte-for-byte identical to what it rendered before perforation existed. `perforationCellSize` sets the cell — measured across the flats for hex, on a side for square — and `perforationWallThickness` the material left between neighbouring cells.

Each panel is switched independently. The front and sides default on; **the back defaults off**, because the back plate is what carries the mount. Where the back *is* perforated, the openConnect slot grid keeps a solid keep-out around it, so every slot retains its continuous backing wall. With grid snapping on (the default) the slot grid covers the back panel edge to edge and that keep-out leaves no perforatable area at all — turning `perforateBack` on then cuts nothing, and the model echoes a note saying so. To open up area outside the grid, lower `mountHorizontalGrids` / `mountVerticalGrids` or turn the snapping off.

### The border is structural

`perforationBorder` is not a cosmetic frame. Perforating to the very edge weakens a panel exactly where the mount and the corners take load, so the border is measured not only from each panel's outer edges but from **every joint the panel makes** — the pocket floor, the neighbouring panels, the finger cutout, and the slot grid. No hole lands on a corner or a seam.

Setting it to `0` is allowed and removes that protection.

If the border swallows a panel entirely, that panel simply comes out solid rather than erroring.

### Cell fragments

Masking a cell field inevitably slices some cells at a shallow angle — most visibly along the side panels' diagonal taper. The fragments left behind can be far too narrow to print, so the pattern is opened (eroded, then dilated by the same amount) to delete any hole narrower than `perforationWallThickness`. That threshold is the pattern's own minimum gap, so nothing in the part ends up thinner than the design already asks for. Cells clear of the mask survive with their corners rounded to that radius, which prints better than a sharp one.

At the defaults — US Letter portrait, hex, 12mm cells, 2mm walls, 8mm border, front and sides only — this removes about 17% of the part's material. The square lattice at the same settings removes roughly the same.

## Orientation

The model is built as-mounted: **+Y points at the wall**, so the back panel's outer face lies in the plane `Y = 0` and the pocket hangs out toward −Y. +Z is up.

Slots are cut into the wall-facing face, sliding **up** — the part drops down onto the openConnect connectors, so gravity holds it in place.

## Named anchors

| Anchor | Location |
|--------|----------|
| `wall` | Centre of the mounting face, the plane that meets the openGrid wall |
| `back_top` | Centre of the back panel's top edge |
| `pocket_floor` | Centre of the pocket floor's top surface |
| `front_top` | Centre of the front panel's top edge |

```scad
include <BOSL2/std.scad>
use <opengrid_inbox.scad>

openGridInbox() {
  attach("front_top", BOTTOM) myLabelHolder();
}
```

Note that `use <>` imports modules only. A consumer must `include <BOSL2/std.scad>` itself, since `attachable()` needs BOSL2 in scope.

## Printing

Print with the back panel flat on the bed, slots facing up. The raked front panel and the tapering sides then need support only under the front panel's overhang; set `slotEntryRampFlip` if you instead print the part on its side.

`backThickness` must be at least 3.5mm — the openConnect slot is 2.7mm deep and the model asserts a 0.8mm solid backing wall behind it.

In that orientation the front panel is the overhang, so perforating it cuts down the area needing support as well as the material. Pick a `perforationWallThickness` that is a whole number of extrusion widths — the 2mm default is five passes of a 0.4mm nozzle — otherwise the walls between cells come out as a line and a sliver of gap fill.

## Licensing

The pocket geometry is original work under the repository license, CC BY-NC-SA 4.0. The openConnect mount comes from mitufy's connector library (`external/opengrid-projects/lib/openconnect_lib.scad`), CC BY 4.0 — attribution only.

This part deliberately depends on the **connector library only**. mitufy's holder, drawer, shelf, hook, label, and gadget generators are CC BY-SA 4.0; deriving from one of those would impose ShareAlike terms that conflict with this repository's license. Credit openGrid (David D) and openConnect (mitufy) as remixed sources on any published listing.
