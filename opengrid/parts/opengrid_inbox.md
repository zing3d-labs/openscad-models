# opengrid_inbox.scad

A wall-mounted paper, envelope, and file inbox that hangs on an openGrid wall using openConnect slots cut into its back panel. The pocket is a wedge — a tall back panel flat against the wall, a shorter front panel raked outward so sheets lean back and stay readable, closed at the sides by tapering panels, with a finger cutout in the front edge so a stack can be grabbed. The module is BOSL2-attachable.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `paperWidth` | float | 215.9 | Sheet width in mm; sets the interior width |
| `paperHeight` | float | 279.4 | Sheet height in mm; only feeds the echoed summary |
| `paperClearance` | float | 4 | Extra interior width beyond the sheet, total across both sides |
| `pocketDepth` | float | 25 | Interior depth at the floor — the stack capacity |
| `rakeAngle` | float | 12 | Outward lean of the front panel, degrees from vertical |
| `backHeight` | float | 140 | Height of the back panel in mm |
| `frontHeight` | float | 84 | Height of the front panel in mm; must be shorter than `backHeight` |
| `cornerRounding` | float | 3 | Rounding on the front and side panel silhouettes |
| `wallThickness` | float | 2.4 | Thickness of the front and side panels |
| `backThickness` | float | 4 | Thickness of the back panel; must contain the openConnect slots |
| `floorThickness` | float | 2.4 | Thickness of the pocket floor |
| `fingerCutoutStyle` | string | `"Scallop"` | Grab cutout shape: `"Scallop"`, `"Notch"`, or `"None"` |
| `fingerCutoutWidth` | float | 70 | Width of the grab cutout |
| `fingerCutoutDepth` | float | 22 | How far the cutout reaches down from the front panel top edge |
| `mountHorizontalGrids` | int | 0 | Slot columns; `0` fits as many whole tiles as the width allows |
| `mountVerticalGrids` | int | 0 | Slot rows; `0` fits as many whole tiles as the height allows |
| `mountVerticalAlignment` | string | `"Center"` | Where the grid sits in the leftover height: `"Center"`, `"Top"`, `"Bottom"` |
| `slotPosition` | string | `"All"` | Which grid positions get a slot |
| `slotLockDistribution` | string | `"Corners"` | Which slots get the locking nub |
| `slotLockSide` | string | `"Left"` | Side the nubs sit on, as seen from the wall side |
| `slotEntryRampFlip` | bool | false | Flip the slot entry ramp for side-on printing |
| `anchor`, `orient`, `spin` | — | — | Standard BOSL2 attachment parameters |

## Sizing

`paperWidth` drives the interior width; `backHeight` and `frontHeight` are absolute millimetres, so a paper-size change never silently resizes the pocket. The `Paper_Size` Customizer preset (A4 / US Letter / A5 / Custom) only sets `paperWidth` and `paperHeight`.

A `backHeight` that is a multiple of 28 uses the openConnect grid exactly, with no leftover. The defaults — US Letter, 140mm back — give an 8 × 5 tile grid on a 224.7 × 49.3 × 140mm part, leaving 195mm of a Letter sheet visible above the front panel. The rendered part echoes this summary.

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

## Licensing

The pocket geometry is original work under the repository license, CC BY-NC-SA 4.0. The openConnect mount comes from mitufy's connector library (`external/opengrid-projects/lib/openconnect_lib.scad`), CC BY 4.0 — attribution only.

This part deliberately depends on the **connector library only**. mitufy's holder, drawer, shelf, hook, label, and gadget generators are CC BY-SA 4.0; deriving from one of those would impose ShareAlike terms that conflict with this repository's license. Credit openGrid (David D) and openConnect (mitufy) as remixed sources on any published listing.
