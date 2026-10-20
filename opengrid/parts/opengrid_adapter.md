# opengrid_adapter.scad

A plate that mounts to openGrid on its back and carries another system's connectors on its front, so a part made for that system hangs on an openGrid wall. The driving case is a part built for Multiboard — Multiconnect slots on a 25mm pitch — moved onto openGrid, which is 28mm: openConnect slots on the back, Multiconnect studs on the front.

The back is [`opengrid_mount_base.scad`](opengrid_mount_base.scad), so it offers what the mount base offers: openConnect slots, openConnect studs or openGrid snaps, with the same slot options.

## Two grids, one outline

25 and 28 never line up, so neither face is laid out from the other. Each face counts in its own units — the back in 28mm openGrid tiles, the front in the front system's cells — and the plate is the smallest rectangle that holds both footprints.

A count of **0 is Auto**: as many as fit. Give the side you care about and leave the other on Auto.

| Front | Back | Plate |
|---|---|---|
| 3×3 Multiconnect | Auto | 75×75mm, 2×2 openConnect slots |
| 1×1 Multiconnect | Auto | 28×28mm, 1 slot — a slot is wider than one 25mm cell, so the plate grows to a whole tile |
| 1×3 Multiconnect (a hook) | Auto | 28×75mm, 1×2 slots |
| Auto | 3×3 | 84×84mm, 3×3 Multiconnect studs |
| Auto | Auto (same axis) | refused — neither side says how big the plate is |

Each axis is settled on its own, so an Auto back across and an Auto front down is a valid plate. An Auto face never has fewer than one connector.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `backMountType` | string | `"openConnect"` | `"openConnect"` (slots), `"openConnect Studs"` or `"Snaps"` |
| `backUnitsX`, `backUnitsY` | int | 0 | Back grid in 28mm units; 0 = Auto |
| `slotSlideDirection`, `slotPosition`, `slotLockDistribution`, `slotLockSide`, `slotEntryRampFlip` | — | as the mount base | Back openConnect options, passed to the mount base |
| `liteSnap`, `snapPlacement` | — | `true`, `"Corners"` | Back snap options |
| `frontMountType` | string | `"Multiconnect Studs"` | `"Multiconnect Studs"`, `"Multiconnect Slots"`, `"openConnect Studs"`, `"openGrid Snaps"` or `"None"` |
| `frontColumns`, `frontRows` | int | 3, 3 | Front cells; 0 = Auto |
| `frontPosition` | string | `"All"` | `All`, `Staggered`, `Edge Rows`, `Edge Columns`, `Corners`. Multiconnect slots run a whole line of cells, so for them it picks lines |
| `frontPitch` | float | 0 | Front cell pitch in mm; 0 = the system's own (25 for Multiconnect). openGrid types are always 28 |
| `frontSlideDirection` | string | `"Up"` | Way the hung part slides to come **off**, for Multiconnect slots and openConnect studs |
| `headPattern` | string | `"Dimple"` | Face of a Multiconnect stud: `Dimple`, `Coin Slot` or `None` |
| `frontLiteSnap` | bool | `true` | Front snaps Lite (3.4mm) or Full (6.8mm) |
| `frontAlignX` | string | `"Center"` | `Center`, `Left`, `Right` — lines the front's edge up with the back's |
| `frontAlignY` | string | `"Center"` | `Center`, `Top`, `Bottom` |
| `frontOffset` | [x, y] | `[0, 0]` | Moves the front on from its alignment, in mm |
| `width`, `height` | float | 0 | Plate size in mm; 0 = the smallest that holds both faces. Smaller than either face is refused, naming the face |
| `thickness` | float | 4 | Slab thickness. Raised, with a message, when slots cut into both faces need more |
| `cornerRefinementType`, `cornerRefinementSize` | — | `"None"`, 2 | As the mount base; costs back slots near the corners |
| `anchor`, `orient`, `spin` | — | — | Standard BOSL2 attachment parameters |

## Frame

Built board side **down**, like the mount base: the front is the top face. With the back sliding `"Up"`, +Y is up the wall and +X is to the right seen from the front. All direction names are those axes.

## Front connectors

- **Multiconnect Studs** — the Multiconnect head, flange outermost, for a Multiconnect part's slots to slide over. Checked against a QuackWorks three-slot Multiconnect back: every stud sits inside the slots with nothing left over.
- **Multiconnect Slots** — channels cut into the front for a part carrying Multiconnect heads. The cross-section, closed end, on-ramps and v2 snap ridges match QuackWorks' `multiConnectSlotTool()`. The heads are on the hung part here, so the closed end is at the end the part slides away from: on a wall, at the bottom.
- **openConnect Studs** — the mount base's `openGridMountStud()` on the 28mm grid, for a part with openConnect slots.
- **openGrid Snaps** — QuackWorks' openGrid snap, Full or Lite.
- **None** — a plain plate.

## Published functions and modules

| Name | What |
|---|---|
| `openGridAdapterMulticonnectHead(headPattern)` | A Multiconnect head as `multiconnect_head(anchor=BOTTOM)` draws it, flange down |
| `openGridAdapterMulticonnectStud(headPattern)` | That head turned to stand flange-up off a face at Z = 0 |
| `openGridAdapterMulticonnectSlot(length, pitch)` | One Multiconnect channel cut down into a face at Z = 0, closed end at the origin, running along +Y |
| `openGridAdapterMulticonnectPitch()`, `openGridAdapterMulticonnectHeadHeight()`, `openGridAdapterMulticonnectSlotDepth()` | 25, 4 and 4.15mm |
