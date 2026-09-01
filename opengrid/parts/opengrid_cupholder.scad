/*
  opengrid_cupholder.scad

  A cup holder that mounts to an openGrid board through a flat base, with
  optional handle slots cut through the wall so mugs with handles can sit in it.

  The base is opengrid_mount_base.scad, which is where both mounts, both base
  shapes and every rule about which grid positions can carry a mount live. This
  file is the cup, the handle slots, and the sizing that decides how big a base
  the cup needs. Read that file for the mount itself; what follows is only what
  is particular to standing a cup on one.

  The model stands the way it is used: the base sits on the Z = 0 plane with
  its board-facing side down, and the cup opens upward above it.

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

  ---------------------------------------------------------------------------
  Base size and shape

  The base is a square slab by default: a whole number of 28mm grid units on
  each side, sized up to cover the cup. Base_Shape = "Circular" drops the slab
  and leaves the cup's own outline as the whole base, so the holder carries no
  material the cup does not stand on and nothing stands out past the cup.

  The disc is the cup's outer diameter where it meets the base, so a cup that
  flares upward - the default - overhangs its own base rather than sitting on
  a lip. Size_Base_Units_To_Bottom_Diameter has nothing to choose here: it
  sizes the square base's grid, and a disc is the base end's diameter either
  way.

  Those two numbers - how many whole units a square base needs, and how wide
  the disc is - are the whole of this file's say in the base. Which positions
  end up carrying a mount, whether a corner refinement costs a slot its entry,
  and where the grid falls under a disc are all settled by
  opengrid_mount_base.scad, which reports what it did.

  Corner_Refinement_Type and Corner_Refinement_Size are square-base settings; a
  disc has no corners. On a square base a refinement that reaches into a corner
  tile costs that corner's slot its full entry first and then, if it reaches
  far enough, the slot itself.

  ---------------------------------------------------------------------------
  Licensing

  The cup holder geometry in this file is original work by zing3d-labs and is
  licensed under the repository license, CC BY-NC-SA 4.0 (see ../../LICENSE).

  Both mounts come in through opengrid_mount_base.scad, which carries the
  licensing note for them - mitufy's openConnect connector library (CC BY 4.0)
  and QuackWorks' openGrid snap (CC BY-NC-SA 4.0). Nothing here depends on
  either directly.
  ---------------------------------------------------------------------------
*/

include <BOSL2/std.scad>
use <opengrid_mount_base.scad>

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
  slotEntryRampFlip=Slot_Entry_Ramp_Flip
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
  units = ceil(sizing_diameter / openGridMountTileSize());

  circularBase = baseShape == "Circular";

  // The disc is the cup's own outline where it meets the base - not the sizing
  // diameter, which takes the cup's widest end and would leave the base
  // standing out past the cup as a lip everywhere the cup is narrower.
  disc_diameter = outer_bottom_diameter;

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

  // The one thing both mounts need of the base, asserted here rather than left
  // to the base so that the message names the variable the user can reach. How
  // thin is thin enough is a printing question rather than a modelling one, and
  // is left to the user - but zero is not thin, it is absent: the slab vanishes
  // and the cup meets the snaps across a plane of no thickness, which renders
  // without complaint and cannot be printed at all.
  assert(baseThickness > 0,
    str("Base_Thickness must be greater than zero - it is ", baseThickness,
      "mm, which leaves no base for the cup to stand on."));

  // Stated here as well as in the base for the same reason: openGridMountBase()
  // asserts the same minimum, but in terms of its own parameter, and this is
  // the message that names Base_Thickness and the way out of it. A
  // statement-position assert only runs when it is reached, so the snap mount
  // never sees this one.
  if (mountType == "openConnect")
    assert(baseThickness >= openGridMountMinThickness(),
      str("Base_Thickness must be at least ", openGridMountMinThickness(),
        "mm for the openConnect mount - ", openGridMountSlotDepth(),
        "mm of openConnect slot plus ", openGridMountMinBaseWall(),
        "mm of solid floor under it - but it is ", baseThickness,
        "mm. Raise Base_Thickness, or set Mount_Type to Snaps."));

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

  // Render: the base resting on the Z = 0 plane, board-facing side down, with
  // the cup standing on top of it. openGridMountBase() presents the same TOP
  // whichever mount and shape it was asked for - the snaps hang below it, not
  // off it - so there is one branch here where there used to be four, and
  // cupBody already stands the right way up, so nothing rotates it.
  //
  // Do not reach for attach() here: mating the cup to a face by anchor would
  // turn it over to meet that face, and Handle_Slot_Start_Angle would come out
  // mirrored. position() moves the cup without turning it.
  //
  // The 0.1 is overlap into the base, so the cup and the base share a volume
  // rather than meeting across a face.
  openGridMountBase(
    baseShape=circularBase ? "Circular" : "Rectangular",
    xUnits=units,
    yUnits=units,
    diameter=disc_diameter,
    mountAlignment=mountAlignment,
    thickness=baseThickness,
    mountType=mountType,
    cornerRefinementType=cornerRefinementType,
    cornerRefinementSize=cornerRefinementSize,
    liteSnap=liteSnap,
    snapPlacement=snapPlacement,
    slotSlideDirection=slotSlideDirection,
    slotPosition=slotPosition,
    slotLockDistribution=slotLockDistribution,
    slotLockSide=slotLockSide,
    slotEntryRampFlip=slotEntryRampFlip,
    anchor=BOTTOM
  )
    position(TOP) down(0.1) cupBody(anchor=BOTTOM);
}
