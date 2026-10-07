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
3. **The default body is Truss.** It prints on side with no support inside, weighs
   a little over half of Solid, and is triangulated against the racking a tall tent sees.
4. **Handedness.** With one tilt axis, the right-hand part is the left-hand part
   turned 180°, so one print serves both halves. `Handedness = Right` still builds the
   true mirror image, so both halves can slide the same way in the world. That is
   also the path toe-in will need.
5. **Default placement.** The face's low edge sits directly above the board plate's
   trailing edge (`Low_Edge_Offset = 0`), and `Low_Edge_Height = 0` picks the least
   height that keeps the object plate clear of the board plate. See *Placing the
   face* for moving it.
6. **Default sizes:** board 4×2 units, object face 4×3 units, 5mm plates, 45° tilt,
   studs on the corners. These are placeholders until the keyboard case is measured
   (*open*, below).

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
| `Wall_Thickness` | mm | 3 | Shell and web thickness for Tube, Truss and Arch. |
| `Truss_Bays` | 1–8 | 3 | |
| `End_Walls` | bool | false | Closes the ends of Tube, Truss and Arch. |
| `Rib_Count`, `Rib_Thickness` | 2–12, mm | 3, 4 | Ribbed only. |
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
- the face reaches more than 10mm past the board's edge as a cantilever (a note).

The geometric checks apply to the single-axis pose. With toe or roll set, only
the hinge-overlap warning runs.

## Body shapes

All renders below are at the defaults (45°, board 4×2, face 4×3). Volume is the
solid model, plates included. A slicer's infill makes the real filament use lower
and keeps the same order.

| Shape | What it is | Volume | Prints on side | Notes |
|---|---|---|---|---|
| **Solid** | Hull of the two plates | 247 cm³ | yes | Stiffest and simplest. Most material. Also works for any compound pose. |
| **Tube** | Triangular shell: board plate, object plate, back wall | 92 cm³ | yes | Lightest closed section; the plates are its other two walls. Good in torsion. The back wall is a long unbraced panel. |
| **Truss** *(default)* | Tube with a web upright and diagonal per bay | 135 cm³ | yes | Triangulated, so the back wall and the face are braced. A good mid-point. |
| **Arch** | Quarter-ellipse shell from the board's far edge to the face's top edge | 99 cm³ | yes | Closest to today's tents. At shallow tilts it bulges past the board's +Y edge (by 27mm at 45°), because an arch has to reach the face's top. |
| **Ribbed** | Gussets across the hinge, back left open | 91 cm³ | **no**, print As Mounted | About as light as Tube. The open back is good for cables. On side, its inner ribs become shelves with a free edge (13× the steep overhang of the others, measured). |

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

---

## Verification done

All checks render with Manifold, using `--render` and never a preview. Every
check has a control that has to come out non-empty, so a pass is evidence.

- **Studs fit a real slot.** `openGridMountStud(d)` differenced against
  `openGridMountSlotCutter(d)` is empty for all four directions. Controls: a
  mirrored head leaves 90 facets in the nub, and an unturned head leaves
  8.5mm³ of flange in the slot's lip.
- **Object face mates.** Intersect the part with a stand-in keyboard plate: an
  `openGridMountBase()` with slots, placed through the same pose. The result is
  empty for both hands, all four slide directions, all five bodies, and tilts of
  0, 20, 45, 70 and 90. Control: the same plate without slots gives 4392mm³,
  which is 12 studs' worth. It is also empty for:
  - a 3×3 board with a 5×3 face set 20mm up and 80mm across, for Solid, Tube,
    Truss and Ribbed, in both hands (control: 5472mm³, 15 studs);
  - the face slid 40mm along the hinge;
  - the low edge set 30mm in front of the board.
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
- **One body.** All 81 cases in `opengrid_angle_connector.tests.yaml` measure
  one body. The exception is a closed Arch, which reports its sealed hollow as a
  second shell.
- **The base is unchanged.** `opengrid_mount_base`, `opengrid_block` and
  `opengrid_cupholder` measure identical volumes before and after the stud
  helper was added.

## Findings

- **The mount base's "Right" lock nub doesn't fit a true head under slides
  "Down" and "Right".** Differencing a correctly turned head against
  `openGridMountSlotCutter(dir, slotLockSide="Right")` leaves 0.126mm³ per slot
  for those two directions. The other six combinations of direction and lock
  side are empty. It is a squeeze on the detent, not a blocked slot, and it
  comes from the library reaching Down and Right by mirroring its Up slot. This
  part sidesteps it for its own object plate by always using "Left". The board
  plate passes the user's `Board_Slot_Lock_Side` through, so it inherits the
  issue whenever the side the base is asked for ends up "Right" under a Down or
  Right slide. `Handedness = Right` can produce that too, for example a board
  slide of Right with lock side Left. The defaults (slide Left, lock Left, either
  hand) are clear. Worth fixing in the base, or at least warning there.

---

## Open questions

1. **Keyboard case interface.** Where are the case's slots, and how many? The
   object face is a generic grid (`Object_Units_X/Y`, studs on Corners). Should
   it instead follow the case's real slot layout, as a list of positions? Do the
   slots need designing into the case too?
2. **Target tilt for the keyboard.** The photos suggest steep, about 60–90°.
   That sets how tall the part is, and whether the face's top edge needs its
   own support.
3. **Lock or stop.** Gravity is neutral along the hinge, so only the lock nubs
   hold the slide. Is that enough with a trackball, or should the board side
   take an `opengrid_block` stop (it exists for this) or a printed latch?
4. **Toe-in.** The halves in the photos look rotated toward each other. For the
   board face, that can come from where the parts sit on the grid, or from a toe
   angle on the part. Which?
5. **Cable pass-through.** Ribbed's open back gives a route already. Do the
   closed bodies need a hole or notch for the TRRS or USB cable?
6. **Arch footprint.** Is Arch reaching past the board at shallow tilts
   acceptable? If not, cap it at the board edge, at the cost of support under
   the face's top.

## Follow-up work proposed

- A **stud mode in `openGridMountBase()`** (`mountType = "openConnect Studs"`),
  with the same placement and fit rules as slots, circular bases included. The
  draft adds only the single-stud helper `openGridMountStud()` there, verified
  as above. Choosing stud positions is done here for rectangular grids, and that
  should move into the base.
- **A test print** of the default part, plus a slot coupon printed on its side,
  to settle the open printing question.
- **Fix or warn** about the base's Right-side nub (see *Findings*).
- **Toe and roll in the Customizer**, once question 4 is answered.
- **The shared angle library**, when #5 is picked up.
