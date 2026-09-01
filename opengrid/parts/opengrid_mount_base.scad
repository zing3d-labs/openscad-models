/*
  opengrid_mount_base.scad

  The base an openGrid accessory mounts by: a slab carrying one of the two
  mounts openGrid offers, in whichever of two shapes suits the thing standing
  on it.

    openConnect - the slab is plain, and openConnect slots are cut into the
                  face that meets the board. Screw openConnect connectors into
                  the board first, then slide the part onto them. The default.
    Snaps       - openGrid snaps stand proud of that face and click into the
                  tiles directly.

  The two are alternatives rather than additions. Both claim the same tiles
  from the same face, and the snaps stand off exactly the face the openConnect
  mount needs flat against the board, so a base carrying both could not sit
  down on the board at all.

  The slab is printable on its own - a bare mounting plate is a useful thing to
  have - but it exists mainly to be built on. opengrid_block.scad is the slab
  with nothing but height added, and opengrid_cupholder.scad stands a cup on
  it.

  ---------------------------------------------------------------------------
  Frame

  The base is built the way it is used: the board-facing side is DOWN, and
  whatever stands on the base goes above it. The anchors say where things are,
  and they mean the same thing under either mount and either shape:

      BOTTOM          the outermost board-facing point. Under openConnect that
                      is the mount face itself; under snaps it is the snap
                      tips, which reach to the far side of the tile.
      "board"         the plane the board's outer surface lies in - the slab's
                      board-facing face. The same as BOTTOM under openConnect,
                      one snap thickness above it under snaps.
      TOP             the far face of the slab, which is what a part stands on.
      "mount_<i>_<j>" one grid position, on the board plane, facing DOWN.

  So a consumer writes the same two lines whichever mount it asked for, and
  nothing it stands on the base has to know which one that was:

      openGridMountBase(..., anchor=BOTTOM)
        position(TOP) myBody(anchor=BOTTOM);

  A rectangular base is attachable as a cuboid and a circular one as a
  cylinder, so RIGHT lands on the rim of a disc rather than on the corner of
  the box around it.

  This is also why thickness means what it means. It is the slab alone - the
  material that stands out from the board - and never includes the snaps, which
  go into the board rather than out from it. A snap base is therefore taller
  overall than an openConnect base of the same thickness, and still stands out
  from it by the same distance.

  ---------------------------------------------------------------------------
  Grid positions

  Mount positions are named `mount_<i>_<j>`, counting i to the right and j
  DOWNWARD - j = 0 is the row furthest in +Y. That is the library's own
  convention, and it is the one Slot_Position already speaks: "Top Corners"
  means the corners of row 0. Naming the anchors the other way round would put
  two conventions in one module.

  On a rectangular base every position is a whole tile, so every one gets an
  anchor whether or not the placement chose to put a mount there - a consumer
  may well want to attach something over a bare tile. On a circular base a
  position only appears if the disc can actually support a mount there.

  ---------------------------------------------------------------------------
  Base shape

  Rectangular is the grid-sized slab: a whole number of 28mm units on each
  side. Every tile it covers is a whole tile, so every position takes a mount
  and the only thing that can cost one is a corner refinement.

  Circular drops the slab for a disc of a given diameter, so the base carries
  no material a round body does not stand on. A disc cuts across tiles, so both
  mounts share one rule for which positions are supported:

      A grid position takes a mount when everything that mount needs of the
      base lies wholly inside the disc - and, for a slot, with a band of solid
      material still left between the cut and the rim.

  A partially covered tile is therefore not a special case: a position whose
  mount would hang over the rim is dropped, whatever fraction of the tile the
  disc covers, and nothing the mount does ever reaches the rim.

  What "everything that mount needs" comes to differs by mount, and for
  openConnect it is more than the footprint the library publishes. That
  footprint covers the slot pocket and the 2mm wall around it, but the cutter's
  lead-in ramp runs 9.4mm further toward the mouth - so the test takes the
  published footprint and the cutter's own outline together. A snap is tested
  on its full 25.58mm square, the 24.8mm core plus the click nubs standing
  proud of it, because a nub cut off at the rim is a nub that no longer clicks.

  A disc is not tied to the grid the way the slab is, so where the grid falls
  under it is a free choice, and mountAlignment makes it:

      Centered - a mount sits at the centre of the disc.
      Maximal  - the grid is offset to support as many mounts as it can.

  Either way the mounts stay 28mm apart, which is all the board asks of them.

  What Maximal counts is mounts, not whole grid units. A mount needs the disc
  under what it actually uses rather than under the whole 28mm tile, so
  counting tiles would refuse positions that are perfectly well supported: a
  disc only two whole tiles fit under can take four openConnect slots.

  Maximal really searches. It does not test only the four offsets of nought or
  half a tile in each axis, because those are not always the best. A 108mm disc
  takes seven snaps at an offset of [0, 5.5]mm and six at any of the four. A
  36mm disc takes one openConnect slot at [0, 24.75]mm where all four of them
  take none at all - which is the difference between a base that mounts and one
  that refuses to build. The sweep covers half a tile in each axis the mount
  footprint is symmetric about and a whole tile in each axis it is not, in
  MOUNT_OFFSET_STEP steps.

  Ties are settled twice over, because a lot of offsets support the same number
  of mounts and some of those are plainly worse. First by which offset leaves
  its tightest mount the most rim to spare, which takes a symmetric arrangement
  over a lopsided one holding the same number rather than parking a mount a
  tenth of a millimetre from the edge. Then by which is nearest centred, which
  stops the grid sliding for no gain.

  snapPlacement and slotPosition keep their meanings on a disc, read off the
  supported positions rather than off a rectangle: a position is on an edge row
  when it has no neighbour above or below it, on an edge column when it has
  none to either side, and a corner when both are true. On a full rectangular
  grid that picks out exactly what those options pick out there.

  A disc has no corners, so cornerRefinementType is ignored on one.

  ---------------------------------------------------------------------------
  Breaking the edges

  Two refinements, applied to different edges and answering to different
  things.

  cornerRefinementType breaks the VERTICAL corners - the four upright arrises
  where the sides meet - and on a rectangular base only, since a disc has none.
  It is the one that can cost an openConnect slot, for the reason below.

  topEdgeRefinementType breaks the horizontal edges around the TOP face, on
  either shape. That is the far side from the board, so it can never reach a
  mount and costs nothing on either. It defaults to off all the same, because
  the top of a base is usually where something else stands and a break there is
  material that thing wanted; a part whose top is a free face - a bare plate, a
  block - turns it on.

  They compose. The base is drawn with its vertical corners refined and then
  intersected with a mask that carries the top break, rather than asking one
  cuboid() for both, since a single call takes one rounding for the edge set it
  is given. A top break is clamped to the slab's thickness, where a fillet
  becomes a bullnose and a chamfer a knife edge, and to half the shorter span
  so opposite breaks cannot cross. Asking for more than that is cut back and
  reported rather than refused.

  ---------------------------------------------------------------------------
  Corner refinement and openConnect slots

  A corner fillet or chamfer eats into the ground the slot cutter runs over,
  and a slot has very little to give: on a plain rectangular base the cut
  already comes within MIN_SLOT_EDGE_WALL of the outside along every edge row,
  so a refinement of any size starts costing slots immediately.

  A slot that cannot keep that band is not simply lost. Most of the cutter's
  reach toward the mouth is the entry the connector head drops into, and the
  head will still go in through a shorter one, so such a slot is offered
  SLOT_ENTRY_TRIM off its entry and kept if that is enough. The choice is
  between two lengths and no others - whole, or short by that much - and whole
  is always tried first, because a full entry gives the most room to line the
  connector up by hand. A slot that still does not fit is dropped, and the echo
  says how many were trimmed and how many went.

  This costs a small base far more than a large one, because a refinement of a
  given size reaches a larger share of a shorter edge. A one-by-one openConnect
  base has room for a modest fillet and no more, which is why the parts that
  build on this default their refinement to suit their own size rather than
  inheriting one from here.

  ---------------------------------------------------------------------------
  Directions

  The openConnect mount takes compass-style direction names, which are the
  model's own axes seen from the standing-up side:

      +X    slotSlideDirection "Right"
      -X    slotSlideDirection "Left"
      +Y    slotSlideDirection "Up"
      -Y    slotSlideDirection "Down"

  The four names come from mitufy's connector library. They are written above
  as the axes they land on rather than as left and right from some viewpoint,
  because a base and the underside it mounts by are looked at from opposite
  sides and naming one of them would settle less than it appears to.

  The part slides the named way to come OFF the connectors, and the opposite
  way to seat. On a vertical wall gravity holds a part seated, so the usual
  choice is the one pointing up. On a horizontal board none of the four is
  uphill and nothing holds a part on but the slots' own lock nubs - see
  opengrid_block.scad, which exists for exactly that gap.

  ---------------------------------------------------------------------------
  Licensing

  The base geometry in this file is original work by zing3d-labs and is
  licensed under the repository license, CC BY-NC-SA 4.0 (see ../../LICENSE).

  The openConnect mount is generated by mitufy's connector library
  (external/opengrid-projects/lib/openconnect_lib.scad), which is licensed
  Creative Commons Attribution 4.0 International:

      openConnect / openGrid connector libraries
      Created by mitufy - https://github.com/mitufy
      https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system

  openGrid is created by David D:
      https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem

  The snap mount comes straight from QuackWorks
  (external/QuackWorks/openGrid/opengrid-snap.scad) for both shapes. QuackWorks
  is CC BY-NC-SA 4.0, the same license this repository uses, so that dependency
  carries no additional terms.

  This file deliberately depends on the CONNECTOR LIBRARY ONLY. mitufy's
  holder / drawer / shelf / hook / label / gadget generators are CC BY-SA 4.0;
  deriving from one of those would impose ShareAlike terms that conflict with
  this repository's CC BY-NC-SA 4.0 license. Do not reintroduce such a
  dependency here.
  ---------------------------------------------------------------------------
*/

// Brings in BOSL2 (via lib/opengrid_base.scad) along with the openConnect
// slot modules and the OG_/OC_ constants, so no separate BOSL2 include.
include <../../external/opengrid-projects/lib/openconnect_lib.scad>
use <../../external/QuackWorks/openGrid/opengrid-snap.scad>

/* [Base] */

// How the base attaches to the board. openConnect slides onto connectors
// screwed into the tiles; snaps click into the tiles directly. The two are
// alternatives - the options below apply only to the mount selected here.
Mount_Type = "openConnect"; // [openConnect, Snaps]

// Shape of the base. Rectangular is the grid-sized slab - a whole number of
// 28mm units on each side. Circular is a disc of a given diameter, which cuts
// across tiles and so supports only the positions it can fit a whole mount at.
Base_Shape = "Rectangular"; // [Rectangular, Circular]

// Thickness of the slab, in mm - the material that stands out from the board.
// Snaps go into the board rather than out from it, so this never includes them.
// Left open rather than ranged: the snap mount is happy with a thin slab, and
// the openConnect mount asserts its own minimum of 2.7mm of slot plus 0.8mm of
// solid floor beneath it, so it says so itself rather than the slider hiding it.
Thickness = 4;

/* [Rectangular Base] */

// openGrid units across the base, in X
Units_X = 2; // [1:1:12]

// openGrid units across the base, in Y
Units_Y = 2; // [1:1:12]

// How to adjust the vertical corners for visual appeal. On an openConnect base
// this costs slots - see the header - so it starts switched off. A disc has no
// corners, so this does nothing there.
Corner_Refinement_Type = "None"; // [None, Chamfer, Fillet]

// Measurement for the selected corner refinement, in mm
Corner_Refinement_Size = 2; // [0.5:0.5:20]

/* [Top Edge] */

// How to break the edges around the TOP face - the far side from the board.
// Corner_Refinement_Type above breaks the vertical corners; this breaks the
// horizontal edges those corners meet. Leave it off on a base something else
// stands on, since a broken top edge is material the thing standing there
// wanted; turn it on where the top is a free face, as on a block.
Top_Edge_Refinement_Type = "None"; // [None, Chamfer, Fillet]

// Measurement for the selected top edge refinement, in mm. Clamped to the
// slab's own thickness, since a break deeper than that has no material to eat.
Top_Edge_Refinement_Size = 1; // [0.5:0.5:20]

/* [Circular Base] */

// Diameter of the disc, in mm. Rectangular bases ignore this.
Diameter = 100; // [28:1:400]

// Where the 28mm mount grid falls under a circular base. Centered puts a mount
// at the centre of the disc. Maximal offsets the grid to support as many
// mounts as it can, breaking ties toward the roomiest fit and then toward
// centred. A rectangular base is its own grid, so this does nothing there.
Mount_Alignment = "Maximal"; // [Centered, Maximal]

/* [Snap Mount] */

// Version of the tile, Full (6.8mm) or Lite (3.4mm)
Grid_Type = "Lite"; // [Full,Lite]

// Which grid positions carry a snap
Snap_Placement = "Corners"; // [All, Edges, Corners]

/* [openConnect Mount] */

// Direction the part slides to come off the connectors, in the model's own
// axes: "Right" is +X, "Left" is -X, "Up" is +Y, "Down" is -Y. The part seats
// by sliding the opposite way, so point this at whichever side of the board
// has room to work.
Slot_Slide_Direction = "Up"; // [Up, Down, Left, Right]

// Which grid positions get a slot. A slot costs nothing to print, so cutting
// all of them keeps every board position usable; the connectors you actually
// screw into the board are still up to you.
Slot_Position = "All"; // [All, Staggered, Edge Rows, Edge Columns, Corners]

// Which slots get the locking nub - the detent that stops the part sliding
// back off. All, because you pick which handful of tiles to put connectors in,
// and the slots you happen to pick should be the locking ones. Thin this out
// only if the fit comes out too tight to seat by hand.
Slot_Lock_Distribution = "All"; // [All, Staggered, Corners, Top Corners, Bottom Corners, None]

// Side of the slot the locking nubs sit on. The slot turns with
// Slot_Slide_Direction and this side turns with it, so it is worth naming the
// axes: with a slide of "Up" or "Down", "Left" puts the nubs on the -X side
// and "Right" on the +X side; with a slide of "Left" or "Right", "Left" puts
// them on the -Y side and "Right" on the +Y side.
Slot_Lock_Side = "Left"; // [Left, Right]

// Flip the slot entry ramp, which changes which way its overhangs face
Slot_Entry_Ramp_Flip = false;

/* [Misc] */

// Value of $fn for curves on the design
Smoothing = 40; // [10:10:300]

/* [Hidden] */

// Solid material kept under the deepest point of an openConnect slot, so the
// base keeps a continuous floor.
MIN_BASE_WALL = 0.8;

// Solid material kept between an openConnect slot cut and the outside of the
// base, all the way round it. The same 0.8mm as MIN_BASE_WALL above, and
// deliberately a constant of its own rather than that one reused: MIN_BASE_WALL
// is the floor UNDER a slot and feeds the thickness assert, this is the band
// BESIDE it and decides which slots get cut at all. The two answer to different
// things - one to how stiff the base has to be, the other to how thin a wall
// the printer will hold - so moving either should not silently move the other.
//
// 0.8 is also not a number picked out of the air: it is the wall the library
// already leaves on its own. A slot cutter stops at y = -13.2 in its own 28mm
// tile, which is 0.8mm short of the tile edge at the mouth end. That is what
// lets a rectangular base with no corner refinement sit exactly at this limit
// and lose no slot, and it means raising this number costs every slot on an
// edge row - so raise it only on purpose.
MIN_SLOT_EDGE_WALL = 0.8;

// What an openGrid snap needs clear of a base whose outline does not follow
// the grid: 25.58mm square. That is openGridSnap's 24.8mm core (its own w, in
// external/QuackWorks/openGrid/opengrid-snap.scad) plus the click nubs, which
// stand 0.39mm proud of the core on each side - measured off projection() of
// openGridSnap(), and the reason the core's own width is not the number to
// use. A nub the rim cuts through is a nub that no longer clicks.
SNAP_FOOTPRINT = 25.58;

// How much is cut off the mouth end of an openConnect slot's entry - the wide
// flared end the connector head drops into - when a slot needs to be pulled
// back from the outside of the base. Nothing is trimmed unless it buys a slot
// that would otherwise be dropped, and a slot that still does not fit at this
// trim is dropped rather than trimmed further: the entry is either whole or
// short by this much, never something in between, so a base never carries three
// different slots.
//
// 3.0mm, settled by printing it rather than by measuring it. A ladder of test
// coupons at 0 to 4mm in 0.5 steps all accepted a real connector, so the limit
// is not whether the head fits but how much slop there is to get it in: at 4.0
// the head has to be aligned near perfectly across the slot, while at 3.0 it
// still drops in with the head pushed hard to one side, which is how it is
// actually seated by hand. Below 3.0 the slop grows further, which is why this
// is a ceiling and not a default - a slot that does not need it does not get
// it.
//
// The 9.4mm of entry the cutter has past its footprint is 0.8mm of
// OCSLOT_ONRAMP_CLEARANCE plus the opening the head's 10.6mm flange drops
// through, so 3.0 spends the clearance and 2.2mm of that opening. The flange's
// corners are chamfered, which is what lets it in through a shorter one.
SLOT_ENTRY_TRIM = 3.0;

// How far an entry-trim strip runs past the mouth end of the cutter it shortens.
// Only has to be more than nothing - the strip has to reach past the cutter for
// the difference to leave a clean face rather than a zero-thickness skin - and
// less than the 5.8mm of clear tile between one cutter's mouth and the back of
// the cutter in the next tile along, or a strip would shorten its neighbour too.
SLOT_TRIM_OVERRUN = 1;

// How far a trim strip reaches through the base, as a multiple of the slot
// depth. The strip is subtracted from the cutter rather than from the base, so
// it only ever has to span the cutter's own height - anything past that changes
// nothing. Stated against the slot rather than against the base thickness so
// that the strip is the same shape whatever it is cut into.
SLOT_TRIM_REACH_FACTOR = 8;

// The ground an openConnect slot cutter actually covers, which is more than the
// footprint the library publishes. That footprint is the slot pocket plus its
// 2mm wall and stops at y = -3.8; the cutter runs on to y = -13.2 for the
// lead-in ramp, and 13.004mm out to the side the ramp is offset toward.
// Neither the tile edge nor the grid edge stops the ramp - the cutter is
// already inside its own tile on every side - so nothing but this outline says
// where the cut really reaches, and a slot tested on the footprint alone can
// break out through a refined corner or a curved rim. Measured off projection()
// of openconnect_slot_grid() at one by one; re-measure if the pinned
// external/opengrid-projects moves. Stated symmetrically in x because
// Slot_Entry_Ramp_Flip mirrors the cutter, and flipping a ramp should not
// rearrange every slot on the base. The real cutter runs -13.004 to 8.6 in x,
// so this over-states it by 4.4mm on one side and is knowingly conservative:
// where a refined corner bites into just one of a pair of corner slots, both
// are treated as bitten. That is the price of a base whose slots do not move
// when a checkbox is ticked, and of a base that stays symmetric when it is -
// and since SLOT_ENTRY_TRIM usually saves such a slot rather than dropping it,
// what the conservatism costs is now a trimmed entry rather than a mount.
SLOT_CUTTER_BOUNDS = [[-13.004, -13.2], [13.004, 9]];

// Step of the circular base's Maximal offset search, in mm. The search is a
// sweep, so this is the resolution at which it can tell two offsets apart. An
// offset band narrower than this holds a mount whose footprint clears the rim
// by less than this - a fit so marginal that missing it costs nothing, which
// is what makes a sweep an honest answer to the question rather than a
// sampling of it.
MOUNT_OFFSET_STEP = 0.25;

// Step of the scan that works out what corner refinement a base COULD have
// taken, for the message when the one it was given leaves no slot. Only
// reached on the way to that error, so this is a resolution the reader of the
// message cares about rather than one any render pays for. Half a millimetre
// is the step the Customizer offers the size in. The scan's ceiling is not a
// constant: it is whatever the base itself can hold, worked out per base,
// since asking rect() for a corner wider than the rectangle is an error in
// BOSL2 rather than a shape with no slots in it.
REFINEMENT_SUGGESTION_STEP = 0.5;

openGridMountBase(
  baseShape=Base_Shape,
  xUnits=Units_X,
  yUnits=Units_Y,
  diameter=Diameter,
  mountAlignment=Mount_Alignment,
  thickness=Thickness,
  mountType=Mount_Type,
  cornerRefinementType=Corner_Refinement_Type,
  cornerRefinementSize=Corner_Refinement_Size,
  topEdgeRefinementType=Top_Edge_Refinement_Type,
  topEdgeRefinementSize=Top_Edge_Refinement_Size,
  liteSnap=(Grid_Type == "Lite"),
  snapPlacement=Snap_Placement,
  slotSlideDirection=Slot_Slide_Direction,
  slotPosition=Slot_Position,
  slotLockDistribution=Slot_Lock_Distribution,
  slotLockSide=Slot_Lock_Side,
  slotEntryRampFlip=Slot_Entry_Ramp_Flip,
  $fn=Smoothing
);

// ---------------------------------------------------------------------------
// Published measurements.
//
// `use <file>` imports modules and functions but not variables, so every
// constant a consumer needs is published as a function. The alternative is a
// second copy of the number in the consumer, which is how two files come to
// disagree about what an openConnect slot is.

// The openGrid grid pitch: 28mm. Published so a consumer can size itself to
// whole tiles without reaching into the connector library for one constant.
function openGridMountTileSize() = OG_TILE_SIZE;

// Depth an openConnect slot eats out of the base, from the board-facing face.
// 2.7mm at the library's own defaults.
function openGridMountSlotDepth() = struct_val(ocslot_cfg(), "total_height");

// Solid floor kept under a slot, and so the minimum thickness an openConnect
// base can be built at.
function openGridMountMinBaseWall() = MIN_BASE_WALL;
function openGridMountMinThickness() = openGridMountSlotDepth() + MIN_BASE_WALL;

// Band of solid material kept between a slot cut and the outside of the base.
function openGridMountMinSlotEdgeWall() = MIN_SLOT_EDGE_WALL;

// How much a slot's entry may be shortened by to save it.
function openGridMountSlotEntryTrim() = SLOT_ENTRY_TRIM;

// Square an openGrid snap needs clear on a base that does not follow the grid.
function openGridMountSnapFootprint() = SNAP_FOOTPRINT;

// Thickness of the tile a snap fills, which is how far a snap reaches below
// the board-facing face of the slab.
function openGridMountSnapThickness(liteSnap = false) = liteSnap ? 3.4 : 6.8;

// How far a part travels along its slots between seated and released: 10.6mm
// at the library's own defaults. A stop placed closer than this to the part it
// blocks cannot be slid past, which is the whole basis of opengrid_block.scad.
function openGridMountSlotReleaseTravel() = OCSLOT_MOVE_DISTANCE;

// The angle the slot cutter is turned to face a given slide direction. The
// library keeps this mapping to itself, so it is repeated here to stay in step.
function openGridMountSlotFacing(slotSlideDirection = "Up") =
  slotSlideDirection == "Left" ? 90
  : slotSlideDirection == "Right" ? -90
  : slotSlideDirection == "Down" ? 180
  : 0;

// The slot pocket plus the 2mm wall the library keeps around it - the shape
// openconnect_slot_grid() tests against limit_region.
function openGridMountSlotFootprint(slotSlideDirection = "Up") =
  zrot(openGridMountSlotFacing(slotSlideDirection), struct_val(ocslot_cfg(), "footprint"));

// The ground the cutter actually covers, lead-in ramp included - bigger than
// the footprint toward the mouth and out to the ramp side, and the only one of
// the two that can break the outside of the base. `trim` takes that much off
// the mouth end, which is what a slot short of room is offered.
//
// Both outlines turn with the slide direction, and both are convex, which is
// what lets every fit test settle a shape by its vertices alone.
function openGridMountSlotCutterOutline(slotSlideDirection = "Up", trim = 0) =
  zrot(openGridMountSlotFacing(slotSlideDirection), [
    [SLOT_CUTTER_BOUNDS[0].x, SLOT_CUTTER_BOUNDS[0].y + trim],
    [SLOT_CUTTER_BOUNDS[1].x, SLOT_CUTTER_BOUNDS[0].y + trim],
    [SLOT_CUTTER_BOUNDS[1].x, SLOT_CUTTER_BOUNDS[1].y],
    [SLOT_CUTTER_BOUNDS[0].x, SLOT_CUTTER_BOUNDS[1].y],
  ]);

// ---------------------------------------------------------------------------
// Turning the slot cutter over.
//
// A cutter that has to come out the other way up can be got there two ways,
// and they are not the same part. zflip() is a mirror: it reverses the
// cutter's handedness, and the connector head is chiral, so a mirrored cutter
// is one no real connector fits. The head's two lock detents are cut by
// different code - the left one sheared over by nub_taperin, the right one
// straight, because bridging does not print over a tapered nub - and a
// mirrored slot presents its nub to the wrong one of them. Measured against
// openconnect_head(head_type="head", add_nubs="Both"), which is the head
// openconnect_screw() actually carries: a turned cutter takes it with the
// difference empty, a mirrored one leaves 74-96 facets of the head standing in
// the nub. So the cutter is TURNED, with rot(), and never mirrored.
//
// That empty difference is exact at a slide direction of "Up". The other three
// leave the same 74-96 facets in the nub, and that is the library's own doing
// rather than the turn's: openconnect_slot_grid() used entirely on its own
// terms, with no turn of ours anywhere, leaves it for "Down", "Left" and
// "Right" too, because the library reaches those three by mirroring its "Up"
// slot. It squeezes rather than blocks - the nub is a detent, not the retainer
// - and the retaining lip this is all for comes out identical in all four. Do
// not read it as something the turn introduced.
//
// A turn is about an axis, and the axis is the one the slot slides along,
// because that is the axis the cutter is symmetric across:
//
//   - Direction names survive. A turn about the slide axis leaves the slide
//     axis alone, so "Up" still lands on +Y. Turning about the other axis
//     would reverse it, and asking the library for the opposite name instead
//     is no escape - its "Down" IS a mirror of its "Up" (verified: the two
//     differ by yflip alone), so that route arrives back at a mirrored part.
//   - Every fit test survives. The footprint and cutter outlines above are
//     symmetric across the slide direction and only across it, and a rectangle
//     and a disc are both symmetric across every axis through their centre, so
//     a turn about the slide axis leaves the outline the base fits against
//     exactly where it was. That is what lets the rectangular fit test be
//     written in the grid's frame and still answer for the base's.
//
// What the turn does reverse is the axis ACROSS the slide, so two things have
// to be handed back: the side the nubs sit on, and the row a distribution
// names.
function openGridMountSlotFlipAxis(slotSlideDirection = "Up") =
  (slotSlideDirection == "Left" || slotSlideDirection == "Right") ? RIGHT : BACK;

// The library is asked for the nubs on the far side from the one they are
// wanted on, because the turn carries them across. Both sides pair exactly
// with the head - each detent receives the nub cut by the same code - so this
// costs nothing but the swap.
function openGridMountTurnedLockSide(slotLockSide = "Left") =
  slotLockSide == "Left" ? "Right" : "Left";

// A turn about X reverses the grid's rows, so a distribution that names a row
// is asked for by the other name. Only a whole grid turned as one needs this;
// a base that turns each slot about its own centre never moves a mount.
// "Staggered" has no such handle - on an even grid the turn takes it to the
// complementary staggered set, which is the same pattern offset by a tile.
function openGridMountTurnedLockDistribution(slotSlideDirection = "Up", slotLockDistribution = "All") =
  !(slotSlideDirection == "Left" || slotSlideDirection == "Right") ? slotLockDistribution
  : slotLockDistribution == "Top Corners" ? "Bottom Corners"
  : slotLockDistribution == "Bottom Corners" ? "Top Corners"
  : slotLockDistribution;

// ---------------------------------------------------------------------------

// One openConnect slot cutter, turned to cut into a board-facing face lying in
// the local Z = 0 plane with the material above it. Subtract it from a base in
// that frame and the retaining lip is left at the mouth, which is what holds
// the part on.
//
// Published for bases this file cannot draw - an offset grid, an outline that
// is neither a rectangle nor a disc - which place their own slots one at a
// time. The two shapes this file does draw do not need it: they call it
// themselves, or let the library draw the whole grid in one call.
//
// A one-by-one grid is a single slot at the origin, and it produces geometry
// identical to a slot in the middle of a larger grid: the library clips its
// slots to the whole grid rather than to their own tiles, and a slot never
// reaches past its own tile in the first place.
module openGridMountSlotCutter(
  slotSlideDirection = "Up",
  locked = true,
  slotLockSide = "Left",
  slotEntryRampFlip = false,
  trimEntry = false
) {
  rot(180, v=openGridMountSlotFlipAxis(slotSlideDirection))
    difference() {
      openconnect_slot_grid(
        slot_type="slot",
        horizontal_grids=1,
        vertical_grids=1,
        slot_slide_direction=slotSlideDirection,
        slot_position="All",
        slot_lock_distribution=locked ? "All" : "None",
        slot_lock_side=openGridMountTurnedLockSide(slotLockSide),
        slot_entryramp_flip=slotEntryRampFlip,
        excess_thickness=EPS,
        anchor=TOP
      );
      if (trimEntry) openGridMountEntryTrimStrip(slotSlideDirection);
    }
}

// Takes SLOT_ENTRY_TRIM off the mouth end of one slot's cutter. Subtracted
// from the cutter, so it puts material BACK into the base. Written in the
// cutter's own frame, where the slide direction's facing turns the local FRONT
// onto whichever way this direction's mouth points, so one module serves all
// four.
//
// Bounded on every side rather than left as a half space, because one grid
// call draws every slot on a rectangular base and an unbounded strip would
// reach into its neighbours: OG_TILE_SIZE across covers this cutter, which
// never leaves its own tile, and stops 14mm short of the next tile's centre
// where the neighbouring cutter's nearest point is 14.996mm away. Along the
// mouth it runs from the trim line to just past the cutter's own end, well
// clear of the next tile's cutter 5.8mm further on.
module openGridMountEntryTrimStrip(slotSlideDirection = "Up", cp = [0, 0]) {
  reach = openGridMountSlotDepth() * SLOT_TRIM_REACH_FACTOR;
  translate(cp)
    zrot(openGridMountSlotFacing(slotSlideDirection))
      back(SLOT_CUTTER_BOUNDS[0].y + SLOT_ENTRY_TRIM)
        cuboid([OG_TILE_SIZE, SLOT_ENTRY_TRIM + SLOT_TRIM_OVERRUN, reach], anchor=BACK);
}

// ---------------------------------------------------------------------------

module openGridMountBase(
  baseShape = "Rectangular",
  xUnits = 2,
  yUnits = 2,
  diameter = 100,
  mountAlignment = "Maximal",
  thickness = 4,
  mountType = "openConnect",
  cornerRefinementType = "None",
  cornerRefinementSize = 2,
  topEdgeRefinementType = "None",
  topEdgeRefinementSize = 1,
  liteSnap = false,
  snapPlacement = "Corners",
  slotSlideDirection = "Up",
  slotPosition = "All",
  slotLockDistribution = "All",
  slotLockSide = "Left",
  slotEntryRampFlip = false,
  anchor,
  orient,
  spin
) {
  // $fn is deliberately not set here. It is a special variable, so it reaches
  // this module from whatever called it, which lets a consumer render its body
  // and its base at one smoothness. The top-level call above passes this
  // file's own Smoothing for the standalone render.

  circularBase = baseShape == "Circular";
  openConnectMount = mountType == "openConnect";

  x_size = circularBase ? diameter : xUnits * OG_TILE_SIZE;
  y_size = circularBase ? diameter : yUnits * OG_TILE_SIZE;

  // Snaps reach into the board rather than out from it, so they add to the
  // model's height without adding to the material that stands out from it.
  snap_thickness = openConnectMount ? 0 : openGridMountSnapThickness(liteSnap);
  total_thickness = thickness + snap_thickness;

  slot_depth = openGridMountSlotDepth();

  // The one thing both mounts and both shapes need of the base. How thin is
  // thin enough is a printing question rather than a modelling one, and is
  // left to the user - but zero is not thin, it is absent: the slab vanishes
  // and whatever stands on it meets the mount across a plane of no thickness,
  // which renders without complaint and cannot be printed at all.
  assert(thickness > 0,
    str("openGridMountBase: thickness must be greater than zero - it is ",
      thickness, "mm, which leaves no base at all."));

  assert(circularBase
      || (xUnits >= 1 && yUnits >= 1 && xUnits == floor(xUnits) && yUnits == floor(yUnits)),
    str("openGridMountBase: xUnits and yUnits must be whole numbers of 28mm grid ",
      "units, at least one each - they are ", xUnits, " and ", yUnits, "."));

  slot_footprint = openGridMountSlotFootprint(slotSlideDirection);
  slot_cutter_outline = openGridMountSlotCutterOutline(slotSlideDirection);
  slot_trimmed_cutter_outline =
    openGridMountSlotCutterOutline(slotSlideDirection, SLOT_ENTRY_TRIM);

  // -------------------------------------------------------------------------
  // Rectangular base.

  // Outline of the base, and the same outline held back by a given inset - the
  // band of material a cut has to stay behind. One function rather than a shape
  // and a separate approximation of it, because both refinements survive an
  // inset exactly: eroding a rounded corner by b leaves the same arc b smaller,
  // and eroding a 45-degree chamfer slides its face b inward along its own
  // normal, which shortens the leg by b(2 - sqrt(2)). Clamped at zero, since a
  // corner cannot be refined by a negative amount - an inset deeper than the
  // refinement simply leaves a square corner.
  function baseOutlineAt(inset, refinementSize) =
    let (refined = max(0, refinementSize -
      inset * (cornerRefinementType == "Chamfer" ? 2 - sqrt(2) : 1)))
      rect([x_size - inset * 2, y_size - inset * 2],
        rounding=(cornerRefinementType == "Fillet" ? refined : 0),
        chamfer=(cornerRefinementType == "Chamfer" ? refined : 0));

  function baseOutline(inset = 0) = baseOutlineAt(inset, cornerRefinementSize);

  base_outline = circularBase ? [] : baseOutline();
  slot_band_outline = circularBase ? [] : baseOutline(MIN_SLOT_EDGE_WALL);

  // Which slots a rectangular base will actually cut. A slot has to meet both:
  //
  //   - its footprint inside base_outline - the library's own rule, applied by
  //     openconnect_slot_grid() through limit_region, which keeps the 2mm wall
  //     the library wants around a slot;
  //   - its cutter outline inside that outline held back by MIN_SLOT_EDGE_WALL,
  //     which is what leaves a continuous band of material between the cut and
  //     the outside of the base.
  //
  // The second rule is this file's own. openconnect_slot_grid() cannot be told
  // about it - limit_region only ever tests the footprint - so the slots it
  // rejects are handed over as except_slot_pos instead, which is why the
  // positions are kept here as grid indices as well as centres.
  //
  // The footprint rule alone is not enough, and the shape of its failure is
  // worth stating: the footprint stops 9.4mm short of the cutter at the mouth
  // end, so a corner refinement can eat away exactly the ground the lead-in ramp
  // runs over while the footprint still reports the slot as fitting. At a 5mm
  // fillet on a 112mm base that left two corner slots cutting 0.8mm out through
  // the rounded corner, with no material between the cut and the outside at all.
  //
  // The test is written in the GRID's frame rather than the base's, because
  // except_slot_pos names grid indices and rectangularMountSlots() turns the
  // whole grid over afterwards. The turn is a half turn about an axis lying in
  // the base plane, and both a rectangular base outline and the deliberately
  // symmetric cutter envelope come through it unchanged, so the two frames
  // agree on which slots fit and the indices mean the same thing on either
  // side of the turn.
  function slotFitsWith(cp, cutter) =
    is_pos_shape_in_region(cp=cp, footprint=slot_footprint, limit_region=[base_outline])
      && is_pos_shape_in_region(cp=cp, footprint=cutter, limit_region=[slot_band_outline]);

  // The same test asked of a refinement this base was not built with, so a
  // failure can name the size that would have worked instead of only saying
  // the current one did not.
  function slotFitsAtRefinement(cp, refinementSize) =
    is_pos_shape_in_region(cp=cp, footprint=slot_footprint,
      limit_region=[baseOutlineAt(0, refinementSize)])
      && is_pos_shape_in_region(cp=cp, footprint=slot_trimmed_cutter_outline,
        limit_region=[baseOutlineAt(MIN_SLOT_EDGE_WALL, refinementSize)]);

  // The largest refinement of the type in force that still leaves this base a
  // slot, and the largest that leaves it every slot it asked for. A scan rather
  // than a solve: the fit test walks a polygon against a region and is not
  // something to invert. Only ever reached on the way to an error, so the cost
  // of scanning is paid by the render that was going to fail anyway.
  function slotsAtRefinement(refinementSize) =
    len([for (t = requested_slots) if (slotFitsAtRefinement(t[1], refinementSize)) 1]);

  // A corner cannot be taken off wider than half the shorter side, and the
  // band outline is already inset by MIN_SLOT_EDGE_WALL on each side, so that
  // inset rectangle is the one that sets the ceiling.
  refinement_scan_limit = (min(x_size, y_size) - 2 * MIN_SLOT_EDGE_WALL) / 2;

  function largestRefinementLeaving(atLeast) =
    let (ok = [for (c = [0 : REFINEMENT_SUGGESTION_STEP : refinement_scan_limit])
                if (slotsAtRefinement(c) >= atLeast) c])
      len(ok) == 0 ? -1 : max(ok);

  // Centre of a rectangular grid position, in the base's own frame. j counts
  // downward - j = 0 is the row furthest in +Y - which is the library's own
  // convention and the one is_grid_pos_described() reads.
  function rectPosition(i, j) =
    [-(xUnits - i * 2 - 1) * OG_TILE_SIZE / 2, (yUnits - j * 2 - 1) * OG_TILE_SIZE / 2];

  // Which rectangular grid positions carry a snap. Same vocabulary the circular
  // base reads off its supported positions, applied to a full rectangle where
  // every position is a whole tile, so the two shapes answer "Corners" the same
  // way. Every one of these sets is symmetric about the grid's middle row and
  // middle column, which is what lets the drawing below turn the whole slab
  // over without moving a snap.
  function rectSnapSelected(i, j) =
    let (edge_row = (j == 0 || j == yUnits - 1),
         edge_col = (i == 0 || i == xUnits - 1))
      snapPlacement == "All" ? true
      : snapPlacement == "Edges" ? (edge_row || edge_col)
      : (edge_row && edge_col);

  rect_snap_positions = (circularBase || openConnectMount) ? [] : [
    for (i = [0 : xUnits - 1], j = [0 : yUnits - 1])
      if (rectSnapSelected(i, j)) rectPosition(i, j)
  ];

  requested_slots = circularBase ? [] : [
    for (i = [0 : xUnits - 1], j = [0 : yUnits - 1])
      if (is_grid_pos_described(i, j, xUnits, yUnits, slotPosition))
        [[i, j], rectPosition(i, j)]
  ];

  // Every requested position lands in exactly one of three sets, in this order:
  // cut whole if the whole cutter clears the band, cut with the entry trimmed if
  // only the short one does, dropped if neither. Whole is tried first because a
  // full entry is the easier of the two to seat by hand - the trim is spent only
  // where it buys a mount.
  fitted_slots = [
    for (s = requested_slots) if (slotFitsWith(s[1], slot_trimmed_cutter_outline)) s[1]
  ];
  trimmed_slots = [
    for (s = requested_slots)
      if (!slotFitsWith(s[1], slot_cutter_outline)
        && slotFitsWith(s[1], slot_trimmed_cutter_outline)) s[1]
  ];
  dropped_slots = [
    for (s = requested_slots) if (!slotFitsWith(s[1], slot_trimmed_cutter_outline)) s[0]
  ];

  // -------------------------------------------------------------------------
  // Circular base. See the header for the rule these all serve: a grid
  // position takes a mount when the mount's footprint, centred on it, lies
  // wholly inside the base outline.

  // The disc is drawn as a polygon inscribed in its circle, so its rim sits a
  // hair inside that circle. Fitting mounts against the apothem rather than the
  // radius keeps "inside the base" true of the shape that is actually printed
  // instead of the circle it stands in for. segs() rather than a bare $fn so
  // this still answers correctly when the caller left $fn unset and the facet
  // count comes from $fa and $fs.
  disc_segments = circularBase ? segs(diameter / 2) : 0;
  fit_radius = circularBase ? diameter / 2 * cos(180 / disc_segments) : 0;

  // The radius mounts are actually fitted against. A snap stands off the base
  // and takes nothing out of it, so it is fitted to the rim itself and only has
  // to be whole. An openConnect slot is a cut, so it is held MIN_SLOT_EDGE_WALL
  // back from the rim - and a disc needs that held back explicitly more than a
  // slab does, because the rim curves away from a straight-sided cutter instead
  // of meeting it square: a slot that merely reaches the rim leaves a sliver
  // rather than an edge.
  mount_fit_radius = fit_radius - (openConnectMount ? MIN_SLOT_EDGE_WALL : 0);

  // The outline the selected mount needs clear, in the base's own frame. For a
  // slot that is the published footprint and the cutter's own outline together,
  // simply concatenated rather than hulled - the test below asks whether every
  // vertex is inside the disc, and the disc is convex, so a set of points
  // answers for its hull. A snap is square and faces nowhere, so it needs no
  // turning.
  mount_footprint = openConnectMount
    ? concat(slot_footprint, slot_cutter_outline)
    : rect([SNAP_FOOTPRINT, SNAP_FOOTPRINT]);

  // The same with the entry trimmed, which is what a position is allowed to fall
  // back on. A snap has no entry to trim, so for snaps this is the same outline
  // and no mount is ever counted as trimmed.
  mount_trimmed_footprint = openConnectMount
    ? concat(slot_footprint, slot_trimmed_cutter_outline)
    : mount_footprint;

  // No position further out than this can hold a mount, so the sweep below has
  // somewhere to stop.
  mount_reach = circularBase
    ? ceil((mount_fit_radius + max([for (v = mount_footprint) norm(v)])) / OG_TILE_SIZE)
    : 0;

  // The rule itself: every vertex of the footprint inside mount_fit_radius. The
  // footprint is convex and the disc is convex, so the vertices settle it for
  // the edges between them too - which is also why is_pos_shape_in_region()
  // can test vertices alone on the rectangular base.
  function outlineFits(px, py, outline) =
    len([
      for (v = outline)
        if ((px + v.x) * (px + v.x) + (py + v.y) * (py + v.y)
          > mount_fit_radius * mount_fit_radius) 1
    ]) == 0;

  // A position is supported if it can be cut at all, which on a disc means the
  // trimmed cutter clears the rim; it needs the trim only if the whole one does
  // not. Same order as the rectangular base - whole first, trimmed as the
  // fallback.
  function mountFits(px, py) = outlineFits(px, py, mount_trimmed_footprint);
  function mountNeedsTrim(px, py) = !outlineFits(px, py, mount_footprint);

  // Supported positions at a given grid offset, as grid indices - x to the
  // right, y away, both counted from the position nearest the disc centre.
  // The distance test in front is the cheap half of the same question: both
  // footprints contain their own centre, so a position centred outside the
  // disc cannot possibly fit, and most candidates are thrown out for one
  // multiply rather than for a walk around a polygon.
  function mountIndicesAt(offset) = [
    for (i = [-mount_reach : mount_reach], j = [-mount_reach : mount_reach])
      let (px = i * OG_TILE_SIZE - offset.x, py = j * OG_TILE_SIZE - offset.y)
        if (px * px + py * py <= mount_fit_radius * mount_fit_radius && mountFits(px, py))
          [i, j]
  ];

  function mountPositionAt(ij, offset) =
    [ij.x * OG_TILE_SIZE - offset.x, ij.y * OG_TILE_SIZE - offset.y];

  // Whether mirroring the footprint the given way leaves it unchanged. The
  // disc is symmetric about every axis, so in an axis the footprint is
  // symmetric about, an offset and its mirror support the same mounts and the
  // sweep below need only cover half a tile. A snap is symmetric both ways; an
  // openConnect slot reaches further toward its mouth than away from it, so it
  // is symmetric only across the slide direction.
  function footprintMirrors(flip) =
    len([
      for (v = mount_footprint)
        if (!any([for (w = mount_footprint) approx(w, [flip.x * v.x, flip.y * v.y])])) 1
    ]) == 0;

  // How much rim the tightest mount at a given offset has to spare. Two
  // offsets often support the same number of mounts while one of them leaves a
  // mount all but touching the rim, so this is what separates them.
  //
  // Measured against the WHOLE cutter, deliberately, even for a mount that will
  // be cut with its entry trimmed: a mount needing the trim scores negative
  // here, so of two offsets holding the same number an offset that needs no
  // trimming always wins. The tie-break therefore doubles as a preference for
  // leaving entries whole, which is the same order of preference the
  // rectangular base applies per slot.
  function mountClearanceAt(offset) =
    let (
      room = [
        for (ij = mountIndicesAt(offset))
          let (p = mountPositionAt(ij, offset))
            mount_fit_radius - max([for (v = mount_footprint) norm(p + v)])
      ]
    ) len(room) == 0 ? 0 : min(room);

  // Maximal: sweep the offsets and keep the best count. Two tie-breaks follow,
  // because the count alone leaves a lot of offsets level and some of them are
  // plainly worse. First the roomiest - of the offsets that support the most
  // mounts, the one whose tightest mount is furthest from the rim, which is
  // what picks a symmetric arrangement over a lopsided one holding the same
  // number. Then the one nearest centred, which settles what is left and is
  // what makes Maximal come out at Centered rather than sliding the grid for
  // no gain.
  function maximalOffset() =
    let (
      last_x = footprintMirrors([-1, 1]) ? OG_TILE_SIZE / 2 : OG_TILE_SIZE - MOUNT_OFFSET_STEP,
      last_y = footprintMirrors([1, -1]) ? OG_TILE_SIZE / 2 : OG_TILE_SIZE - MOUNT_OFFSET_STEP,
      offsets = [
        for (ox = [0 : MOUNT_OFFSET_STEP : last_x], oy = [0 : MOUNT_OFFSET_STEP : last_y])
          [ox, oy]
      ],
      counts = [for (o = offsets) len(mountIndicesAt(o))],
      best = max(counts),
      most = [for (k = [0 : len(offsets) - 1]) if (counts[k] == best) offsets[k]],
      room = [for (o = most) mountClearanceAt(o)],
      roomiest = max(room),
      finalists = [for (k = [0 : len(most) - 1]) if (approx(room[k], roomiest)) most[k]],
      nearest = min([for (o = finalists) norm(o)])
    ) [for (o = finalists) if (approx(norm(o), nearest)) o][0];

  // Held back behind the ternary rather than computed and thrown away: the
  // sweep is thousands of offsets, and a rectangular base has no use for it.
  mount_offset = !circularBase || mountAlignment == "Centered" ? [0, 0] : maximalOffset();
  mount_indices = circularBase ? mountIndicesAt(mount_offset) : [];

  function hasMount(i, j) = in_list([i, j], mount_indices);
  function mountPosition(ij) = mountPositionAt(ij, mount_offset);

  // snapPlacement and slotPosition, read off the supported positions instead
  // of off a rectangle: a position is on an edge row when nothing sits above
  // or below it, on an edge column when nothing sits either side, and a corner
  // when both hold. On a full rectangular grid those pick out the same
  // positions is_grid_pos_described() picks out, which is why one function can
  // serve the snap vocabulary, the slot vocabulary and the lock vocabulary at
  // once. Anything unrecognised - "None", notably - selects nothing.
  function isEdgeRow(ij) = !hasMount(ij.x, ij.y - 1) || !hasMount(ij.x, ij.y + 1);
  function isEdgeColumn(ij) = !hasMount(ij.x - 1, ij.y) || !hasMount(ij.x + 1, ij.y);
  function isCorner(ij) = isEdgeRow(ij) && isEdgeColumn(ij);
  function selectedMounts(description) = [
    for (ij = mount_indices)
      if (description == "All"
        || (description == "Edges" && (isEdgeRow(ij) || isEdgeColumn(ij)))
        || (description == "Edge Rows" && isEdgeRow(ij))
        || (description == "Edge Columns" && isEdgeColumn(ij))
        || (description == "Corners" && isCorner(ij))
        || (description == "Top Corners" && isCorner(ij) && !hasMount(ij.x, ij.y + 1))
        || (description == "Bottom Corners" && isCorner(ij) && !hasMount(ij.x, ij.y - 1))
        || (description == "Staggered" && (ij.x + ij.y) % 2 == 0))
        ij
  ];

  circular_mounts = circularBase
    ? selectedMounts(openConnectMount ? slotPosition : snapPlacement)
    : [];

  // The ones among them that only fit with the entry trimmed, for the echo and
  // for circularMountSlots(). Empty for snaps, which have no entry to trim.
  circular_trimmed = circularBase && openConnectMount
    ? [for (ij = circular_mounts) let (p = mountPosition(ij))
        if (mountNeedsTrim(p.x, p.y)) ij]
    : [];

  // -------------------------------------------------------------------------
  // Reporting.

  if (circularBase) {
    assert(len(mount_indices) > 0,
      str("openGridMountBase: no ", openConnectMount ? "openConnect slot" : "openGrid snap",
        " fits inside a ", diameter, "mm circular base, so it would have no mount ",
        "at all. Enlarge the disc, or set the base shape to Rectangular."));

    assert(len(circular_mounts) > 0,
      str("openGridMountBase: ", openConnectMount ? "slotPosition" : "snapPlacement",
        " \"", openConnectMount ? slotPosition : snapPlacement,
        "\" selects none of the ", len(mount_indices),
        " supported grid positions on this circular base, so it would have no ",
        "mount. Pick another placement, or enlarge the disc."));

    echo(str(
      "opengrid_mount_base: circular base, ", diameter, "mm disc, ",
      len(circular_mounts), " of ", len(mount_indices), " supported grid positions mounted",
      approx(mount_offset, [0, 0])
        ? str(", grid centred on a mount",
            mountAlignment == "Maximal" ? " - Maximal found no offset that supports more." : ".")
        : str(", grid offset ", mount_offset, "mm from centred - centring it would support ",
            len(mountIndicesAt([0, 0])), ".")
    ));

    if (cornerRefinementType != "None")
      echo(str(
        "opengrid_mount_base: cornerRefinementType is \"", cornerRefinementType,
        "\", but a disc has no corners to refine, so it is ignored on a circular base."
      ));
  }

  // Everything the openConnect mount needs of the base. These live in the branch
  // rather than carrying a !openConnectMount guard so that a failure reports the
  // condition that actually matters, instead of an implication the reader has to
  // unpick. A statement-position assert only runs when it is reached, so the snap
  // mount never sees them.
  if (openConnectMount) {
    assert(thickness >= openGridMountMinThickness(),
      str("openGridMountBase: thickness must be at least ", openGridMountMinThickness(),
        "mm for the openConnect mount - ", slot_depth, "mm of openConnect slot plus ",
        MIN_BASE_WALL, "mm of solid floor under it - but it is ", thickness,
        "mm. Raise it, or set the mount type to Snaps."));

    echo(str(
      "opengrid_mount_base: openConnect mount, ",
      let (n = circularBase ? len(circular_mounts) : len(fitted_slots))
        str(n, n == 1 ? " slot" : " slots"), " on a ",
      circularBase
        ? str(diameter, "mm circular base. ")
        : str(xUnits, "x", yUnits, " grid over a ", x_size, "x", y_size, "mm base. "),
      "Each slot takes ", slot_depth, "mm of the ", thickness, "mm base, leaving ",
      thickness - slot_depth, "mm of floor under it.",
      let (trimmed = circularBase ? len(circular_trimmed) : len(trimmed_slots))
        trimmed == 0 ? ""
          : str(" ", trimmed, " of them have ", SLOT_ENTRY_TRIM,
              "mm off the entry so they clear the outside of the base by ",
              MIN_SLOT_EDGE_WALL, "mm; those seat with less room to line the ",
              "connector up, and the rest are untouched.")
    ));

    // Only the rectangular base can drop a slot it asked for: the circular base
    // never asks for one that does not fit, and reports what it supports above.
    if (!circularBase && len(fitted_slots) < len(requested_slots))
      echo(str(
        "opengrid_mount_base: ", len(requested_slots) - len(fitted_slots), " of ",
        len(requested_slots), " slots cannot be cut with ", MIN_SLOT_EDGE_WALL,
        "mm of material left between the cut and the outside of the base, even ",
        "with ", SLOT_ENTRY_TRIM, "mm off the entry, and were dropped. Reduce the ",
        "corner refinement size, turn it off, or pick a slot position that keeps ",
        "clear of the corners."
      ));

    // Guarded rather than asserted directly so the suggestion scan below only
    // runs on the way to the error, not on every render that is fine.
    if (!circularBase && len(fitted_slots) == 0)
      assert(false,
        str("openGridMountBase: no openConnect slot can be cut with ", MIN_SLOT_EDGE_WALL,
          "mm of material left between the cut and the outside of the base, even ",
          "with ", SLOT_ENTRY_TRIM, "mm off the entry, so the base would have no ",
          "mount at all and could not attach to a board.",
          let (all = largestRefinementLeaving(len(requested_slots)),
               some = largestRefinementLeaving(1))
            let (n = len(requested_slots),
                 every = n == 1 ? "its only slot" : str("all ", n, " slots"),
                 fix = str(" Reduce it, turn it off, enlarge the base, or set the mount ",
                   "to Snaps, which stand off the face instead of cutting into it."))
              some < 0
                ? str(" No ", cornerRefinementType, " of any size leaves a slot on a ",
                    xUnits, "x", yUnits, " base.", fix)
                : str(" On this ", xUnits, "x", yUnits, " base a ", cornerRefinementType,
                    " of up to ", all, "mm keeps ", every,
                    approx(all, some) ? "" : str(", and up to ", some,
                      "mm keeps at least one"),
                    "; it is ", cornerRefinementSize, "mm.", fix)));
  }

  // -------------------------------------------------------------------------
  // Geometry.

  // openConnect slots, cut into the board-facing underside of the slab - the
  // same face the snaps would stand on, and the reason the grid has to be
  // turned over to get there.
  //
  // The library builds its grid the way a shelf or a plate uses it: wide end at
  // the grid's own BOTTOM, narrowing upward, and the mount face at the grid's
  // TOP with the material below it - see the attach(TOP, TOP, inside=true) in
  // mitufy's own openconnect_plate.scad. This base is the other way up. Its
  // material is ABOVE the face that meets the board, so the grid is turned over
  // before it is sunk into the underside, and is anchored by its TOP so the
  // turn swings it about the mouth and leaves that mouth on the board-facing
  // face. openGridMountSlotFlipAxis() carries the reasoning for turning rather
  // than mirroring, and for turning about the slide axis in particular.
  //
  // Which slots get cut is settled twice over, by the two rules slotFitsWith()
  // spells out: limit_region hands the library its own footprint rule, and
  // except_slot_pos hands it the positions whose cutter would come closer than
  // MIN_SLOT_EDGE_WALL to the outside of the base, which is a rule the library
  // has no way to express. The strips then shorten the entries of the positions
  // that only fit because they are allowed to be shortened - also something the
  // library cannot be asked for, since one grid call draws every slot alike.
  module rectangularMountSlots() {
    down(thickness / 2)
      rot(180, v=openGridMountSlotFlipAxis(slotSlideDirection))
        difference() {
          openconnect_slot_grid(
            slot_type="slot",
            horizontal_grids=xUnits,
            vertical_grids=yUnits,
            slot_slide_direction=slotSlideDirection,
            slot_position=slotPosition,
            slot_lock_distribution=openGridMountTurnedLockDistribution(
              slotSlideDirection, slotLockDistribution),
            slot_lock_side=openGridMountTurnedLockSide(slotLockSide),
            slot_entryramp_flip=slotEntryRampFlip,
            limit_region=[base_outline],
            except_slot_pos=dropped_slots,
            excess_thickness=EPS,
            anchor=TOP
          );
          for (cp = trimmed_slots)
            openGridMountEntryTrimStrip(slotSlideDirection, cp);
        }
  }

  // openConnect slots for a circular base. openconnect_slot_grid() always
  // centres a whole number of tiles on the model, so it can neither be offset
  // nor thinned down to a circle - but openGridMountSlotCutter() is a single
  // slot at the origin, and moving one of those into place says the same thing.
  //
  // Turned over the same way and for the same reason as the rectangular grid,
  // but from inside the translate, so each slot swings about its own mouth and
  // the mounts stay exactly where mountPosition() put them. That is also why
  // this one has no turned lock distribution to apply: nothing here is picked
  // out by row, so the turn has no row to carry across.
  module circularMountSlots() {
    locked = selectedMounts(slotLockDistribution);
    down(thickness / 2)
      for (ij = circular_mounts)
        let (p = mountPosition(ij))
          translate(p)
            openGridMountSlotCutter(
              slotSlideDirection=slotSlideDirection,
              locked=in_list(ij, locked),
              slotLockSide=slotLockSide,
              slotEntryRampFlip=slotEntryRampFlip,
              trimEntry=mountNeedsTrim(p.x, p.y)
            );
  }

  // The grid positions that get an anchor, as [name_i, name_j, [x, y]].
  //
  // A rectangular base publishes every tile it covers, mounted or not - every
  // one is a whole tile, and a consumer may well want to attach something over
  // a bare one. A disc publishes the positions it can actually support, since
  // "the tiles it covers" is not a well-formed question there.
  //
  // Circular indices are signed and centred, so they are shifted to start at
  // zero, and j is reversed so that j = 0 is the row furthest in +Y under both
  // shapes rather than under only one of them.
  circular_i_min = circularBase ? min([for (ij = mount_indices) ij.x]) : 0;
  circular_j_max = circularBase ? max([for (ij = mount_indices) ij.y]) : 0;

  anchor_positions = circularBase
    ? [for (ij = mount_indices)
        [ij.x - circular_i_min, circular_j_max - ij.y, mountPosition(ij)]]
    : [for (i = [0 : xUnits - 1], j = [0 : yUnits - 1]) [i, j, rectPosition(i, j)]];

  board_z = -total_thickness / 2 + snap_thickness;

  anchors = concat(
    [named_anchor("board", [0, 0, board_z], DOWN, 0)],
    [for (a = anchor_positions)
      named_anchor(str("mount_", a[0], "_", a[1]), [a[2].x, a[2].y, board_z], DOWN, 0)]
  );

  // Breaking the top edge is a cut into the slab from above, so it can ask for
  // more material than there is. Clamped to the thickness - at exactly that, a
  // fillet takes the top face away to a bullnose and a chamfer to a knife edge,
  // which are the limits of the shapes rather than failures - and to half the
  // shorter span, so the two breaks on opposite sides cannot cross.
  top_edge_room = min(thickness, (circularBase ? diameter : min(x_size, y_size)) / 2);
  top_edge_size = topEdgeRefinementType == "None" ? 0
    : min(topEdgeRefinementSize, top_edge_room);

  if (topEdgeRefinementType != "None" && topEdgeRefinementSize > top_edge_room)
    echo(str(
      "opengrid_mount_base: top edge refinement asked for ", topEdgeRefinementSize,
      "mm but only ", top_edge_room, "mm is available on a ", thickness,
      "mm slab this size, so it was cut back to that."
    ));

  // A solid the base is intersected with to break its top edges: the same
  // footprint, reaching from well below the board up to the top face, with the
  // edges around that face refined.
  //
  // A mask rather than a refinement on the slab's own cuboid, because a slab
  // can already carry a DIFFERENT refinement down its vertical corners and one
  // cuboid() call takes a single rounding for the edge set it is given. The
  // mask is the full rectangle - vertical corners square - so it never reaches
  // inside the slab's own corner refinement, and where the two meet the
  // intersection blends them. It is the full footprint and hangs far below, so
  // it clips neither the snaps, which are narrower, nor anything under the
  // board plane.
  module topEdgeMask() {
    reach = total_thickness * 2 + top_edge_size + 1;
    up(total_thickness / 2) {
      if (circularBase) {
        cyl(h=reach, d=diameter, anchor=TOP,
          rounding2=(topEdgeRefinementType == "Fillet" ? top_edge_size : 0),
          chamfer2=(topEdgeRefinementType == "Chamfer" ? top_edge_size : 0));
      } else {
        cuboid([x_size, y_size, reach], anchor=TOP, edges=TOP,
          rounding=(topEdgeRefinementType == "Fillet" ? top_edge_size : 0),
          chamfer=(topEdgeRefinementType == "Chamfer" ? top_edge_size : 0));
      }
    }
  }

  // The slab itself, centred on the origin, with the mount applied. Drawn once
  // and used by whichever attachable() the shape calls for, so the two shapes
  // differ only in the envelope they publish anchors against.
  module baseBody() {
    if (top_edge_size > 0) {
      intersection() { slabWithMount(); topEdgeMask(); }
    } else {
      slabWithMount();
    }
  }

  module slabWithMount() {
    if (openConnectMount) {
      difference() {
        if (circularBase) {
          cyl(h=thickness, d=diameter);
        } else {
          cuboid(
            [x_size, y_size, thickness],
            rounding=(cornerRefinementType == "Fillet" ? cornerRefinementSize : 0),
            chamfer=(cornerRefinementType == "Chamfer" ? cornerRefinementSize : 0),
            edges="Z"
          );
        }
        if (circularBase) circularMountSlots(); else rectangularMountSlots();
      }
    } else if (circularBase) {
      // The circular snap base. Snaps stand off the slab's own TOP, so the
      // whole thing is turned over together to put them against the board -
      // the same construction the rectangular branch below uses, differing
      // only in the outline and in where the snaps are allowed to sit.
      xrot(180)
        down(total_thickness / 2)
          cyl(h=thickness, d=diameter, anchor=BOTTOM) {
            for (ij = circular_mounts)
              color("lightblue")
                translate(mountPosition(ij))
                  attach(TOP, TOP)
                    openGridSnap(lite=liteSnap);
          }
    } else {
      // The rectangular snap base, drawn the same way as the circular one above
      // - the only difference is a cuboid where that has a cyl.
      //
      // Deliberately NOT openGridFacade(), which draws the same slab and the
      // same snaps and is the obvious thing to reach for. Calling it would
      // make the general part depend on the specific one - a facade is this
      // base with a thin slab and a removal notch - and would leave this module
      // with two ways of doing one thing, since the disc has to place its own
      // snaps regardless: the facade cannot draw a round outline. Drawing both
      // here keeps one implementation and leaves the facade free to be rebuilt
      // on this module rather than the other way round.
      //
      // Snaps stand off the slab's own TOP, so the whole thing is turned over
      // to put them against the board. That turn also reverses Y, which costs
      // nothing: every placement rectSnapSelected() offers is symmetric about
      // the grid's middle row, so no snap moves.
      xrot(180)
        down(total_thickness / 2)
          cuboid(
            [x_size, y_size, thickness],
            rounding=(cornerRefinementType == "Fillet" ? cornerRefinementSize : 0),
            chamfer=(cornerRefinementType == "Chamfer" ? cornerRefinementSize : 0),
            edges="Z",
            anchor=BOTTOM
          ) {
            for (p = rect_snap_positions)
              color("lightblue")
                translate(p)
                  attach(TOP, TOP)
                    openGridSnap(lite=liteSnap);
          }
    }
  }

  // A disc is attachable as a cylinder and a slab as a cuboid, so that RIGHT
  // lands on the rim of a disc rather than on the corner of the box round it,
  // and edge and corner anchors stay meaningful on a slab.
  if (circularBase) {
    attachable(d=diameter, l=total_thickness, anchors=anchors,
      anchor=anchor, orient=orient, spin=spin) {
      baseBody();
      children();
    }
  } else {
    attachable(size=[x_size, y_size, total_thickness], anchors=anchors,
      anchor=anchor, orient=orient, spin=spin) {
      baseBody();
      children();
    }
  }
}
