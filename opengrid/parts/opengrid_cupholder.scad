/*
  opengrid_cupholder.scad

  A cup holder that mounts to an openGrid board through a flat base, with
  optional handle slots cut through the wall so mugs with handles can sit in it.

  Two mounts are offered, and they are alternatives rather than additions:

    openConnect - the base is a plain slab with openConnect slots cut into the
                  face that meets the board. Screw openConnect connectors into
                  the board first, then slide the holder onto them. The default.
    Snaps       - openGrid snaps stand proud of the base and click into the
                  tiles. The original mount.

  The model stands the way it is used: the base sits on the Z = 0 plane with
  its board-facing side down, and the cup opens upward above it.

  Only one of the two is ever built. Both claim the same tiles from the same
  face of the base, and the snaps stand off exactly the face the openConnect
  mount needs flat against the board, so a holder carrying both could not sit
  down on the board at all.

  ---------------------------------------------------------------------------
  Directions

  Two things in this file point somewhere: the handle slots take an angle, and
  the openConnect mount takes compass-style direction names. They share one
  frame, so a slot can be lined up with the mount by number rather than by eye:

      +X    angle   0    Slot_Slide_Direction "Right"
      +Y    angle  90    Slot_Slide_Direction "Up"
      -X    angle 180    Slot_Slide_Direction "Left"
      -Y    angle 270    Slot_Slide_Direction "Down"

  The angle is measured looking down into the cup, counterclockwise from +X,
  the way zrot() measures - so 0 is to the right, 90 away from you, 180 to the
  left, 270 toward you. Both mounts read it the same way, so changing
  Mount_Type leaves the slots where they are.

  The four direction names come from mitufy's connector library. They are
  written above as the axes they actually land on rather than as left and right
  from some viewpoint, because the cup and the underside it mounts by are
  looked at from opposite sides and naming one of them would settle less than
  it appears to.

  ---------------------------------------------------------------------------
  Base shape

  The base is a square slab by default: a whole number of 28mm grid units on
  each side, sized up to cover the cup. Base_Shape = "Circular" drops the slab
  and leaves the cup's own outline as the whole base, so the holder carries no
  material the cup does not stand on and nothing stands out past the cup.

  The disc is the cup's outer diameter where it meets the base, so a cup that
  flares upward - the default - overhangs its own base rather than sitting on
  a lip. Size_Base_Units_To_Bottom_Diameter has nothing to choose here: it
  sizes the square base's grid, and a disc is the base end's diameter either
  way.

  A square base is its own grid - every tile it covers is a whole tile, so
  every tile takes a mount. A disc cuts across tiles, so both mounts share one
  rule for which positions are supported:

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

  A slot is held back further still. A snap only has to be whole, but a slot is
  a cut, and a cut that reaches the outside of the base leaves nothing there to
  print - so every slot keeps a band of solid material, MIN_SLOT_EDGE_WALL,
  between itself and the outside. That applies to both bases: on a square base
  it is what stops a refined corner being eaten through by a slot near it, and
  on a disc it is what stops a slot approaching the curved rim at a tangent and
  leaving a sliver.

  A slot that cannot keep that band is not simply lost. Most of the cutter's
  reach toward the mouth is the entry the connector head drops into, and the
  head will still go in through a shorter one, so such a slot is offered
  SLOT_ENTRY_TRIM off its entry and kept if that is enough. The choice is
  between two lengths and no others - whole, or short by that much - and whole
  is always tried first, because a full entry gives the most room to line the
  connector up by hand. A slot that still does not fit is dropped, and the echo
  says how many were trimmed and how many went.

  Corner_Refinement_Type and Corner_Refinement_Size are square-base settings.

  A disc is not tied to the grid the way the slab is, so where the grid falls
  under it is a free choice, and Mount_Alignment makes it:

      Centered - a mount sits at the centre of the disc.
      Maximal  - the grid is offset to support as many mounts as it can.

  Either way the mounts stay 28mm apart, which is all the board asks of them.

  What Maximal counts is mounts, not whole grid units. A mount needs the disc
  under what it actually uses rather than under the whole 28mm tile, so
  counting tiles would refuse positions that are perfectly well supported: the
  default cup takes four openConnect slots on a disc only two whole tiles fit
  under.

  Maximal really searches. It does not test only the four offsets of nought or
  half a tile in each axis, because those are not always the best. A 108mm disc
  takes seven snaps at an offset of [0, 5.5]mm and six at any of the four. A
  36mm disc takes one openConnect slot at [0, 24.75]mm where all four of them
  take none at all - which is the difference between a holder that mounts and
  one that refuses to build. The sweep covers half a tile in each axis the
  mount footprint is symmetric about and a whole tile in each axis it is not,
  in MOUNT_OFFSET_STEP steps.

  Ties are settled twice over, because a lot of offsets support the same
  number of mounts and some of those are plainly worse. First by which offset
  leaves its tightest mount the most rim to spare, which takes a symmetric
  arrangement over a lopsided one holding the same number rather than parking
  a mount a tenth of a millimetre from the edge. Then by which is nearest
  centred, which stops the grid sliding for no gain.

  Snap_Placement and Slot_Position keep their meanings on a disc, read off the
  supported positions rather than off a rectangle: a position is on an edge
  row when it has no neighbour above or below it, on an edge column when it
  has none to either side, and a corner when both are true. On a full
  rectangular grid that picks out exactly what those options pick out today.

  A disc has no corners, so they are ignored there. On a square base a
  refinement that reaches into a corner tile costs that corner's slot its full
  entry first and then, if it reaches far enough, the slot itself.

  ---------------------------------------------------------------------------
  Licensing

  The cup holder geometry in this file is original work by zing3d-labs and is
  licensed under the repository license, CC BY-NC-SA 4.0 (see ../../LICENSE).

  The openConnect mount is generated by mitufy's connector library
  (external/opengrid-projects/lib/openconnect_lib.scad), which is licensed
  Creative Commons Attribution 4.0 International:

      openConnect / openGrid connector libraries
      Created by mitufy - https://github.com/mitufy
      https://www.printables.com/model/1559478-openconnect-opengrids-own-connector-system

  openGrid is created by David D:
      https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem

  The snap mount comes from QuackWorks (external/QuackWorks) - by way of
  opengrid_facade.scad for the square base, and straight from
  openGrid/opengrid-snap.scad for the circular one, which draws its own snaps
  because the facade only knows how to draw rectangles. QuackWorks is
  CC BY-NC-SA 4.0, the same license this repository uses, so that dependency
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
use <opengrid_facade.scad>
use <../../external/QuackWorks/openGrid/opengrid-snap.scad>

/* [Cup Holder] */

// Inner diameter at the cup opening (top), in mm
Cup_Holder_Top_Diameter = 90;

// Inner diameter at the facade (mounting) end, in mm
Cup_Holder_Bottom_Diameter = 75;

// Height of the cup holder body, in mm
Cup_Holder_Height = 90;

// Thickness of the cup holder walls, in mm
Wall_Thickness = 2;

/* [Handle Slots] */

// Number of slots cut through the cup wall so mugs with handles can sit in the
// holder, spaced evenly around the circumference. 0 leaves the wall solid.
Handle_Slot_Count = 0; // [0:1:8]

// How far each slot reaches down from the cup opening (the wide top rim), in mm
Handle_Slot_Height = 45; // [1:1:200]

// Width of the slot, in mm. Sized to the handle that has to pass through it,
// so it is a flat measurement rather than a share of the circumference.
Handle_Slot_Width = 30; // [1:0.5:120]

// Angle of the first slot around the cup, in degrees. The remaining slots
// follow evenly around from it. Measured looking down into the cup from above,
// counterclockwise from +X, the way zrot() measures:
//
//     0 = right,  90 = back (away from you),  180 = left,  270 = front
//
// Both mounts read it the same way, so changing Mount_Type does not move the
// slots.
Handle_Slot_Start_Angle = 0; // [0:5:355]

// How to break the two ends of each slot - the mouth at the rim and the closed
// inner end
Handle_Slot_End_Refinement_Type = "Fillet"; // [None, Chamfer, Fillet]

// Measurement for the selected refinement - fillet radius or chamfer leg, in mm
Handle_Slot_End_Refinement_Size = 10; // [0.5:0.5:20]

/* [Base Settings] */

// How the base attaches to the board. openConnect slides onto connectors
// screwed into the tiles; snaps click into the tiles directly. The two are
// alternatives - the options below apply only to the mount selected here.
Mount_Type = "openConnect"; // [openConnect, Snaps]

// Shape of the mounting base. Square is the grid-sized slab - a whole number
// of 28mm units on a side, sized up to cover the cup. Circular drops the slab
// and takes the cup's own outline instead, so the base carries no material the
// cup does not stand on and never stands out past it. A disc has no corners,
// so Corner_Refinement_Type and Corner_Refinement_Size do nothing there.
Base_Shape = "Square"; // [Square, Circular]

// Where the 28mm mount grid falls under a circular base. Centered puts a mount
// at the centre of the disc. Maximal offsets the grid to support as many
// mounts as it can, breaking ties toward the roomiest fit and then toward
// centred. A square base is its own grid, so this does nothing there.
Mount_Alignment = "Maximal"; // [Centered, Maximal]

// Thickness of the mounting base, in mm. This is also the floor of the cup.
// Left open rather than ranged: the snap mount is happy with a thin base, and
// the openConnect mount asserts its own minimum of 2.7mm of slot plus 0.8mm of
// solid floor beneath it, so it says so itself rather than the slider hiding it.
Base_Thickness = 4;

// Use the bottom (open end) diameter to size the grid instead of the top diameter.
// The top diameter may overlap additional tiles slightly, which is fine if enabled.
// This sizes the square base only: a circular base is the cup's outline where it
// meets the base, which is the bottom diameter whichever way the cup tapers.
Size_Base_Units_To_Bottom_Diameter = false;

// How to adjust corners for visual appeal
Corner_Refinement_Type = "Fillet"; // [None, Chamfer, Fillet]

// Measurement for the selected corner refinement
Corner_Refinement_Size = 5; // [2:0.5:20]

/* [Snap Mount] */

// Version of the tile, Full (6.8mm) or Lite (3.4mm)
Grid_Type = "Lite"; // [Full,Lite]

// Snap Placement
Snap_Placement = "Corners"; // [All, Edges, Corners]

/* [openConnect Mount] */

// Direction the holder slides to come off the connectors, in the model's own
// axes: "Right" is +X, "Left" is -X, "Up" is +Y, "Down" is -Y. Those are the
// axes Handle_Slot_Start_Angle is measured in, so "Right" is that angle's 0,
// "Up" its 90, "Left" its 180 and "Down" its 270. The holder seats by sliding
// the opposite way, so point this at whichever side of the board has room to
// work. On a horizontal board none of the four is uphill.
Slot_Slide_Direction = "Up"; // [Up, Down, Left, Right]

// Which grid positions get a slot. A slot costs nothing to print, so cutting
// all of them keeps every board position usable; the connectors you actually
// screw into the board are still up to you.
Slot_Position = "All"; // [All, Staggered, Edge Rows, Edge Columns, Corners]

// Which slots get the locking nub - the detent that stops the holder sliding
// back off. All, because you pick which handful of tiles to put connectors in,
// and the slots you happen to pick should be the locking ones. Nothing else
// holds the holder on a horizontal board, so None is not advisable here. Thin
// this out only if the fit comes out too tight to seat by hand.
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
Smoothing = 150; // [10:10:300]

/* [Hidden] */

// Solid material kept under the deepest point of an openConnect slot, so the
// cup keeps a continuous floor.
MIN_BASE_WALL = 0.8;

// Solid material kept between an openConnect slot cut and the outside of the
// base, all the way round it. The same 0.8mm as MIN_BASE_WALL above, and
// deliberately a constant of its own rather than that one reused: MIN_BASE_WALL
// is the floor UNDER a slot and feeds the Base_Thickness assert, this is the
// band BESIDE it and decides which slots get cut at all. The two answer to
// different things - one to how stiff the cup floor has to be, the other to how
// thin a wall the printer will hold - so moving either should not silently move
// the other.
//
// 0.8 is also not a number picked out of the air: it is the wall the library
// already leaves on its own. A slot cutter stops at y = -13.2 in its own 28mm
// tile, which is 0.8mm short of the tile edge at the mouth end. That is what
// lets a square base with no corner refinement sit exactly at this limit and
// lose no slot, and it means raising this number costs every slot on an edge
// row - so raise it only on purpose.
MIN_SLOT_EDGE_WALL = 0.8;

// What an openGrid snap needs clear on a circular base: 25.58mm square. That
// is openGridSnap's 24.8mm core (its own w, in
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

// The ground an openConnect slot cutter actually covers, which is more than the
// footprint the library publishes. That footprint is the slot pocket plus its
// 2mm wall and stops at y = -3.8; the cutter runs on to y = -13.2 for the
// lead-in ramp, and 13.004mm out to the side the ramp is offset toward. Both
// bases need it. Neither the tile edge nor the grid edge stops the ramp - the
// cutter is already inside its own tile on every side - so nothing but this
// outline says where the cut really reaches, and a slot tested on the footprint
// alone can break out through a refined corner or a curved rim. Measured off
// projection() of openconnect_slot_grid() at one by one; re-measure if the
// pinned external/opengrid-projects moves. Stated symmetrically in x because
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

openGridCupholder(
  cupHolderBottomDiameter=Cup_Holder_Bottom_Diameter,
  cupHolderTopDiameter=Cup_Holder_Top_Diameter,
  cupHolderHeight=Cup_Holder_Height,
  wallThickness=Wall_Thickness,
  handleSlotCount=Handle_Slot_Count,
  handleSlotHeight=Handle_Slot_Height,
  handleSlotWidth=Handle_Slot_Width,
  handleSlotStartAngle=Handle_Slot_Start_Angle,
  handleSlotEndRefinementType=Handle_Slot_End_Refinement_Type,
  handleSlotEndRefinementSize=Handle_Slot_End_Refinement_Size,
  mountType=Mount_Type,
  baseShape=Base_Shape,
  mountAlignment=Mount_Alignment,
  baseThickness=Base_Thickness,
  sizeGridToBottomDiameter=Size_Base_Units_To_Bottom_Diameter,
  snapPlacement=Snap_Placement,
  cornerRefinementType=Corner_Refinement_Type,
  cornerRefinementSize=Corner_Refinement_Size,
  liteSnap=(Grid_Type == "Lite"),
  slotSlideDirection=Slot_Slide_Direction,
  slotPosition=Slot_Position,
  slotLockDistribution=Slot_Lock_Distribution,
  slotLockSide=Slot_Lock_Side,
  slotEntryRampFlip=Slot_Entry_Ramp_Flip,
);

module openGridCupholder(
  cupHolderBottomDiameter = 85,
  cupHolderTopDiameter = 90,
  cupHolderHeight = 90,
  wallThickness = 2,
  handleSlotCount = 0,
  handleSlotHeight = 45,
  handleSlotWidth = 30,
  handleSlotStartAngle = 0,
  handleSlotEndRefinementType = "Fillet",
  handleSlotEndRefinementSize = 10,
  mountType = "openConnect",
  baseShape = "Square",
  mountAlignment = "Maximal",
  baseThickness = 4,
  sizeGridToBottomDiameter = false,
  snapPlacement = "Corners",
  cornerRefinementType = "Fillet",
  cornerRefinementSize = 5,
  liteSnap = false,
  slotSlideDirection = "Up",
  slotPosition = "All",
  slotLockDistribution = "All",
  slotLockSide = "Left",
  slotEntryRampFlip = false,
  anchor,
  orient,
  spin
) {
  $fn = Smoothing;

  outer_bottom_diameter = cupHolderBottomDiameter + 2 * wallThickness;
  outer_top_diameter = cupHolderTopDiameter + 2 * wallThickness;

  sizing_diameter = sizeGridToBottomDiameter ? outer_bottom_diameter : outer_top_diameter;
  units = ceil(sizing_diameter / OG_TILE_SIZE);
  base_size = units * OG_TILE_SIZE;

  openConnectMount = mountType == "openConnect";

  // A slot never reaches past the facade end of the cup.
  slot_height = min(handleSlotHeight, cupHolderHeight);
  // Slot cutters run from the cup axis out to here - past the widest point of
  // the outer surface - so each one removes the full wall thickness at every
  // height, whichever way the body tapers.
  slot_reach = max(outer_bottom_diameter, outer_top_diameter) / 2 + 1;
  // Overhang past the rim, so the cut face is not coplanar with it.
  slot_overhang = 0.01;
  // Clamped so the two ends can never overrun each other or pinch the slot shut.
  slot_end_size = handleSlotEndRefinementType == "None"
    ? 0
    : min(handleSlotEndRefinementSize, handleSlotWidth / 2, slot_height / 2);

  // The one thing both mounts need of the base, so it is not in either branch.
  // How thin is thin enough is a printing question rather than a modelling one,
  // and is left to the user - but zero is not thin, it is absent: the slab
  // vanishes and the cup meets the snaps across a plane of no thickness, which
  // renders without complaint and cannot be printed at all.
  assert(baseThickness > 0,
    str("Base_Thickness must be greater than zero - it is ", baseThickness,
      "mm, which leaves no base for the cup to stand on."));

  // Depth an openConnect slot eats out of the base, from the board-facing face.
  mount_slot_depth = struct_val(ocslot_cfg(), "total_height");

  // Turning the slot cutter over - see mountSlots() for why it has to be
  // turned at all, and this for why it is turned about THIS axis.
  //
  // A cutter that has to come out the other way up can be got there two ways,
  // and they are not the same part. zflip() is a mirror: it reverses the
  // cutter's handedness, and the connector head is chiral, so a mirrored
  // cutter is one no real connector fits. The head's two lock detents are cut
  // by different code - the left one sheared over by nub_taperin, the right
  // one straight, because bridging does not print over a tapered nub - and a
  // mirrored slot presents its nub to the wrong one of them. Measured against
  // openconnect_head(head_type="head", add_nubs="Both"), which is the head
  // openconnect_screw() actually carries: a turned cutter takes it with the
  // difference empty, a mirrored one leaves 74-96 facets of the head standing
  // in the nub. So the cutter is TURNED, with rot(), and never mirrored.
  //
  // That empty difference is exact at Slot_Slide_Direction "Up". The other
  // three leave the same 74-96 facets in the nub, and that is the library's
  // own doing rather than the turn's: openconnect_slot_grid() used entirely on
  // its own terms, with no turn of ours anywhere, leaves it for "Down", "Left"
  // and "Right" too, because the library reaches those three by mirroring its
  // "Up" slot. It squeezes rather than blocks - the nub is a detent, not the
  // retainer - and the retaining lip this is all for comes out identical in
  // all four. Do not read it as something the turn introduced.
  //
  // A turn is about an axis, and the axis is the one the slot slides along,
  // because that is the axis the cutter is symmetric across:
  //
  //   - The direction table in the header survives. A turn about the slide
  //     axis leaves the slide axis alone, so "Up" still lands on +Y and lines
  //     up with a handle slot at 90 degrees. Turning about the other axis
  //     would reverse it, and asking the library for the opposite name instead
  //     is no escape - its "Down" IS a mirror of its "Up" (verified: the two
  //     differ by yflip alone), so that route arrives back at a mirrored part.
  //   - Every fit test survives. slot_cutter_outline and slot_footprint below
  //     are symmetric across the slide direction and only across it, so a turn
  //     about that axis leaves the outline either base fits against exactly
  //     where it was - which is also what lets the square base's own test be
  //     written in the grid's frame and still answer for the base's.
  //
  // What the turn does reverse is the axis across the slide, so two things are
  // handed back below: the side the nubs sit on, and - on the square base,
  // where the turn is about the whole grid rather than about each slot - the
  // row a distribution names.
  slot_slides_along_x = slotSlideDirection == "Left" || slotSlideDirection == "Right";
  slot_flip_axis = slot_slides_along_x ? RIGHT : BACK;

  // The library is asked for the nubs on the far side from the one they are
  // wanted on, because the turn carries them across. Both sides pair exactly
  // with the head - each detent receives the nub cut by the same code - so
  // this costs nothing but the swap.
  turned_lock_side = slotLockSide == "Left" ? "Right" : "Left";

  // A turn about X reverses the grid's rows, so a distribution that names a
  // row is asked for by the other name. Only the square base needs this: the
  // circular one turns each slot about its own centre and never moves a mount.
  // "Staggered" has no such handle - on an even grid the turn takes it to the
  // complementary staggered set, which is the same pattern offset by a tile.
  turned_lock_distribution =
    !slot_slides_along_x ? slotLockDistribution
    : slotLockDistribution == "Top Corners" ? "Bottom Corners"
    : slotLockDistribution == "Bottom Corners" ? "Top Corners"
    : slotLockDistribution;

  // Outline of the base, and the same outline held back by a given inset - the
  // band of material a cut has to stay behind. One function rather than a shape
  // and a separate approximation of it, because both refinements survive an
  // inset exactly: eroding a rounded corner by b leaves the same arc b smaller,
  // and eroding a 45-degree chamfer slides its face b inward along its own
  // normal, which shortens the leg by b(2 - sqrt(2)). Clamped at zero, since a
  // corner cannot be refined by a negative amount - an inset deeper than the
  // refinement simply leaves a square corner.
  function baseOutline(inset = 0) =
    let (refined = max(0, cornerRefinementSize -
      inset * (cornerRefinementType == "Chamfer" ? 2 - sqrt(2) : 1)))
      rect([base_size - inset * 2, base_size - inset * 2],
        rounding=(cornerRefinementType == "Fillet" ? refined : 0),
        chamfer=(cornerRefinementType == "Chamfer" ? refined : 0));

  base_outline = baseOutline();

  // What an openConnect slot needs clear of the base. Two outlines, because the
  // library publishes one and cuts with another:
  //
  //   slot_footprint       the slot pocket plus the 2mm wall the library keeps
  //                        around it - the shape openconnect_slot_grid() tests
  //                        against limit_region.
  //   slot_cutter_outline  the ground the cutter actually covers, lead-in ramp
  //                        included. Bigger than the footprint toward the mouth
  //                        and out to the ramp side, and the only one of the two
  //                        that can break the outside of the base.
  //
  // Both turn with the slide direction, and openconnect_slot_grid() keeps that
  // mapping to itself, so it is repeated here to stay in step. Both are convex,
  // which is what lets every test below settle a shape by its vertices alone.
  //
  // The cutter comes in two lengths, because a slot that will not otherwise fit
  // can have SLOT_ENTRY_TRIM taken off its mouth end instead of being dropped.
  // The footprint has only one length: it stops 9.4mm short of the mouth, so
  // the trim never reaches it, and a slot the library's own rule rejects cannot
  // be rescued by trimming.
  slot_facing =
    slotSlideDirection == "Left" ? 90
    : slotSlideDirection == "Right" ? -90
    : slotSlideDirection == "Down" ? 180
    : 0;
  slot_footprint = zrot(slot_facing, struct_val(ocslot_cfg(), "footprint"));
  function slotCutterOutline(trim = 0) = zrot(slot_facing, [
    [SLOT_CUTTER_BOUNDS[0].x, SLOT_CUTTER_BOUNDS[0].y + trim],
    [SLOT_CUTTER_BOUNDS[1].x, SLOT_CUTTER_BOUNDS[0].y + trim],
    [SLOT_CUTTER_BOUNDS[1].x, SLOT_CUTTER_BOUNDS[1].y],
    [SLOT_CUTTER_BOUNDS[0].x, SLOT_CUTTER_BOUNDS[1].y],
  ]);
  slot_cutter_outline = slotCutterOutline();
  slot_trimmed_cutter_outline = slotCutterOutline(SLOT_ENTRY_TRIM);

  // Which slots the square base will actually cut. A slot has to meet both of:
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
  // runs over while the footprint still reports the slot as fitting. At the
  // default 5mm fillet on a 112mm base that left two corner slots cutting
  // 0.8mm out through the rounded corner, with no material between the cut and
  // the outside at all.
  //
  // The test is written in the GRID's frame rather than the base's, because
  // except_slot_pos names grid indices and mountSlots() turns the whole grid
  // over afterwards. The turn is a half turn about an axis lying in the base
  // plane, and both a square base outline and the deliberately symmetric cutter
  // envelope come through it unchanged, so the two frames agree on which slots
  // fit and the indices mean the same thing on either side of the turn.
  slot_band_outline = baseOutline(MIN_SLOT_EDGE_WALL);

  function slotFitsWith(cp, cutter) =
    is_pos_shape_in_region(cp=cp, footprint=slot_footprint, limit_region=[base_outline])
      && is_pos_shape_in_region(cp=cp, footprint=cutter, limit_region=[slot_band_outline]);

  requested_slots = [
    for (i = [0 : units - 1], j = [0 : units - 1])
      if (is_grid_pos_described(i, j, units, units, slotPosition))
        [[i, j], [-(units - i * 2 - 1) * OG_TILE_SIZE / 2, (units - j * 2 - 1) * OG_TILE_SIZE / 2]]
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
  circularBase = baseShape == "Circular";

  // The disc is the cup's own outline where it meets the base - not the sizing
  // diameter, which takes the cup's widest end and would leave the base
  // standing out past the cup as a lip everywhere the cup is narrower.
  disc_diameter = outer_bottom_diameter;

  // The disc is drawn as a Smoothing-sided polygon inscribed in that circle,
  // so its rim sits a hair inside the circle. Fitting mounts against the
  // apothem rather than the radius keeps "inside the base" true of the shape
  // that is actually printed instead of the circle it stands in for.
  fit_radius = disc_diameter / 2 * cos(180 / Smoothing);

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
  mount_reach = ceil((mount_fit_radius + max([for (v = mount_footprint) norm(v)])) / OG_TILE_SIZE);

  // The rule itself: every vertex of the footprint inside mount_fit_radius. The
  // footprint is convex and the disc is convex, so the vertices settle it for
  // the edges between them too - which is also why is_pos_shape_in_region()
  // can test vertices alone on the square base.
  function outlineFits(px, py, outline) =
    len([
      for (v = outline)
        if ((px + v.x) * (px + v.x) + (py + v.y) * (py + v.y)
          > mount_fit_radius * mount_fit_radius) 1
    ]) == 0;

  // A position is supported if it can be cut at all, which on a disc means the
  // trimmed cutter clears the rim; it needs the trim only if the whole one does
  // not. Same order as the square base - whole first, trimmed as the fallback.
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
  // leaving entries whole, which is the same order of preference the square
  // base applies per slot.
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
  // sweep is thousands of offsets, and a square base has no use for it.
  mount_offset = !circularBase || mountAlignment == "Centered" ? [0, 0] : maximalOffset();
  mount_indices = circularBase ? mountIndicesAt(mount_offset) : [];

  function hasMount(i, j) = in_list([i, j], mount_indices);
  function mountPosition(ij) = mountPositionAt(ij, mount_offset);

  // Snap_Placement and Slot_Position, read off the supported positions instead
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

  if (circularBase) {
    assert(len(mount_indices) > 0,
      str("No ", openConnectMount ? "openConnect slot" : "openGrid snap",
        " fits inside a ", disc_diameter, "mm circular base, so the holder would ",
        "have no mount at all. Enlarge the cup holder, or set Base_Shape to Square."));

    assert(len(circular_mounts) > 0,
      str(openConnectMount ? "Slot_Position" : "Snap_Placement", " \"",
        openConnectMount ? slotPosition : snapPlacement,
        "\" selects none of the ", len(mount_indices),
        " supported grid positions on this circular base, so the holder would have ",
        "no mount. Pick another placement, or enlarge the cup holder."));

    echo(str(
      "opengrid_cupholder: circular base, ", disc_diameter, "mm disc, ",
      len(circular_mounts), " of ", len(mount_indices), " supported grid positions mounted",
      approx(mount_offset, [0, 0])
        ? str(", grid centred on a mount",
            mountAlignment == "Maximal" ? " - Maximal found no offset that supports more." : ".")
        : str(", grid offset ", mount_offset, "mm from centred - centring it would support ",
            len(mountIndicesAt([0, 0])), ".")
    ));

    if (cornerRefinementType != "None")
      echo(str(
        "opengrid_cupholder: Corner_Refinement_Type is \"", cornerRefinementType,
        "\", but a disc has no corners to refine, so it is ignored on a circular base."
      ));
  }

  // Everything the openConnect mount needs of the base. These live in the branch
  // rather than carrying a !openConnectMount guard so that a failure reports the
  // condition that actually matters, instead of an implication the reader has to
  // unpick. A statement-position assert only runs when it is reached, so the snap
  // mount never sees them.
  if (openConnectMount) {
    assert(baseThickness >= mount_slot_depth + MIN_BASE_WALL,
      str("Base_Thickness must be at least ", mount_slot_depth + MIN_BASE_WALL,
        "mm for the openConnect mount - ", mount_slot_depth, "mm of openConnect slot plus ",
        MIN_BASE_WALL, "mm of solid floor under it - but it is ", baseThickness,
        "mm. Raise Base_Thickness, or set Mount_Type to Snaps."));

    echo(str(
      "opengrid_cupholder: openConnect mount, ",
      circularBase ? len(circular_mounts) : len(fitted_slots), " slots on a ",
      circularBase
        ? str(disc_diameter, "mm circular base. ")
        : str(units, "x", units, " grid over a ", base_size, "x", base_size, "mm base. "),
      "Each slot takes ", mount_slot_depth, "mm of the ", baseThickness,
      "mm base, leaving ", baseThickness - mount_slot_depth, "mm of floor under the cup.",
      let (trimmed = circularBase ? len(circular_trimmed) : len(trimmed_slots))
        trimmed == 0 ? ""
          : str(" ", trimmed, " of them have ", SLOT_ENTRY_TRIM,
              "mm off the entry so they clear the outside of the base by ",
              MIN_SLOT_EDGE_WALL, "mm; those seat with less room to line the ",
              "connector up, and the rest are untouched.")
    ));

    // Only the square base can drop a slot it asked for: the circular base
    // never asks for one that does not fit, and reports what it supports above.
    if (!circularBase && len(fitted_slots) < len(requested_slots))
      echo(str(
        "opengrid_cupholder: ", len(requested_slots) - len(fitted_slots), " of ",
        len(requested_slots), " slots cannot be cut with ", MIN_SLOT_EDGE_WALL,
        "mm of material left between the cut and the outside of the base, even ",
        "with ", SLOT_ENTRY_TRIM, "mm off the entry, and were dropped. Reduce ",
        "Corner_Refinement_Size, turn Corner_Refinement_Type off, or pick a ",
        "Slot_Position that keeps clear of the corners."
      ));

    assert(circularBase || len(fitted_slots) > 0,
      str("No openConnect slot can be cut with ", MIN_SLOT_EDGE_WALL,
        "mm of material left between the cut and the outside of the base, even ",
        "with ", SLOT_ENTRY_TRIM, "mm off the entry, so the holder would have no ",
        "mount. Reduce Corner_Refinement_Size, turn Corner_Refinement_Type off, ",
        "or enlarge the cup holder."));
  }

  // Cross-section of one slot cutter, drawn across the slot (X) and along it
  // (Y), with Y = 0 at the rim. Both ends are broken by the same refinement:
  // the closed end takes it as a relief cut into the slot, and the rim end
  // takes it negated, which flares the mouth outward as a lead-in for the
  // handle.
  module slotProfile() {
    // Corner order is [X+Y+, X-Y+, X-Y-, X+Y-]: the two Y+ corners are the
    // closed end of the slot, the two Y- corners are the mouth at the rim.
    // A zero refinement has to be handed over as the scalar 0, not as a list
    // of zeros: BOSL2's rect() module tests `rounding==0` to take its plain
    // square path, and an all-zero LIST fails that test, so it calls the rect()
    // function for a rounded path instead - which ignores _return_override on
    // its own all-zero fast path and hands back a bare path where the module
    // expects [points, override]. The module then reads one point as the whole
    // polygon, and the slot cutter is never drawn.
    ends = slot_end_size == 0
      ? 0
      : [slot_end_size, slot_end_size, -slot_end_size, -slot_end_size];
    fwd(slot_overhang) {
      if (handleSlotEndRefinementType == "Chamfer") {
        rect([handleSlotWidth, slot_height + slot_overhang], chamfer=ends, anchor=FRONT);
      } else {
        rect([handleSlotWidth, slot_height + slot_overhang], rounding=ends, anchor=FRONT);
      }
    }
  }

  // Handle slot cutters, in cupBody's local frame: the cup opening is that
  // frame's TOP face, so the slots are measured down from there and reach down
  // toward the base. That frame is never turned over on the way into the
  // finished model, so zrot() here means what it means in the finished model -
  // the angle is measured looking down into the cup, zero on +X, increasing
  // counterclockwise. Emits nothing when slots are switched off, which leaves
  // the cup body exactly as it would be without this feature.
  module handleSlotCutters() {
    $fn = Smoothing;
    if (handleSlotCount > 0 && slot_height > 0 && handleSlotWidth > 0) {
      for (i = [0 : handleSlotCount - 1]) {
        zrot(handleSlotStartAngle + i * 360 / handleSlotCount)
          up(cupHolderHeight / 2)
            // Swing the profile round so it extrudes radially outward from the
            // cup axis - which keeps the slot sides parallel through the wall -
            // and so the profile's mouth end lands at the rim above and its
            // closed end below.
            rotate([-90, 0, -90])
              linear_extrude(height=slot_reach)
                slotProfile();
      }
    }
  }

  // Hollow tapered cup body, attachable so the mount can position it. Built
  // standing the way it is used: the cup opening is the local TOP and the
  // mounting end the local BOTTOM, so the body's own frame already agrees with
  // the finished model's and neither mount has to turn it over. That is what
  // keeps Handle_Slot_Start_Angle meaning the same thing under both mounts -
  // turning the cup end-for-end would reverse its angular sense, and the two
  // mounts would turn it over about different axes.
  module cupBody(anchor, orient, spin) {
    $fn = Smoothing;
    attachable(
      size=[
        max(outer_bottom_diameter, outer_top_diameter),
        max(outer_bottom_diameter, outer_top_diameter),
        cupHolderHeight,
      ],
      anchor=anchor, orient=orient, spin=spin
    ) {
      difference() {
        cyl(h=cupHolderHeight, d1=outer_bottom_diameter, d2=outer_top_diameter);
        up(0.01) cyl(h=cupHolderHeight + 0.02, d1=cupHolderBottomDiameter, d2=cupHolderTopDiameter);
        handleSlotCutters();
      }
      children();
    }
  }

  // Takes SLOT_ENTRY_TRIM off the mouth end of one slot's cutter. Subtracted
  // from the cutter, so it puts material BACK into the base.
  //
  // Written in the cutter's own frame, where zrot(slot_facing) turns the local
  // FRONT onto whichever way this slide direction's mouth faces, so one module
  // serves all four. Bounded on every side rather than left as a half space,
  // because on the square base one grid call draws every slot and an unbounded
  // strip would reach into its neighbours: OG_TILE_SIZE across covers this
  // cutter, which never leaves its own tile, and stops 14mm short of the next
  // tile's centre where the neighbouring cutter's nearest point is 14.996mm
  // away. Along the mouth it runs from the trim line to just past the cutter's
  // own end, well clear of the next tile's cutter 5.8mm further on.
  module entryTrimStrip(cp) {
    translate(cp)
      zrot(slot_facing)
        back(SLOT_CUTTER_BOUNDS[0].y + SLOT_ENTRY_TRIM)
          cuboid(
            [OG_TILE_SIZE, SLOT_ENTRY_TRIM + SLOT_TRIM_OVERRUN, baseThickness * 4],
            anchor=BACK
          );
  }

  // openConnect slots, cut into the board-facing underside of the base - the
  // same face the snaps would stand on, and the reason the grid has to be
  // turned over to get there.
  //
  // The library builds its grid the way a shelf or a plate uses it: wide end
  // at the grid's own BOTTOM, narrowing upward, and the mount face at the
  // grid's TOP with the material below it - see the attach(TOP, TOP,
  // inside=true) in mitufy's own openconnect_plate.scad. This base is the
  // other way up. Its material is ABOVE the face that meets the board, so the
  // grid has to be turned over before it is sunk into the underside, and the
  // grid is anchored by its TOP so the turn swings it about the mouth and
  // leaves that mouth on the board-facing face.
  //
  // Untransformed, the wide end lands at the board face: an open pocket with
  // sloped walls, nothing to capture the connector's flange, and the cutter's
  // excess buried in the slab instead of breaking out through it. Turned, the
  // narrow end is at the face and the retaining lip is left at the mouth,
  // which is what holds the holder on.
  //
  // slot_flip_axis carries the reasoning for turning rather than mirroring,
  // and for turning about the slide axis in particular.
  //
  // Which slots get cut is settled twice over, by the two rules slotFitsWith()
  // spells out: limit_region hands the library its own footprint rule, and
  // except_slot_pos hands it the positions whose cutter would come closer than
  // MIN_SLOT_EDGE_WALL to the outside of the base, which is a rule the library
  // has no way to express. The strips then shorten the entries of the positions
  // that only fit because they are allowed to be shortened - also something the
  // library cannot be asked for, since one grid call draws every slot alike.
  module mountSlots() {
    down(baseThickness / 2)
      rot(180, v=slot_flip_axis)
        difference() {
          openconnect_slot_grid(
            slot_type="slot",
            horizontal_grids=units,
            vertical_grids=units,
            slot_slide_direction=slotSlideDirection,
            slot_position=slotPosition,
            slot_lock_distribution=turned_lock_distribution,
            slot_lock_side=turned_lock_side,
            slot_entryramp_flip=slotEntryRampFlip,
            limit_region=[base_outline],
            except_slot_pos=dropped_slots,
            excess_thickness=EPS,
            anchor=TOP
          );
          for (cp = trimmed_slots) entryTrimStrip(cp);
        }
  }

  // openConnect base: the same footprint and corner refinement the snap facade
  // draws, with nothing standing off it, and the slot grid cut into the face
  // that meets the board.
  module openConnectBase(anchor, orient, spin) {
    $fn = Smoothing;
    attachable(size=[base_size, base_size, baseThickness], anchor=anchor, orient=orient, spin=spin) {
      difference() {
        cuboid(
          [base_size, base_size, baseThickness],
          rounding=(cornerRefinementType == "Fillet" ? cornerRefinementSize : 0),
          chamfer=(cornerRefinementType == "Chamfer" ? cornerRefinementSize : 0),
          edges="Z"
        );
        mountSlots();
      }
      children();
    }
  }

  // openConnect slots for a circular base. openconnect_slot_grid() always
  // centres a whole number of tiles on the model, so it can neither be offset
  // nor thinned down to a circle - but a one-by-one grid is a single slot at
  // the origin, and moving one of those into place says the same thing. It is
  // the same call the square base makes, and it produces geometry identical to
  // a slot in the middle of a larger grid: the library clips its slots to the
  // whole grid rather than to their own tiles, and a slot never reaches past
  // its own tile in the first place.
  //
  // Turned over the same way and for the same reason as mountSlots(), but from
  // inside the translate, so each slot swings about its own mouth and the
  // mounts stay exactly where mountPosition() put them. That is also why this
  // one has no turned_lock_distribution to apply: nothing here is picked out
  // by row, so the turn has no row to carry across.
  module circularMountSlots() {
    locked = selectedMounts(slotLockDistribution);
    down(baseThickness / 2)
      for (ij = circular_mounts)
        let (p = mountPosition(ij))
          translate(p)
            rot(180, v=slot_flip_axis)
              difference() {
                openconnect_slot_grid(
                  slot_type="slot",
                  horizontal_grids=1,
                  vertical_grids=1,
                  slot_slide_direction=slotSlideDirection,
                  slot_position="All",
                  slot_lock_distribution=in_list(ij, locked) ? "All" : "None",
                  slot_lock_side=turned_lock_side,
                  slot_entryramp_flip=slotEntryRampFlip,
                  excess_thickness=EPS,
                  anchor=TOP
                );
                if (mountNeedsTrim(p.x, p.y)) entryTrimStrip([0, 0]);
              }
  }

  // Circular openConnect base: the disc under the cup with nothing standing
  // off it, and the slots cut into the face that meets the board. Same shape
  // and same frame as openConnectBase(), so the render below can hand either
  // one the cup without knowing which it has.
  module circularOpenConnectBase(anchor, orient, spin) {
    $fn = Smoothing;
    attachable(size=[disc_diameter, disc_diameter, baseThickness], anchor=anchor, orient=orient, spin=spin) {
      difference() {
        cyl(h=baseThickness, d=disc_diameter);
        circularMountSlots();
      }
      children();
    }
  }

  // Circular snap base: the same disc, with openGrid snaps standing off it.
  // openGridFacade() draws its slab and its snaps together and has no way to
  // be told about a round outline or an offset grid, so the disc places its
  // own snaps - by the same attach(TOP, TOP) the facade uses, so a snap here
  // is the facade's snap the facade's way up. Built the facade's way round
  // too: the snaps stand off the local TOP and the render below turns the
  // whole thing over, which is what keeps the two snap paths interchangeable.
  module circularSnapBase(anchor, orient, spin) {
    $fn = Smoothing;
    snap_thickness = liteSnap ? 3.4 : 6.8;
    total_thickness = baseThickness + snap_thickness;
    attachable(size=[disc_diameter, disc_diameter, total_thickness], anchor=anchor, orient=orient, spin=spin) {
      down(total_thickness / 2)
        cyl(h=baseThickness, d=disc_diameter, anchor=BOTTOM) {
          for (ij = circular_mounts)
            color("lightblue")
              translate(mountPosition(ij))
                attach(TOP, TOP)
                  openGridSnap(lite=liteSnap);
        }
      children();
    }
  }

  // Render: the base resting on the Z = 0 plane, board-facing side down, with
  // the cup standing on top of it. cupBody already stands the right way up, so
  // both mounts only ever move it - position() places it and nothing rotates
  // it. Do not reach for attach() here: mating the cup to a face by anchor
  // would turn it over to meet that face, and the two mounts present opposite
  // faces, so each would turn it over differently and Handle_Slot_Start_Angle
  // would come out mirrored, and mirrored differently per mount.
  // The 0.1 in each branch is overlap into the base, so the cup and the base
  // share a volume rather than meeting across a face.
  if (openConnectMount && circularBase) {
    circularOpenConnectBase(anchor=BOTTOM)
      position(TOP) down(0.1) cupBody(anchor=BOTTOM);
  } else if (openConnectMount) {
    openConnectBase(anchor=BOTTOM)
      position(TOP) down(0.1) cupBody(anchor=BOTTOM);
  } else if (circularBase) {
    // Both snap bases draw their snaps on their own TOP, so the base is turned
    // over to put them against the board; the cup then stands on what is now
    // its upper face, and the snap tips land on Z = 0 like the openConnect
    // base does. Everything inside that xrot(180) is upside down, the cup
    // included, so the cup gets an xrot(180) of its own to cancel it and stand
    // up again. The square snap branch below reads the same way, and for the
    // same reason.
    xrot(180) circularSnapBase(anchor=TOP)
      position(BOTTOM) xrot(180) down(0.1) cupBody(anchor=BOTTOM);
  } else {
    xrot(180) openGridFacade(
      xUnits=units,
      yUnits=units,
      facadeThickness=baseThickness,
      cornerRefinementType=cornerRefinementType,
      cornerRefinementSize=cornerRefinementSize,
      liteSnap=liteSnap,
      includeCornerSnaps=true,
      includeEdgeSnaps=(snapPlacement == "All" || snapPlacement == "Edges"),
      includeInternalSnaps=(snapPlacement == "All"),
      topCornerDirectionalSnaps=false,
      topEdgeDirectionalSnaps=false,
      anchor=TOP
    )
      position(BOTTOM) xrot(180) down(0.1) cupBody(anchor=BOTTOM);
  }
}
