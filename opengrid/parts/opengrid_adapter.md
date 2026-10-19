# opengrid_adapter.scad

A plate that mounts to openGrid on its back and carries another system's connectors on its front, so a part made for that system hangs on an openGrid wall. The driving case is a part built for Multiboard — Multiconnect slots on a 25mm pitch — moved onto openGrid, which is 28mm: openConnect slots on the back, Multiconnect studs on the front. The front can also carry Multiboard's threaded holes or snap holes, for posts and snaps made for a Multiboard tile.

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
| `frontMountType` | string | `"Multiconnect Studs"` | `"Multiconnect Studs"`, `"Multiconnect Slots"`, `"Multiboard Large Thread Holes"`, `"Multiboard Mid Thread Holes"`, `"Multiboard Small Thread Holes"`, `"Multiboard Snap Holes"`, `"openConnect Studs"`, `"openGrid Snaps"` or `"None"` |
| `frontColumns`, `frontRows` | int | 3, 3 | Front cells; 0 = Auto |
| `frontPosition` | string | `"All"` | `All`, `Staggered`, `Edge Rows`, `Edge Columns`, `Corners`. Multiconnect slots run a whole line of cells, so for them it picks lines |
| `frontPitch` | float | 0 | Front cell pitch in mm; 0 = the system's own (25 for Multiconnect and Multiboard). openGrid types are always 28 |
| `frontSlideDirection` | string | `"Up"` | Way the hung part slides to come **off**, for Multiconnect slots and openConnect studs |
| `headPattern` | string | `"Dimple"` | Face of a Multiconnect stud: `Dimple`, `Coin Slot` or `None` |
| `threadDepth` | float | 6.4 | How deep the Multiboard threaded holes go into the plate, in mm. 6.4 is a tile's thickness |
| `snapHoleThread` | bool | `false` | Also cut the large thread into the snap holes, as a tile has it |
| `frontLiteSnap` | bool | `true` | Front snaps Lite (3.4mm) or Full (6.8mm) |
| `frontAlignX` | string | `"Center"` | `Center`, `Left`, `Right` — lines the front's edge up with the back's |
| `frontAlignY` | string | `"Center"` | `Center`, `Top`, `Bottom` |
| `frontOffset` | [x, y] | `[0, 0]` | Moves the front on from its alignment, in mm |
| `width`, `height` | float | 0 | Plate size in mm; 0 = the smallest that holds both faces. Smaller than either face is refused, naming the face |
| `thickness` | float | 4 | Slab thickness. Raised, with a message, when the cuts into the two faces need more |
| `cornerRefinementType`, `cornerRefinementSize` | — | `"None"`, 2 | As the mount base; costs back slots near the corners |
| `anchor`, `orient`, `spin` | — | — | Standard BOSL2 attachment parameters |

## Frame

Built board side **down**, like the mount base: the front is the top face. With the back sliding `"Up"`, +Y is up the wall and +X is to the right seen from the front. All direction names are those axes.

## Front connectors

- **Multiconnect Studs** — the Multiconnect head, flange outermost, for a Multiconnect part's slots to slide over. Checked against a QuackWorks three-slot Multiconnect back: every stud sits inside the slots with nothing left over.
- **Multiconnect Slots** — channels cut into the front for a part carrying Multiconnect heads. The cross-section, closed end, on-ramps and v2 snap ridges match QuackWorks' `multiConnectSlotTool()`. The heads are on the hung part here, so the closed end is at the end the part slides away from: on a wall, at the bottom.
- **Multiboard Large / Mid / Small Thread Holes** — threaded holes for a Multiconnect post or bolt with that Multiboard thread to screw into, on the 25mm grid, `threadDepth` deep. Each is the thread made 0.25mm larger across, its teeth cut back to a tip diameter, with a lead-in at the mouth. Large and small are a tile's two holes; mid is the thread that screws into a snap's centre, here as a hole of its own.
- **Multiboard Snap Holes** — a tile's large hole, so a Multiboard snap, or a part with one built in, clicks in. The adapter cuts only the hole. The octagon narrows from the face to a 21.4mm band and widens again behind it, which is what the snap's bumps catch on. `snapHoleThread` adds the large thread, so the same hole takes a large-thread post as well. Always 6.4mm deep.
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
| `openGridAdapterMultiboardThread(size)` | A Multiboard thread, `"Large"`, `"Mid"` or `"Small"`, as the bolt has it: `[major diameter, pitch, flank angle, tooth depth]` |
| `openGridAdapterMultiboardHoleDiameter(size)`, `openGridAdapterMultiboardHoleTip(size)` | A threaded hole's major diameter, and the diameter its teeth are cut back to |
| `openGridAdapterMultiboardThread(size, length, clearance)` | That thread as a solid standing up from Z = 0: a bolt that mates with the hole, or with `clearance` the hole's own thread |
| `openGridAdapterMultiboardThreadHole(size, depth)` | One threaded hole cut down into a face at Z = 0 |
| `openGridAdapterMultiboardSnapHole(thread)` | One snap hole cut down into a face at Z = 0, flats along the grid |
| `openGridAdapterMultiboardSnapHoleDepth()` | 6.4mm |
