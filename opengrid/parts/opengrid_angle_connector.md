# opengrid_angle_connector.scad: design notes

A load-bearing part that holds an object at a set tilt off an openGrid board. It
slides onto openConnect connectors screwed into the board, and the object slides
onto a second face that stands at the chosen angle. The driving case is tenting a
split keyboard (a Charybdis-style pair, trackball on the right half) on an openGrid
desk tray, replacing quarter-arch tents that use bespoke connectors. It is meant to
work as a general part beyond that one use.

**Status: working draft.** The geometry renders, mates, and passes the checks below.
It has not been printed. Anything marked *open* still needs a decision.

---

## Decisions

### Settled

| Question | Decision |
|---|---|
| Object-face interface | **Printed openConnect studs** by default, so the object only needs slots. Slots and snaps are also offered as settings. |
| Angle axes | **One tilt axis for now**, organised so a toe-in and a front/back roll drop in later (see *The angle mechanism*). |
| Body shape priority | **Flexibility.** Offer several bodies rather than pick one. Five are in the draft. |
| Scope of this draft | Design doc plus a working prototype part. |
| Board-side interface | openConnect slots (the board carries connectors), or snaps, both drawn by `openGridMountBase()`. Slots are not reimplemented. |
| Generic, not keyboard-specific | The part is a general angle connector. The keyboard tent is the motivating case, not a target: there is no keyboard tilt, footprint or case layout to design for, and the defaults are generic. |
| Object-face layout | A generic grid (`Object_Units_X/Y` and a placement pattern) by default, with an explicit list of stud positions as an override for objects whose slots are off the 28mm pitch. *Not built yet.* |
| Holding the slide | The openConnect lock nubs alone. No stop and no latch. |
| Toe-in and roll | Not in the Customizer for now. `toeAngle` and `rollAngle` stay module-only, so they can be exposed later without reworking the pose. |
| Cable pass-through | None on the closed bodies. Ribbed's open back is the cable route. |
| Arch past the board | Kept. At shallow tilts Arch reaches past the board's far edge; the part warns when it does. |
| Studs come from the mount base | The object plate is an `openGridMountBase()` with `mountType = "openConnect Studs"`, the same base its slot and snap options use. Studs go exactly where the slotted base would cut slots, so the object's slots and these studs follow one set of placement rules. |
| Shaping | **The part reads as one object.** The side outline is rounded, the back wall stands plumb from the board's far edge with the face's top as a short eave over it, and the Truss is a Warren with a joint behind each row of studs and rounded openings. Each is a setting, and the old look is one setting each away. See *Shaping*. |
| Scope vs. the arbitrary-angle beam bracket ([#5](https://github.com/zing3d-labs/openscad-models/issues/5)) | A separate part, built for strength under typing load. The overlap is noted below and not shipped here. |

### Made in the draft, to review

These were judgment calls made to get a working part. Each one is a parameter, so changing a default is cheap.

1. **Both slides default to "Left", along the hinge.** Gravity has no component
   along the hinge, so it can neither seat nor unseat either joint, and the lock
   nubs hold position. Sliding down the slope would let gravity seat the object,
   but that axis cannot be printed on side (point 2). Up or down the slope is still
   one setting away.
2. **The default print orientation is On Side.** Layers then lie in the plane the
   tilt happens in, which is the plane typing load bends the part in. That is the
   strong orientation for a tent. It also prints both faces as vertical walls.
3. **The default body is Truss, as a Warren.** It prints on side with no support
   inside, weighs about two thirds of Solid, and is triangulated against the racking
   a tall tent sees.
4. **Handedness.** With one tilt axis, the right-hand part is the left-hand part
   turned 180°, so one print serves both halves. `Handedness = Right` still builds the
   true mirror image, so both halves can slide the same way in the world. That is
   also the path toe-in will need.
5. **Default placement.** The face's low edge sits directly above the board plate's
   trailing edge (`Low_Edge_Offset = 0`), and `Low_Edge_Height = 0` picks the least
   height that keeps the object plate clear of the board plate. See *Placing the
   face* for moving it.
6. **Default sizes:** board 4×2 units, object face 4×3 units, 5mm plates, 4mm
   walls and webs, 45° tilt, studs on the corners. These are generic defaults, not sized for any one object.

---

## Parameters

Customizer names; the module takes the same in camelCase.

| Parameter | Range / values | Default | Notes |
|---|---|---|---|
| `Tilt_Angle` | 0–90° | 45 | Measured off the board plane. 0 is a flat spacer, 90 is upright. |
| `Low_Edge_Height` | mm ≥ 0, 0 = auto | 0 | Height of the face's low edge above the board surface. Auto is `Board_Thickness + Object_Thickness·cos(tilt)`. |
| `Low_Edge_Offset` | mm, any sign | 0 | How far the low edge is set across the hinge from the board's trailing edge (the edge the face rises away from). Positive moves it the way the face rises; it may be negative or run past the far edge. |
| `Face_Offset_X` | mm | 0 | Slides the face along the hinge relative to the board's centre. |
| `Low_Edge_Clearance` | mm ≥ 0 | 10 | How far below the low edge, down the slope, the space in front of the face is kept clear for an overhanging object. |
| `Board_Units_X/Y` | 1–12 | 4 / 2 | Board-plate footprint in 28mm units. |
| `Board_Thickness` | ≥ 3.5 for openConnect | 5 | |
| `Board_Mount_Type` | openConnect, Snaps | openConnect | |
| `Board_Slide_Direction` | Left, Right, Up, Down | Left | The way the part slides to come off the board. |
| `Board_Slot_Position` / `_Lock_Distribution` / `_Lock_Side` | as `opengrid_mount_base` | All / All / Left | Passed straight through to the base. |
| `Grid_Type`, `Snap_Placement` | as `opengrid_mount_base` | Lite / Corners | Applies to snaps on either face. |
| `Object_Units_X/Y` | 1–12 | 4 / 3 | Object-face size in 28mm units. |
| `Object_Thickness` | ≥ 3.5 for slots | 5 | |
| `Object_Mount_Type` | Studs, Slots, Snaps | Studs | |
| `Object_Slide_Direction` | Left, Right, Up, Down | Left | The way the *object* slides to come off. Up means up the slope. |
| `Object_Mount_Position` | All, Staggered, Edge Rows, Edge Columns, Corners | Corners | Which grid positions carry a stud or slot. |
| `Body_Shape` | Solid, Tube, Truss, Arch, Ribbed | Truss | See *Body shapes*. |
| `Wall_Thickness` | mm | 4 | Shell and web thickness for Tube, Truss and Arch. Close to the plates' 5mm, so every member of the profile reads as one weight. |
| `Truss_Bays` | 1–8 | 3 | Pratt only; a Warren places its own joints. |
| `End_Walls` | bool | false | Closes the ends of Tube, Truss and Arch. |
| `Rib_Count`, `Rib_Thickness` | 2–12, mm | 3, 4 | Ribbed only. |
| `Profile_Rounding` | mm ≥ 0 | 2 | Radius on every outside corner of the side profile. Held under half the thinner plate. See *Shaping*. |
| `Back_Wall` | Plumb, Hull | Plumb | Plumb stands the back wall up from the board's far edge, with the face's top as an eave over it (up to half a tile). Hull runs it straight to the face's high edge. |
| `Truss_Style` | Warren, Pratt | Warren | Warren: diagonals only, a joint behind each row of the face's grid. Pratt: an upright and a diagonal per bay. |
| `Truss_Fillet` | mm ≥ 0 | 2 | Radius on the corners of the Truss's openings. |
| `Handedness` | Left, Right | Left | |
| `Print_Orientation` | On Side, As Mounted | On Side | |

These module-only parameters are kept out of the Customizer until printed: `toeAngle` and `rollAngle` (see below).

---

## Placing the face

The face is placed by its **low edge**: its height above the board surface
(`Low_Edge_Height`), how far it is set across the hinge from the board's trailing
edge (`Low_Edge_Offset`), and how far the face is slid along the hinge
(`Face_Offset_X`). The board (`Board_Units_X/Y`) and the face (`Object_Units_X/Y`)
are sized independently. A 3×3 board carrying a 5×3 face with its low edge 20mm up
and 80mm across works:

```
Board_Units_X = 3; Board_Units_Y = 3;
Object_Units_X = 5; Object_Units_Y = 3;
Low_Edge_Height = 20; Low_Edge_Offset = 80;
```

**Which side the mount goes on.** Always the side of the tilted plate that faces
*away* from the board, so the body lives on the board's side of the plate and the
object never shares its space. There is no override:

- **Upper side:** the face leans back over the board. This is the default
  placement, and the tent case.
- **Lower side:** the face is set out past the board like a bracket arm, as in
  the example above. The object hangs on the plate's outside.

The side is decided by which side of the face's plane the board plate's top
centre falls on. Turning the plate
over is a half-turn about its own up-slope axis, never a mirror, so studs stay
true openConnect heads. Slide names stay in the part's own axes: "Left" is still
−X whichever way the plate faces.

`Low_Edge_Height = 0` picks the least height that keeps the plate and its mount
clear of the board plate and above the board surface, for whichever side and
placement is in force. It works from the plate's real outline rather than a
formula that assumed the upper side. It then raises the face in 0.5mm steps
until no part of the board is where the object goes. A face set out over the
board's far edge needs that second step: in the example above with the height
left to the part, it picks 9.3mm.

**What the body is allowed to fill.** Between the plates, everything except two
zones:

- **The object plate and the space in front of it**, from its low end up. This
  keeps the body out of its slots.
- **The space in front of the face plane**, reaching `Low_Edge_Clearance` below
  the low edge. This is room for an object that overhangs the face's low edge.

Further below that, the body may reach in front of the face plane. That is how a
face set out over the board gets buttressed from the board side. Directly behind
the face plane, below the low edge, the body takes hold of the plate's lower end.
`Low_Edge_Clearance = 0` buttresses right up to the low edge.

**Sanity checks.** The part refuses a placement where:

- the object plate, or its studs, slots or snaps, would run into the board plate;
- the face would reach below the board surface;
- the board plate would sit in front of the face, where the object goes;
- the Arch's springing point is not over the board. An Arch needs its corner on
  the board, so use Truss, Tube or Solid for a face set far out.

It warns when:

- the board plate leaves an object less room below the low edge than
  `Low_Edge_Clearance` asks for;
- the body stands on less than one tile (28mm) of the board's depth;
- the face and board overlap by less than one tile along the hinge;
- the face reaches more than 10mm past the board's edge as a cantilever (a note);
- an Arch reaches more than 10mm past the board's far edge.

The geometric checks apply to the single-axis pose. With toe or roll set, only
the hinge-overlap warning runs.

## Body shapes

Volumes are at the defaults (45°, board 4×2, face 4×3, 4mm walls, shaped). Volume
is the solid model, plates included. A slicer's infill makes the real filament use lower
and keeps the same order.

| Shape | What it is | Volume | Prints on side | Notes |
|---|---|---|---|---|
| **Solid** | Hull of the two plates | 226 cm³ | yes | Stiffest and simplest. Most material. Also works for any compound pose. |
| **Tube** | Triangular shell: board plate, object plate, back wall | 95 cm³ | yes | Lightest closed section; the plates are its other two walls. Good in torsion. The back wall is a long unbraced panel. |
| **Truss** *(default)* | Tube braced by webs: a Warren by default, or a Pratt | 151 cm³ | yes | Triangulated, so the back wall and the face are braced. A good mid-point. |
| **Arch** | Quarter-ellipse shell from the board's far edge to the face's top edge | 108 cm³ | yes | Closest to today's tents. At shallow tilts it bulges past the board's +Y edge (by 27mm at 45°), because an arch has to reach the face's top. |
| **Ribbed** | Gussets across the hinge, back left open | 88 cm³ | **no**, print As Mounted | About as light as Tube. The open back is good for cables. On side, its inner ribs become shelves with a free edge (13× the steep overhang of the others, measured). |

Trade-offs for the keyboard:

- **For a steep tent (60–90°), Truss or Tube.** The load is typing force pushing
  the face toward the board, which racks the profile. A closed, triangulated
  section resists that best for the plastic it uses.
- **Choose Arch if it should look like today's tents.** It is fine structurally,
  but it reaches past the board footprint at shallow angles.
- **Ribbed only makes sense printed upright,** where its gussets stand
  vertical. Printed that way, the board-face slots face the bed as a normal
  base does, but the object face is tilted, and so are its studs.

---

## Shaping

The first draft drew the part as three things stacked: a board plate, an object
plate and a body between them, each with its own sharp edges. Renders across the
options showed what that costs:

- **Slabs, not an object.** The board plate stuck out past the face's low edge
  as a stepped lip, the object plate's thickness showed as a separate band, and
  every corner was sharp.
- **A back wall that leaned out.** It ran straight from the face's high edge to
  the board's far edge, so when the face was longer than the board reached, the
  top hung out past the footprint. That reads as about to tip, and the back is
  the side seen most in use.
- **An irregular truss.** Bays of uneven width, a tiny first bay, joints that
  did not line up with the studs, and 5mm chords against 3mm webs.

Three settings answer those, all on by default:

- **`Profile_Rounding` (2mm).** The side outline - board plate, body and object
  plate together - is opened by the radius, which rounds every outside corner,
  and then closed again so two rounded corners a step apart do not leave a
  groove. The body also fills the notch between the object plate's square-cut
  low end and the board's leading edge, so the front runs as one line from the
  board up to the face. That notch is behind the face plane, clear of the
  object. The rounding is an intersection, so it only ever takes material
  away, and it never takes any from:
  - anything in front of the face (studs, snaps), or a studded face between
    its rounded ends;
  - a slotted or snapped face's front edge, since a slot's cutter comes within
    0.8mm of the plate edge and a snap's footprint within 1.2mm;
  - the board plate from its underside up through the slots and their floor.
  It is held under half the thinner plate, which would otherwise be eroded
  away, and says so when it is.
- **`Back_Wall = Plumb`.** Where the face's top reaches past the board's far
  edge, the back wall stands straight up from that edge and the face's top
  overhangs it as an eave, up to half a tile. A wall square to something reads
  as intended; the old in-between lean read as accidental. Plumb also carries
  the load straight down onto the board. Beyond half a tile the eave is a
  cantilever, so the wall leans out as before. A face whose top stays over the
  board is unchanged: its back wall already leans in.
- **`Truss_Style = Warren`, `Truss_Fillet` (2mm).** Diagonals only, zigzagging
  between joints on the object plate and joints on the board. The plate's joints
  sit behind the rows of the face's grid, so a stud's load goes straight into
  one. Rows where the body is less than three walls deep are skipped, and the
  rest thinned to about one per tile of board depth, so a steep face does not
  pack a web per row into a narrow profile. The board's joints fall between them
  in proportion along the board, which spreads the zigzag over the whole profile
  at any tilt. An end diagonal that would run almost alongside the wall it meets
  is left out, so no sliver opening is left between them. The openings' corners
  are rounded, which also takes the stress concentrations out of them.

Printed on side, all three lie in the layer plane: the rounding, the eave and the
openings add no overhang.

Two limits. A face set out past the board leaves a profile of another shape -
the chords no longer meet near the board's leading edge - so it gets a Pratt
with sharp openings, and says so. A proper bracket shape for that placement is
follow-up work. And the shelves left beside a face narrower than the board are
not addressed yet.

---

## The angle mechanism

Everything on the tilted face is drawn once, in the face's own frame: the face in
local Z = 0, outward +Z, local +X along the hinge, local +Y up the slope. A single
matrix, `angleConnectorObjectPose(tilt, lift, hingeY, objectDepth, toe, roll)`,
places that frame:

```
move([0, hingeY, lift]) * zrot(toe) * xrot(tilt) * yrot(roll) * back(objectDepth / 2)
```

- The **plates and studs** go through the pose, so they follow any pose.
- **Solid and Ribbed** are hulls of the two plates, so they follow any pose too.
  Measured: tilt 40°, toe 10°, roll −8° renders as one body for both.
- **Tube, Truss and Arch** are drawn from a 2D side profile, which only exists
  for a single axis. They assert when toe or roll is nonzero.

**Adding toe-in or roll later** means exposing `toeAngle` and `rollAngle` in the
Customizer, then deciding how the profile bodies should behave. Two options:
build their webs as hulls between plate slices (works for any pose), or keep them
single-axis. Handedness already uses the conjugated pose `M·P·M` with M a
reflection across Y. That is a proper rotation, so studs and slots placed through
it are re-placed, not mirrored. A compound-angle left and right pair needs exactly
that.

### Overlap with the arbitrary-angle beam bracket ([#5](https://github.com/zing3d-labs/openscad-models/issues/5))

A beam bracket at an arbitrary angle is the same mechanism: two faces with an
openGrid mount each, at an angle about a shared edge. It differs in two places:
the body is a narrow web instead of a load-bearing tube, and both faces carry
snaps or the beam's own interface. What it would share:

- `angleConnectorObjectPose()`, which hangs a face off another at an angle.
- The "plate either end" pattern: `openGridMountBase()` on the reference face,
  and the same base turned over by `xrot(180)` (a rotation, never a mirror) on
  the angled face.
- The direction and lock-side remapping (`angleConnectorYFlipDirection`,
  `angleConnectorYFlipLockSide`).

**Proposal:** when #5 is picked up, move those three into a small shared file
(`opengrid/parts/opengrid_angle_lib.scad` or similar). The bracket and this part
then both `use` it, so there is one copy rather than two. Nothing is moved now,
because one consumer does not justify a library.

---

## Printing

Printed **On Side**, the part stands on its +X or −X end. The end is chosen from
`Object_Slide_Direction` so that every stud's **flat front** (the face of the head
toward the slot's mouth) faces the bed.

Measured layer by layer for one stud standing off a vertical wall, counting
anything more than 45° out from the layer beneath as unsupported:

| Stud laid with | Unsupported | Where |
|---|---|---|
| Flat front down *(chosen)* | One layer, 2.4mm × 17mm | A ledge straight off the wall, on the face that mates with nothing |
| Flat front up | ~9 mm²-layers over 1.6mm of height | The flange and a lock notch: the parts that hold |
| Slide up or down the slope | ~6 mm²-layers over 1.6mm | The flange |

The flat-front-down layout therefore has the largest overhang area, but all of it
is one short ledge on a non-functional face. The other layouts droop the flange
that engages the slot's lip. With both slides along the hinge, the board's slot
mouths face the bed as well. *Open:* how well an openConnect slot cut into a
vertical wall prints has not been tested. The base has `Slot_Entry_Ramp_Flip` for
side-printing, and it is not exposed here yet.

**Plates of different widths.** On side, the part is built up along the hinge,
so wherever the face is wider than the board, slid along it, or narrower than it,
one plate's end starts partway up the print. That end used to start in mid-air:
the whole-part check (every 1mm layer, anything more than 45° past the layer
beneath counts) found 253mm² unsupported at the board plate's end on a face slid
40mm. The set-out example had 383mm², and the upright bracket arm 132mm². Two
changes fix it, for Tube, Truss and Arch:

- Along any stretch of the hinge that one plate does not reach, the body keeps a
  wall of its own where that plate would be: a floor past the board's ends, a
  face-side wall past the face's.
- Each plate end that falls partway along the body gets a 45° wedge that leans
  into that wall, so the end grows out of it a layer at a time. The board plate's
  wedges stand outside its footprint and above the board surface. The face
  plate's stay behind the face, out of the object's way.

After the fix the same check finds nothing at those transitions beyond strips
under 1mm wide (0.9mm × 16mm on the bracket arm), which print as ordinary
overhangs. What remains on every layout is the studs' own 2.4mm ledges. Solid and
Ribbed need neither change: they are hulls that taper from one plate's span to
the other's.

---

## Verification done

All checks render with Manifold, using `--render` and never a preview. Every
check has a control that has to come out non-empty, so a pass is evidence.

- **Studs fit a real slot.** `openGridMountStud(d)` differenced against
  `openGridMountSlotCutter(d)` is empty for all four directions and both lock
  sides. Controls: a mirrored head leaves 90 facets in the nub, and an
  unturned head leaves 8.5mm³ of flange in the slot's lip. Before the base's
  lock-nub fix (#31), the Right lock side under slides Down and Right left
  0.126mm³ per slot. That case now comes out empty too.
- **Moving onto the base's stud mode changed nothing.** The object plate was
  first built with its own stud placement. It is now an `openGridMountBase()`
  with `mountType = "openConnect Studs"`. The part built each way, differenced
  both ways, is empty for both hands × all four slide directions; for the All,
  Staggered (4×3 and 5×3), Edge Rows and Edge Columns placements; for the
  lower-side example in both hands; for tilts of 0, 20, 70 and 90; for slots,
  snaps and the on-side layout. Controls: Corners against All leaves
  2938mm³, and slide Left against Right 926mm³ each way. The object-face
  mate checks below therefore carry over unchanged.
- **Object face mates.** Intersect the part with a stand-in keyboard plate: an
  `openGridMountBase()` with slots, placed through the same pose. The result is
  empty for both hands, all four slide directions, all five bodies, and tilts of
  0, 20, 45, 70 and 90. Control: the same plate without slots gives 4392mm³,
  which is 12 studs' worth. It is also empty for:
  - a 3×3 board with a 5×3 face set 20mm up and 80mm across, for Solid, Tube,
    Truss and Ribbed, in both hands (control: 5472mm³, 15 studs);
  - the face slid 40mm along the hinge;
  - the low edge set 30mm in front of the board;
  - the example with the mount on the lower side, with studs in all four slide
    directions and with slots. Control: the studs it meets lie at Y = 43–95mm,
    all past the board's far edge at 42mm;
  - a face set out past the board at 30°, 60° and 90°, and leaning back over
    it at the same angles.
- **Object slots take connector heads.** Empty for both hands and all four
  directions.
- **Board face mates.** Connector heads at every tile give an empty
  intersection, for every body and tilt tested, and for the placements above.
  Control: heads shifted 0.4mm into the lip give 389mm³ (438mm³, 9 heads, on
  the 3×3 board).
- **Body never fills a slot.** The body is kept out of the board plate and out
  of the object plate's zone. The mate checks above are what prove it.
- **Every sanity check fires.** Each error and warning was triggered by a
  placement built for it, and the defaults trigger none.
- **Shaping takes nothing that mates.** Each check builds the part with and
  without `Profile_Rounding` and measures where the two differ, both ways. The
  difference is empty in front of the face; between a studded face's rounded
  ends, behind its face; through a slotted face's slot depth (3mm, or the whole
  3.5mm plate on thin plates); and in the board plate's lowest 3.5mm, which
  holds its slots and their floor. That holds for studs at 20, 45, 70 and 90°,
  snaps, slots on 5mm and on 3.5mm plates, Tube, and the lifted face. (The
  slotted cases leave a 0.001mm³ sheet across the whole face, a coplanar seam
  below the noise floor, and still measure one body.) Controls: the same
  difference over the whole object plate is 125–1494mm³, and over the whole
  board plate 4–328mm³. The first version trimmed 99mm³ from the snaps' rims,
  which reach inside the rounding; snap faces now keep their edge square.
  The body material the shaping adds - the Warren webs, the filled low-end
  notch - is cut back by the same zones as the rest of the body, which keep it
  out of both plates' mounts and the object's space, so the mate checks above
  carry over.
- **One body.** All 121 cases in `opengrid_angle_connector.tests.yaml` measure
  one body, except where `End_Walls` closes a Tube, Truss or Arch: each sealed
  hollow then reports as a shell of its own. The Truss's openings are rounded
  once for the whole length, then trimmed to each stretch of the hinge. Rounded
  stretch by stretch, a face narrower than the board closed its first opening
  beside the face and sealed the rest of it as a void inside the body, which
  measured as a second body.

  A flat spacer (tilt 0) has its plates sitting straight on each other. Where a
  Tube or Truss hollow left that contact with nothing overlapping it, the union
  kept a zero-volume sheet between the plates and the part measured two bodies.
  A 0.2mm slab across their shared footprint, inside
  both plates, now joins them, and the volume is unchanged.

---

## Open questions

None.

## Follow-up work proposed

- **An explicit stud-position list** for the object face, overriding the grid.
- **A bracket shape for a face set out past the board:** a curved knee brace from
  the board to the face's underside, in place of a truss of long thin triangles,
  with a minimum angle in the profile.
- **A body no wider than a narrow face**, or tapered to it, so no shelves are
  left beside it.
- **The Arch as a cove** that curves in under the face and stays on the board,
  rather than bulging out past it.
- **A test print** of the default part, plus a slot coupon printed on its side,
  to settle the open printing question.
- **Toe and roll in the Customizer**, which also means Tube, Truss and Arch must
  follow a compound pose.
- **The shared angle library**, when #5 is picked up.
