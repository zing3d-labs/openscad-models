/*
  opengrid_block.scad

  A plain block that mounts to an openGrid board: a whole number of 28mm grid
  units in each direction, a chosen height tall, with an optional fillet or
  chamfer down its vertical corners.

  It is the mounting base of opengrid_mount_base.scad with nothing added but
  height, so it inherits both mounts, every placement option, and the frame -
  board-facing side down, material above. Read that file for the mount itself.

  ---------------------------------------------------------------------------
  What it is for

  A block is a spacer, a riser, a foot, a bumper - and, the reason it was
  written, a STOP.

  An openConnect part mounts by sliding along the board in one direction, which
  means it unmounts by sliding back the other way. On a vertical wall gravity
  holds a part seated. On a HORIZONTAL board nothing does: the slots' lock nubs
  are a detent, not a retainer, so bumping a part hard enough in the unmount
  direction can slide it right off the connectors. A full cup coming off a
  desk-mounted holder is the failure this prevents.

  Seat a block in the grid spot next to the part, on the side the part unmounts
  toward. The part can no longer travel that way, so it cannot come off until
  the block is lifted out.

  ---------------------------------------------------------------------------
  Why a block in the next spot is enough

  A part has to travel openGridMountSlotReleaseTravel() - 10.6mm at the
  library's own defaults - to get from seated to released. That is the number
  the gap has to beat, and it is a generous one.

  A part sized to whole grid units ends flush with the tile boundary, and so
  does a block in the next spot along, so the two meet with no gap at all. Even
  a part whose outline stops short of its tile boundary has 17.4mm of slack
  before a 28mm-pitch neighbour is too far away to catch it. The block does not
  need to touch to work; it needs to be closer than the release travel.

  ---------------------------------------------------------------------------
  How tall it has to be

  Tall enough that its face catches the side of the part's base rather than
  passing under or over it.

  Both parts sit their board-facing face on the same plane - the board's outer
  surface - so a block of height H overlaps its neighbour's base over the
  smaller of H and that base's thickness. The neighbour's thickness is not a
  guess: an openConnect base cannot be thinner than
  openGridMountMinThickness(), 3.5mm, being 2.7mm of slot plus 0.8mm of floor
  under it, or it would have nowhere to put the slot. So a block at least that
  tall makes FULL-face contact with any openConnect-mounted part there is,
  whatever else about it is unknown.

  The default of 8mm is that minimum with room to spare, chosen for the hand
  rather than for the geometry: a block has to be pinched and lifted out, and
  8mm gives something to hold. Nothing needs tools, and nothing is captive.

  Measured rather than argued, against the cup holder at its shipped defaults -
  a 4-unit base sliding "Up", with a default block in the next spot at y = 70,
  both placed by their "board" anchor so they share one board surface:

      slide 0.0mm   no contact - the two do not foul each other when seated
      slide 0.1mm   contact over 28 x 0.1 x 4.0mm
      slide 10.6mm  contact over 28 x 10.6 x 4.0mm

  So the block catches the cup from the first tenth of a millimetre of travel,
  across its own full width and the full 4mm thickness of the cup's base, and
  the cup never reaches the 10.6mm it needs. The check is worth stating in that
  order because it can fail either way: a block too short would show a contact
  height below the base thickness, and one that fouled the cup when seated
  would show contact at slide 0.

  ---------------------------------------------------------------------------
  Why it mounts by snaps by default

  A stop is a part whose whole job is to be shoved. The load is a bump in the
  plane of the board, so what matters is how the block resists sliding, not how
  it resists being pulled off.

  A snap takes that load in bearing against the walls of the tile it fills. It
  cannot slide anywhere - the only way out is straight off the board, which is
  the one direction the bump does not push, and the direction the snap's own
  retention is built for.

  An openConnect block is held by slots of its own, and slots release along an
  axis. If that axis lines up with the bump, the bump drives the block off and
  the part follows it. So openConnect is offered, but if you use it, point
  Slot_Slide_Direction ACROSS the direction the blocked part pushes, never
  along it - and prefer snaps, which have no such axis to get wrong.

  ---------------------------------------------------------------------------
  Breaking the edges

  Two refinements, and they answer to different things.

  Corner_Refinement_* breaks the VERTICAL corners - the four upright arrises
  where the sides meet. Top_Edge_Refinement_* breaks the horizontal edges
  around the TOP face.

  The top edge is the free one. Nothing stands on a block and nothing mounts to
  its top, so a break there costs nothing on either mount and is worth having
  on a part that gets pinched and lifted out by hand. It is on by default, at
  1mm. It never eats into the blocking face either: the break is taken out of
  the top, so the side keeps its full height under it, and a block's contact
  with its neighbour is set by the neighbour's base thickness rather than by
  the block's own height anyway.

  The vertical corners are the costly ones on an openConnect block:
  the cut already comes within 0.8mm of the outside along every edge row, so
  there is nothing to give. On a one-by-one block a fillet is absorbed by
  shortening the slot's entry, which is why this file leaves the refinement off
  by default rather than inheriting a size that suits a larger base. Turn it on
  and the base will say in an echo what it cost. A snap block has no such
  constraint - the snaps stand off the face rather than cutting into it - so a
  refinement there is free.

  ---------------------------------------------------------------------------
  Licensing

  The block geometry in this file is original work by zing3d-labs and is
  licensed under the repository license, CC BY-NC-SA 4.0 (see ../../LICENSE).

  Both mounts come in through opengrid_mount_base.scad, which carries the
  licensing note for them - mitufy's openConnect connector library (CC BY 4.0)
  and QuackWorks' openGrid snap (CC BY-NC-SA 4.0). Nothing here depends on
  either directly.
  ---------------------------------------------------------------------------
*/

include <BOSL2/std.scad>
use <opengrid_mount_base.scad>

/* [Block] */

// openGrid units across the block, in X
Units_X = 1; // [1:1:12]

// openGrid units across the block, in Y
Units_Y = 1; // [1:1:12]

// How tall the block is, in mm - how far it stands out from the board. Snaps
// go into the board rather than out from it, so this never includes them and
// means the same thing under either mount. Anything at least 3.5mm makes full-face contact with an
// openConnect-mounted neighbour; the default is that with room to grip.
Height = 8;

// How to adjust the vertical corners for visual appeal. On an openConnect
// block this costs the slot its full entry, and on a small one it can cost the
// slot itself, so it starts switched off - see the header.
Corner_Refinement_Type = "None"; // [None, Chamfer, Fillet]

// Measurement for the selected corner refinement, in mm
Corner_Refinement_Size = 2; // [0.5:0.5:20]

// How to break the edges around the top face. Free on either mount - the top
// of a block is the one face nothing needs - and worth having on a part that
// gets picked up by hand. The blocking face keeps its full height below it.
Top_Edge_Refinement_Type = "Fillet"; // [None, Chamfer, Fillet]

// Measurement for the selected top edge refinement, in mm
Top_Edge_Refinement_Size = 1; // [0.5:0.5:20]

/* [Mount] */

// How the block attaches to the board. Snaps click into the tiles directly and
// cannot slide anywhere, which is what a stop wants. openConnect slides onto
// connectors screwed into the tiles, and so has a release axis of its own to
// keep clear of the bump - see the header.
Mount_Type = "Snaps"; // [Snaps, openConnect]

/* [Snap Mount] */

// Version of the tile, Full (6.8mm) or Lite (3.4mm)
Grid_Type = "Lite"; // [Full,Lite]

// Which grid positions carry a snap. On a one-by-one block every position is a
// corner, so all three settings come out the same.
Snap_Placement = "All"; // [All, Edges, Corners]

/* [openConnect Mount] */

// Direction the block slides to come off its own connectors, in the model's
// own axes: "Right" is +X, "Left" is -X, "Up" is +Y, "Down" is -Y.
//
// Point this ACROSS the direction the blocked part pushes, never along it. A
// block that releases the same way it is shoved is a block that leaves with
// the part.
Slot_Slide_Direction = "Up"; // [Up, Down, Left, Right]

// Which grid positions get a slot. A slot costs nothing to print, so cutting
// all of them keeps every board position usable.
Slot_Position = "All"; // [All, Staggered, Edge Rows, Edge Columns, Corners]

// Which slots get the locking nub - the detent that stops the block sliding
// back off its connectors.
Slot_Lock_Distribution = "All"; // [All, Staggered, Corners, Top Corners, Bottom Corners, None]

// Side of the slot the locking nubs sit on
Slot_Lock_Side = "Left"; // [Left, Right]

// Flip the slot entry ramp, which changes which way its overhangs face
Slot_Entry_Ramp_Flip = false;

/* [Misc] */

// Value of $fn for curves on the design
Smoothing = 40; // [10:10:300]

openGridBlock(
  xUnits=Units_X,
  yUnits=Units_Y,
  height=Height,
  cornerRefinementType=Corner_Refinement_Type,
  cornerRefinementSize=Corner_Refinement_Size,
  topEdgeRefinementType=Top_Edge_Refinement_Type,
  topEdgeRefinementSize=Top_Edge_Refinement_Size,
  mountType=Mount_Type,
  liteSnap=(Grid_Type == "Lite"),
  snapPlacement=Snap_Placement,
  slotSlideDirection=Slot_Slide_Direction,
  slotPosition=Slot_Position,
  slotLockDistribution=Slot_Lock_Distribution,
  slotLockSide=Slot_Lock_Side,
  slotEntryRampFlip=Slot_Entry_Ramp_Flip,
  $fn=Smoothing
);

module openGridBlock(
  xUnits = 1,
  yUnits = 1,
  height = 8,
  cornerRefinementType = "None",
  cornerRefinementSize = 2,
  topEdgeRefinementType = "Fillet",
  topEdgeRefinementSize = 1,
  mountType = "Snaps",
  liteSnap = true,
  snapPlacement = "All",
  slotSlideDirection = "Up",
  slotPosition = "All",
  slotLockDistribution = "All",
  slotLockSide = "Left",
  slotEntryRampFlip = false,
  anchor,
  orient,
  spin
) {
  // How much of an openConnect-mounted neighbour's base this block's face
  // covers. The neighbour's base is at least openGridMountMinThickness() thick
  // - the slot depth plus the floor under it - so a block that tall or taller
  // meets it across its whole side. Reported rather than asserted: a shorter
  // block still blocks, it just catches less of what it is blocking, and how
  // much is enough is a question about the bump rather than about the model.
  neighbour_min_base = openGridMountMinThickness();
  contact = min(height, neighbour_min_base);

  echo(str(
    "opengrid_block: ", xUnits, "x", yUnits, " block standing ", height,
    "mm tall. As a stop it catches ", contact, "mm of a ",
    "neighbouring part's base",
    height >= neighbour_min_base
      ? str(" - the full ", neighbour_min_base,
          "mm an openConnect base is at least, so full-face contact with any of them.")
      : str(", short of the ", neighbour_min_base,
          "mm an openConnect base is at least, so it catches only part of one. ",
          "Raise Height to ", neighbour_min_base, "mm or more for full-face contact."),
    " A part needs ", openGridMountSlotReleaseTravel(),
    "mm of travel to release, so a block anywhere inside that of it is close ",
    "enough - which the next grid spot along always is."
  ));

  // Everything else is the mounting base. A block adds height and nothing
  // whatever to how the base meets the board, so there is nothing here to do
  // but pass the parameters through and let it report what it did.
  openGridMountBase(
    baseShape="Rectangular",
    xUnits=xUnits,
    yUnits=yUnits,
    thickness=height,
    mountType=mountType,
    cornerRefinementType=cornerRefinementType,
    cornerRefinementSize=cornerRefinementSize,
    topEdgeRefinementType=topEdgeRefinementType,
    topEdgeRefinementSize=topEdgeRefinementSize,
    liteSnap=liteSnap,
    snapPlacement=snapPlacement,
    slotSlideDirection=slotSlideDirection,
    slotPosition=slotPosition,
    slotLockDistribution=slotLockDistribution,
    slotLockSide=slotLockSide,
    slotEntryRampFlip=slotEntryRampFlip,
    anchor=anchor, orient=orient, spin=spin
  ) children();
}
