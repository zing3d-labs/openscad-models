/*
  opengrid_adapter.scad

  A plate that mounts to openGrid on its back and carries another system's
  connectors on its front, so a part made for that system hangs on an openGrid
  wall. The case it was made for is a part built for Multiboard - Multiconnect
  slots on a 25mm pitch - moved onto openGrid, which is 28mm:

      back   openConnect slots, onto openConnect connectors screwed into the
             board. Or openConnect studs, or openGrid snaps: the back is
             opengrid_mount_base.scad and offers what that offers.
      front  Multiconnect studs, for the part's Multiconnect slots to slide
             onto. Or Multiconnect slots, Multiboard threaded holes or snap
             holes, openConnect studs, openGrid snaps, or nothing at all.

  ---------------------------------------------------------------------------
  Two grids in one outline

  25 and 28 never line up, so neither face is laid out from the other. Each
  counts in its own units on its own pitch - the back in 28mm openGrid tiles,
  the front in the front system's pitch - and the plate is whatever outline
  holds both.

  A count of 0 is Auto: as many as fit. Give the side you care about and leave
  the other on Auto:

      front 3x3 Multiconnect, back Auto  ->  75x75mm, a 2x2 of openConnect slots
      back 3x3,               front Auto ->  84x84mm, a 3x3 of Multiconnect studs
      front 1x1 Multiconnect, back Auto  ->  28x28mm, one slot (see below)
      both given                         ->  both as given
      both Auto on one axis              ->  refused: neither side says how big

  An Auto back is as many mounts as fit within the front's footprint, by the
  mount base's own fit rules (openGridMountAutoUnits()) - and never fewer than
  one, since a plate that cannot mount is no plate. An Auto front is as many
  whole front cells as fit the back's tiles. Each axis is settled on its own,
  so the two faces can trade: an Auto back across and an Auto front down is a
  well-formed plate.

  Worked through for openConnect slots behind Multiconnect, on the slot's real
  cutter (26.0mm across the slide, 0.8mm of edge wall either side):

      Multiconnect columns   part width   openConnect columns
              1                 25mm        0 - the slot alone is wider
              2                 50mm        1
              3                 75mm        2
              4                100mm        3
              5                125mm        4

  Along the slide a slot needs less - its footprint reaches 11mm either way of
  centre, its trimmed cutter 10.2mm plus the wall - so 75mm takes 2 rows, and a
  third misses by 1.5mm.

  A one-column part, which is most hooks, cannot be backed within its own
  width. That is why the outline is not the front's footprint but the
  smallest rectangle holding both footprints: Auto gives the back its one slot
  anyway, and the plate comes out 28mm wide, a whole tile, with the 25mm
  front centred on it. No special case does that; it is the same rule.

  Footprints are whole cells. The back's is its tiles, xUnits x 28mm by yUnits
  x 28mm, which is the slab the mount base would draw for that grid on its
  own. The front's is its cells, columns x pitch by rows x pitch: a 20mm
  Multiconnect flange in a 25mm cell keeps 2.5mm of plate round it, which is
  the edge wall the front needs.

  Width and Height (mm, 0 = from the footprints) override the outline. They
  can make the plate bigger, never smaller than what it carries - a size that
  leaves either face hanging over the edge is refused, naming the face.

  ---------------------------------------------------------------------------
  Alignment

  Front_Align_X (Center, Left, Right) and Front_Align_Y (Center, Top, Bottom)
  place the front's footprint against the back's - Left lines up their left
  edges - and Front_Offset_X/Y move it on from there in mm. The outline then
  grows to hold both wherever they ended up.

  Alignment decides where the part hangs on the board, never whether it fits:
  the counts are settled first, from footprint sizes alone, and only then
  placed.

  ---------------------------------------------------------------------------
  Frame and directions

  The plate is built board side DOWN, as the mount base is, so the front is
  the TOP face and its connectors stand up off it or cut down into it. The
  model's +Y is up the wall when the back slides "Up" off its connectors,
  which is the usual hanging; +X is then to the right, seen from the front.
  Every direction name below is those axes, as in the mount base.

  ---------------------------------------------------------------------------
  The front connectors

  Multiconnect Studs - the head of a Multiconnect connector, standing on the
    front for a Multiconnect part's slots to slide over. The head is mitufy's
    multiconnect_head(), redrawn here from the same primitives and checked
    identical to it (see openGridAdapterMulticonnectHead() for why it is not
    simply called). The library builds it the way a screw presents it - wide
    flange at the bottom, the narrow neck uppermost. Here the neck has to meet
    the plate and the flange stand outermost, so the head is turned over. It
    is round, so turning and mirroring would agree; it is turned anyway, the
    same way openGridMountStud() turns the openConnect head. The pattern on its
    face - Dimple, Coin Slot or None - is the library's choice of the same
    name. Dimple is the default: it is what a v1 Multiconnect slot's detent
    clicks into, it costs a v2 slot nothing, and a coin slot is for turning a
    screw, which a printed stud never is.

  Multiconnect Slots - the other way round: channels cut into the front, for
    a part carrying Multiconnect heads to hang on. The cross-section, the round
    closed end, the on-ramps and the v2 snap ridges are QuackWorks'
    multiConnectSlotTool() exactly (see MULTICONNECT_SLOT_PROFILE), drawn here
    rather than called because that module reads its pitch, tolerance and
    version from its own file's Customizer and cannot be handed a pitch.

    On a Multiconnect part the channel runs DOWN from a closed top, because
    the part drops onto heads fixed to the board. Here the heads are on the
    part and the channels on the fixed side, so it is the other way up: the
    heads drop in through the on-ramps and slide down onto the closed end. In
    general the closed end is at the end Front_Slide_Direction points away
    from - that being the way the hung part slides to come OFF - and the
    channel reaches to half a cell past the last row in that direction, where
    the last on-ramp is. A channel runs through every row of its line, so the
    placement pattern picks lines rather than cells: a line is cut when the
    pattern selects any cell in it.

  openConnect Studs - openGridMountStud(), the mount base's stud, on the 28mm
    grid, for a part with openConnect slots. Front_Slide_Direction is the way
    that part slides to come off, the same word its slots were cut with.

  openGrid Snaps - QuackWorks openGridSnap(), as the mount base uses for its
    own snaps, so the front clicks into an openGrid tile. Full or Lite.

  Multiboard Large, Mid and Small Thread Holes - threaded holes cut into the
    front, for a Multiconnect post, a bolt or anything else carrying one of
    Multiboard's three threads to screw into. Each is the thread itself made
    0.25mm larger across, with its teeth cut back to a tip diameter and a
    45-degree lead-in at the mouth; see MULTIBOARD_THREAD_LARGE and below.
    The large and small are the threads of a tile's two holes. A tile has no
    mid holes - the mid thread is what screws into a snap's centre - but a
    mid hole on the front takes the same mid-thread posts. Thread_Depth is
    how far the hole goes in, 6.4mm by default, a tile's thickness: a post
    with a longer thread would bottom out in that, so give it more.

  Multiboard Snap Holes - a tile's large hole, without the thread by default,
    for a Multiboard snap, or a part with one built in, to click into. The
    adapter makes the hole only; the snap is the hung part's. Its octagon
    narrows from the face to a band the snap's body passes through, then
    widens again behind it for the snap's bumps to catch on - see
    MULTIBOARD_SNAP_HOLE_PROFILE. Snap_Hole_Thread cuts the large thread into
    it as well, as a tile has it, so the same hole also takes a large-thread
    post. A snap hole is always a tile's 6.4mm deep, whatever Thread_Depth
    says: it is the depth the snap was made for.

  None - a plain plate, for a part that will be glued or screwed on.

  The openGrid types are on the 28mm grid whatever Front_Pitch says; it is the
  Multiconnect types that come in other pitches (QuackWorks' parts take a
  distanceBetweenSlots), and the Multiboard ones are on the same grid, so only
  they read it.

  ---------------------------------------------------------------------------
  Thickness

  Thickness is the slab, as on the mount base. Cuts come in from both faces -
  openConnect slots from the back; Multiconnect slots and Multiboard holes
  from the front - and two cuts that met would leave a hole straight through.
  A plate whose cuts could meet is therefore built thicker: back cut, front
  cut and the mount base's floor wall between them. Studs and snaps cut
  nothing. The cuts are not placed to miss each other; they are kept apart in
  depth, which holds wherever alignment puts them. Raising it is reported,
  never silent.

  ---------------------------------------------------------------------------
  Licensing

  The adapter geometry in this file is original work by zing3d-labs and is
  licensed under the repository license, CC BY-NC-SA 4.0 (see ../../LICENSE).

  The back is opengrid_mount_base.scad, which carries its own notes: mitufy's
  openConnect connector library (CC BY 4.0) and QuackWorks' openGrid snap.

  The Multiconnect head is redrawn from mitufy's snap and connector generator
  (external/opengrid-projects/opengrid_parametric_snap.scad), which the
  project's README licenses CC BY 4.0 along with the connector libraries - not
  one of the CC BY-SA holder or gadget generators, which this file must not
  derive from, for the reason given in the mount base.

      openConnect / openGrid connector libraries
      Created by mitufy - https://github.com/mitufy

  The Multiconnect slot's profile, ridges and on-ramps are QuackWorks'
  (external/QuackWorks/VerticalMountingSeries/MulticonnectBin.scad), by Andy
  Levesque, CC BY-NC-SA 4.0 - the license this repository uses, so the
  dependency carries no additional terms.

  Multiconnect is created by David D, and Multiboard by Jonathan at Keep
  Making. openGrid is created by David D:
      https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
  ---------------------------------------------------------------------------
*/

// Brings in BOSL2 (via lib/opengrid_base.scad) along with the OG_ constants
// and is_grid_pos_described(), so no separate BOSL2 include - except for
// threading, which the library only reaches through a use and so leaves out
// of scope here.
include <../../external/opengrid-projects/lib/openconnect_lib.scad>
include <BOSL2/threading.scad>
use <opengrid_mount_base.scad>
use <../../external/QuackWorks/openGrid/opengrid-snap.scad>

/* [Back] */

// How the back mounts to the board, as on opengrid_mount_base.scad.
// openConnect slots slide onto connectors screwed into the tiles; snaps click
// into the tiles directly; studs are for a slotted face rather than a board.
Back_Mount_Type = "openConnect"; // [openConnect:openConnect Slots, openConnect Studs, Snaps]

// openGrid units across the back, in X. 0 is Auto: as many as fit behind the
// front.
Back_Units_X = 0; // [0:1:12]

// openGrid units across the back, in Y. 0 is Auto.
Back_Units_Y = 0; // [0:1:12]

/* [Back: openConnect] */

// Direction the plate slides to come off the connectors: "Up" is +Y, "Right"
// is +X. On a wall, Up - gravity then holds it seated.
Slot_Slide_Direction = "Up"; // [Up, Down, Left, Right]

// Which grid positions get a slot
Slot_Position = "All"; // [All, Staggered, Edge Rows, Edge Columns, Corners]

// Which slots get the locking nub
Slot_Lock_Distribution = "All"; // [All, Staggered, Corners, Top Corners, Bottom Corners, None]

// Side of the slot the locking nubs sit on - see opengrid_mount_base.scad
Slot_Lock_Side = "Left"; // [Left, Right]

// Flip the slot entry ramp, which changes which way its overhangs face
Slot_Entry_Ramp_Flip = false;

/* [Back: Snaps] */

// Version of the tile the back snaps into, Full (6.8mm) or Lite (3.4mm)
Grid_Type = "Lite"; // [Full,Lite]

// Which grid positions carry a snap
Snap_Placement = "Corners"; // [All, Edges, Corners]

/* [Front] */

// What the front carries, for the part that hangs on it
Front_Mount_Type = "Multiconnect Studs"; // [Multiconnect Studs, Multiconnect Slots, Multiboard Large Thread Holes, Multiboard Mid Thread Holes, Multiboard Small Thread Holes, Multiboard Snap Holes, openConnect Studs, openGrid Snaps, None]

// Front cells across, in X. 0 is Auto: as many as fit the back.
Front_Columns = 3; // [0:1:16]

// Front cells down, in Y. 0 is Auto.
Front_Rows = 3; // [0:1:16]

// Which front cells carry a connector. Multiconnect slots run the length of a
// line of cells, so for them this picks the lines.
Front_Position = "All"; // [All, Staggered, Edge Rows, Edge Columns, Corners]

// Front cell pitch in mm. 0 is the system's own: 25 for Multiconnect and
// Multiboard. The openGrid types are always 28 and ignore this.
Front_Pitch = 0; // [0:0.5:40]

// Direction the hung part slides to come OFF the front, for Multiconnect slots
// and openConnect studs: "Up" is +Y. Up, on a wall.
Front_Slide_Direction = "Up"; // [Up, Down, Left, Right]

/* [Front: Multiconnect] */

// Pattern on the outer face of a Multiconnect stud
Multiconnect_Head_Pattern = "Dimple"; // [Dimple, Coin Slot, None]

/* [Front: Multiboard] */

// How deep a threaded hole goes into the plate, in mm. 6.4 is a Multiboard
// tile's thickness; go deeper for a post with a longer thread. The slab is
// raised, and says so, to keep its floor behind the hole.
Thread_Depth = 6.4; // [1:0.1:30]

// Cut Multiboard's large thread into the snap holes as well, as a tile has
// it, so a large-thread post screws into the same hole a snap clicks into.
Snap_Hole_Thread = false;

/* [Front: openGrid Snaps] */

// Version of the tile the front snaps into, Full (6.8mm) or Lite (3.4mm)
Front_Grid_Type = "Lite"; // [Full,Lite]

/* [Outline] */

// Where the front sits across the back: Left lines up their left edges
Front_Align_X = "Center"; // [Center, Left, Right]

// Where the front sits up and down the back: Top lines up their top edges
Front_Align_Y = "Center"; // [Center, Top, Bottom]

// Moves the front on from its alignment, in mm. +X is right.
Front_Offset_X = 0;

// Moves the front on from its alignment, in mm. +Y is up.
Front_Offset_Y = 0;

// Plate width in mm, 0 for the smallest that holds both faces
Width = 0;

// Plate height in mm, 0 for the smallest that holds both faces
Height = 0;

// Thickness of the slab in mm. Raised, and reported, when the cuts in the two
// faces need more.
Thickness = 4;

// How to adjust the vertical corners. Costs openConnect slots near the corners
// - see opengrid_mount_base.scad.
Corner_Refinement_Type = "None"; // [None, Chamfer, Fillet]

// Measurement for the selected corner refinement, in mm
Corner_Refinement_Size = 2; // [0.5:0.5:20]

/* [Misc] */

// Value of $fn for curves on the design
Smoothing = 40; // [10:10:300]

/* [Hidden] */

// The Multiconnect pitch: Multiboard's 25mm grid.
MULTICONNECT_PITCH = 25;

// A Multiconnect head, as mitufy's multiconnect_head() draws it: a 1mm flange
// 20mm across, a 2.5mm cone in to the 15mm neck, and 0.5mm of neck - 4mm in
// all. The library keeps these as Customizer variables of its snap generator
// rather than publishing them, so they are repeated here, and checked: see
// openGridAdapterMulticonnectHead().
MULTICONNECT_HEAD_FLANGE_DIAMETER = 20;
MULTICONNECT_HEAD_NECK_DIAMETER = 15;
MULTICONNECT_HEAD_FLANGE_HEIGHT = 1;
MULTICONNECT_HEAD_CONE_HEIGHT = 2.5;
MULTICONNECT_HEAD_NECK_HEIGHT = 0.5;
MULTICONNECT_HEAD_HEIGHT =
  MULTICONNECT_HEAD_FLANGE_HEIGHT + MULTICONNECT_HEAD_CONE_HEIGHT + MULTICONNECT_HEAD_NECK_HEIGHT;

// The two patterns the library can cut in the flange face, at its defaults
// for a head given no connector-slot config. The coin slot is the arc of a
// 13mm circle, 2.4mm thick, reaching 2.6mm into the head; the dimple a cone
// 2mm across and 1mm deep. Both at the library's own fixed 128 facets.
MULTICONNECT_COIN_SLOT_RADIUS = 13;
MULTICONNECT_COIN_SLOT_THICKNESS = 2.4;
MULTICONNECT_COIN_SLOT_DEPTH = 2.6;
MULTICONNECT_DIMPLE_DIAMETER = 2;
MULTICONNECT_DIMPLE_DEPTH = 1;
MULTICONNECT_PATTERN_FN = 128;

// QuackWorks' Multiconnect slot cross-section, as [radius, depth] with depth
// measured from the floor of the channel: 10.15mm across the floor where the
// flange sits, closing in at 45 degrees to 7.65mm round the neck. From
// multiConnectSlotTool(), along with the numbers below. Its 5mm runs 0.85mm
// past the face it is cut into - MULTICONNECT_SLOT_DEPTH below - so the
// narrow part breaks through cleanly rather than ending on the face.
MULTICONNECT_SLOT_PROFILE = [[0, 0], [10.15, 0], [10.15, 1.2121], [7.65, 3.712], [7.65, 5], [0, 5]];

// How far a Multiconnect slot reaches below the face: QuackWorks sinks its
// tool 2.35mm into a 6.5mm back, which puts the face 4.15mm above the floor.
// A 4mm head therefore seats with 0.15mm to spare.
MULTICONNECT_SLOT_DEPTH = 4.15;

// The on-ramp the head drops in through: a cone from the floor's 10.15mm out
// to 12mm at the far end of the profile, at the face 11.69mm. One per cell, half
// a cell along from each head position.
MULTICONNECT_RAMP_FLOOR_RADIUS = 10.15;
MULTICONNECT_RAMP_OUTER_RADIUS = 12;
MULTICONNECT_RAMP_LENGTH = 5;

// The v2 snap ridge: a 0.4mm sliver taken back into each side of the channel
// at the closed end, tapering to nothing 8mm along, which the flange clicks
// past. QuackWorks' default version, and its default of a ridge rather than
// the v1 dimple.
MULTICONNECT_RIDGE_DEPTH = 0.4;
MULTICONNECT_RIDGE_LENGTH = 8;

// Multiboard's three threads, as the bolt or post that screws in has them:
// [major diameter, pitch, flank angle, tooth depth]. All single-start and
// right-handed, with trapezoidal teeth whose crest and root flats are equal;
// the flank angle is BOSL2's, each face's angle from the plane across the
// axis.
MULTIBOARD_THREAD_LARGE = [22.25, 2.5, 45, 0.75];
MULTIBOARD_THREAD_MID = [14.05, 3, 45, 0.9];
MULTIBOARD_THREAD_SMALL = [6.75, 3, 60, 0.5];

// A hole is the same thread made this much larger across, 0.125mm all round,
// which is what a Multiboard tile's own holes allow a bolt.
MULTIBOARD_THREAD_CLEARANCE = 0.25;

// How far in a hole's teeth reach: the diameter of the tips, which is cut
// back from the clearanced thread's own root. The large hole's tips are a
// tile's 21.4mm across - see the snap hole below. The mid hole's are 13.5,
// which leaves room for a post cut with a shallower mid thread than the bolt
// above. The small hole's are its root, 6.0, so they are not cut back at all.
MULTIBOARD_HOLE_TIP_LARGE = 21.4;
MULTIBOARD_HOLE_TIP_MID = 13.5;
MULTIBOARD_HOLE_TIP_SMALL = 6.0;

// The 45-degree lead-in round a threaded hole's mouth, radially, so a post
// starts square rather than catching on the first tooth.
MULTIBOARD_HOLE_CHAMFER = 0.5;

// A Multiboard tile's large hole, which a snap clicks into: an octagon with
// its flats along the grid, as [depth below the face, across flats]. It
// narrows at 0.5mm per mm from 23.4mm at the face to a 21.4mm band, which a
// snap's body passes through, and widens again past the band at the same
// rate. A snap's flange and taper seat on the near taper, and the bumps on
// its sides spring out behind the band and press on the far one - without
// that widening they have nothing to catch behind. 6.4mm is a tile's
// thickness; a snap is 6.0.
MULTIBOARD_SNAP_HOLE_PROFILE = [[0, 23.4], [2.0, 21.4], [4.4, 21.4], [6.4, 23.4]];
MULTIBOARD_SNAP_HOLE_DEPTH = 6.4;
MULTIBOARD_SNAP_HOLE_FACE_WIDTH = 23.4;

// How far a front cut is carried up past the face it is cut into, so it
// breaks through cleanly rather than ending on the face.
FRONT_CUT_OVERSHOOT = 1;

// How far a front stud or snap is sunk into the face it stands on. The face
// comes from the mount base, whose arithmetic puts it at 3.9999999999999996
// where this file's puts the connector at 4 on some bases - a gap of nothing
// that still leaves every connector a separate body in the mesh. Sinking by a
// hundredth of a millimetre fuses them whatever the rounding, and moves a
// connector less than any printer can place one.
FRONT_FUSE_OVERLAP = 0.01;

// Solid material kept between neighbouring front connectors, and between one
// and the outside of the plate: the mount base's MIN_SLOT_EDGE_WALL, for the
// same reason. Sets the smallest pitch each Multiconnect type will take.
FRONT_MIN_WALL = 0.8;

openGridAdapter(
  backMountType=Back_Mount_Type,
  backUnitsX=Back_Units_X,
  backUnitsY=Back_Units_Y,
  slotSlideDirection=Slot_Slide_Direction,
  slotPosition=Slot_Position,
  slotLockDistribution=Slot_Lock_Distribution,
  slotLockSide=Slot_Lock_Side,
  slotEntryRampFlip=Slot_Entry_Ramp_Flip,
  liteSnap=(Grid_Type == "Lite"),
  snapPlacement=Snap_Placement,
  frontMountType=Front_Mount_Type,
  frontColumns=Front_Columns,
  frontRows=Front_Rows,
  frontPosition=Front_Position,
  frontPitch=Front_Pitch,
  frontSlideDirection=Front_Slide_Direction,
  headPattern=Multiconnect_Head_Pattern,
  threadDepth=Thread_Depth,
  snapHoleThread=Snap_Hole_Thread,
  frontLiteSnap=(Front_Grid_Type == "Lite"),
  frontAlignX=Front_Align_X,
  frontAlignY=Front_Align_Y,
  frontOffset=[Front_Offset_X, Front_Offset_Y],
  width=Width,
  height=Height,
  thickness=Thickness,
  cornerRefinementType=Corner_Refinement_Type,
  cornerRefinementSize=Corner_Refinement_Size,
  $fn=Smoothing
);

// ---------------------------------------------------------------------------
// Published measurements and pieces, for a check or a part that mates with
// this one. See the mount base for why constants go out as functions.

function openGridAdapterMulticonnectPitch() = MULTICONNECT_PITCH;
function openGridAdapterMulticonnectHeadHeight() = MULTICONNECT_HEAD_HEIGHT;
function openGridAdapterMulticonnectSlotDepth() = MULTICONNECT_SLOT_DEPTH;

// A Multiboard thread by size - "Large", "Mid" or "Small" - as the bolt has
// it: [major diameter, pitch, flank angle, tooth depth].
function openGridAdapterMultiboardThread(size = "Large") =
  assert(in_list(size, ["Large", "Mid", "Small"]),
    str("openGridAdapterMultiboardThread: size must be \"Large\", \"Mid\" or \"Small\" - it is \"",
      size, "\"."))
  size == "Large" ? MULTIBOARD_THREAD_LARGE
    : size == "Mid" ? MULTIBOARD_THREAD_MID
    : MULTIBOARD_THREAD_SMALL;

// The hole's major diameter, and the diameter its teeth are cut back to.
function openGridAdapterMultiboardHoleDiameter(size = "Large") =
  openGridAdapterMultiboardThread(size)[0] + MULTIBOARD_THREAD_CLEARANCE;
function openGridAdapterMultiboardHoleTip(size = "Large") =
  size == "Large" ? MULTIBOARD_HOLE_TIP_LARGE
    : size == "Mid" ? MULTIBOARD_HOLE_TIP_MID
    : MULTIBOARD_HOLE_TIP_SMALL;

function openGridAdapterMultiboardSnapHoleDepth() = MULTIBOARD_SNAP_HOLE_DEPTH;

// A Multiboard thread `length` long, standing up from the local Z = 0 plane.
// External by default, for a bolt that mates with the hole below. With
// `clearance` it is the hole's own thread, which is what the hole is cut
// with.
//
// Both are built with BOSL2's internal-thread construction, which phases the
// teeth from a crest rather than a root and enlarges the facets to stand
// outside the true circle. That makes the bolt a hair larger than nominal,
// and puts it in phase with the hole when the two stand on the same plane
// at the same length - so differencing one from the other is a fair test of
// fit, rather than of where each happens to start its helix.
module openGridAdapterMultiboardThread(size = "Large", length = 6.4, clearance = 0) {
  t = openGridAdapterMultiboardThread(size);
  trapezoidal_threaded_rod(d=t[0] + clearance, l=length, pitch=t[1], flank_angle=t[2],
    thread_depth=t[3], internal=true, blunt_start=false, $slop=0, anchor=BOTTOM);
}

// One Multiboard threaded hole, cut DOWN into a face at the local Z = 0 plane
// with the material below it, `depth` deep, with its lead-in at the face.
module openGridAdapterMultiboardThreadHole(size = "Large", depth = 6.4) {
  d = openGridAdapterMultiboardHoleDiameter(size);
  length = depth + FRONT_CUT_OVERSHOOT;
  down(depth) {
    openGridAdapterMultiboardThread(size, length, MULTIBOARD_THREAD_CLEARANCE);
    cyl(d=openGridAdapterMultiboardHoleTip(size), h=length, anchor=BOTTOM);
  }
  down(MULTIBOARD_HOLE_CHAMFER)
    cyl(h=MULTIBOARD_HOLE_CHAMFER + FRONT_CUT_OVERSHOOT, d1=d,
      d2=d + 2 * (MULTIBOARD_HOLE_CHAMFER + FRONT_CUT_OVERSHOOT), anchor=BOTTOM);
}

// One Multiboard snap hole, cut DOWN into a face at the local Z = 0 plane:
// a tile's large hole, MULTIBOARD_SNAP_HOLE_PROFILE, with the floor at its
// full depth. With `thread`, the large thread is cut into it as on a tile,
// where the octagon's flats are the thread's tips - the teeth stand only
// round the middle of each flat, and the corners stay open.
module openGridAdapterMultiboardSnapHole(thread = false) {
  // The near taper carried on up past the face, at its own slope.
  near = MULTIBOARD_SNAP_HOLE_PROFILE[0];
  next = MULTIBOARD_SNAP_HOLE_PROFILE[1];
  slope = (near[1] - next[1]) / (next[0] - near[0]);
  profile = concat(
    [[-FRONT_CUT_OVERSHOOT, near[1] + slope * FRONT_CUT_OVERSHOOT]],
    MULTIBOARD_SNAP_HOLE_PROFILE
  );
  // rotate_extrude() into eight sides puts a corner on +X, and a sixteenth
  // of a turn more puts a flat there instead, along the grid. The profile's
  // widths are across flats, so each is taken out to the corner.
  corner = 1 / cos(180 / 8);
  zrot(180 / 8) rotate_extrude($fn=8)
    polygon(concat(
      [for (p = profile) [p[1] / 2 * corner, -p[0]]],
      [[0, -last(profile)[0]], [0, -profile[0][0]]]
    ));
  if (thread)
    down(MULTIBOARD_SNAP_HOLE_DEPTH)
      openGridAdapterMultiboardThread("Large", MULTIBOARD_SNAP_HOLE_DEPTH + FRONT_CUT_OVERSHOOT,
        MULTIBOARD_THREAD_CLEARANCE);
}

// A Multiconnect head the way multiconnect_head(anchor=BOTTOM) draws it -
// flange down on the Z = 0 plane, neck up - built from the same primitives in
// the same order, so the two are the same solid rather than a lookalike.
//
// Drawn here rather than called because the library's head lives in its snap
// generator (opengrid_parametric_snap.scad), and using that file brings the
// whole generator with it: its threading library warns on every head drawn,
// and scad-compiler would inline all of it into a published file for the sake
// of three cylinders. Checked against the library's own head with
// --backend=Manifold --render: each differenced from the other is empty, for
// all three patterns.
module openGridAdapterMulticonnectHead(headPattern = "Dimple") {
  difference() {
    union() {
      cylinder(h=MULTICONNECT_HEAD_FLANGE_HEIGHT, r=MULTICONNECT_HEAD_FLANGE_DIAMETER / 2);
      up(MULTICONNECT_HEAD_FLANGE_HEIGHT)
        cylinder(h=MULTICONNECT_HEAD_CONE_HEIGHT, r1=MULTICONNECT_HEAD_FLANGE_DIAMETER / 2,
          r2=MULTICONNECT_HEAD_NECK_DIAMETER / 2);
      up(MULTICONNECT_HEAD_FLANGE_HEIGHT + MULTICONNECT_HEAD_CONE_HEIGHT)
        cylinder(h=MULTICONNECT_HEAD_NECK_HEIGHT, r=MULTICONNECT_HEAD_NECK_DIAMETER / 2);
    }
    if (headPattern == "Coin Slot")
      up(MULTICONNECT_COIN_SLOT_DEPTH) xrot(90)
        cyl(r=MULTICONNECT_COIN_SLOT_RADIUS, h=MULTICONNECT_COIN_SLOT_THICKNESS,
          $fn=MULTICONNECT_PATTERN_FN, anchor=BACK);
    if (headPattern == "Dimple")
      cyl(d1=MULTICONNECT_DIMPLE_DIAMETER, d2=EPS, h=MULTICONNECT_DIMPLE_DEPTH,
        $fn=MULTICONNECT_PATTERN_FN, anchor=BOTTOM);
  }
}

// One Multiconnect stud, standing UP off a face at the local Z = 0 plane with
// the material below it: neck on the face, flange outermost. The head is
// drawn flange-down, the way a screw presents it, so it is turned over - see
// the header.
module openGridAdapterMulticonnectStud(headPattern = "Dimple") {
  up(MULTICONNECT_HEAD_HEIGHT) xrot(180) openGridAdapterMulticonnectHead(headPattern);
}

// One Multiconnect channel, cut DOWN into a face at the local Z = 0 plane with
// the material below it. The closed end is centred on the origin and the
// channel runs `length` mm along +Y, with an on-ramp every `pitch` from half a
// pitch along - so a head at the origin, or a whole number of pitches along,
// is seated, and one half a pitch further on can drop in or lift out.
//
// QuackWorks' tool, laid on its back: there the profile's depth is the tool's
// -Y and the channel runs down -Z from the closed end; here the depth is +Z,
// measured up from the floor at -MULTICONNECT_SLOT_DEPTH, and the channel runs
// along +Y. The cross-section is symmetric across the channel, and so are the
// ridges and ramps, so the two agree with no question of handedness.
module openGridAdapterMulticonnectSlot(length = 50, pitch = MULTICONNECT_PITCH) {
  section = concat(
    [for (p = MULTICONNECT_SLOT_PROFILE) if (p.x > 0) [p.x, p.y]],
    [for (k = [len(MULTICONNECT_SLOT_PROFILE) - 1 : -1 : 0])
      let (p = MULTICONNECT_SLOT_PROFILE[k]) if (p.x > 0) [-p.x, p.y]]
  );
  ramps = floor(length / pitch + 0.5);

  down(MULTICONNECT_SLOT_DEPTH) {
    // The round closed end.
    rotate_extrude() polygon(MULTICONNECT_SLOT_PROFILE);

    // The channel, less the snap ridges at its closed end.
    difference() {
      back(length) xrot(90) linear_extrude(length) polygon(section);
      for (side = [-1, 1])
        linear_extrude(MULTICONNECT_SLOT_PROFILE[4].y + 1)
          polygon([
            [side * MULTICONNECT_SLOT_PROFILE[1].x, -EPS],
            [side * (MULTICONNECT_SLOT_PROFILE[1].x - MULTICONNECT_RIDGE_DEPTH), -EPS],
            [side * MULTICONNECT_SLOT_PROFILE[1].x, MULTICONNECT_RIDGE_LENGTH],
          ]);
    }

    // The on-ramps, half a pitch past each head position.
    for (k = [0 : ramps - 1])
      back((k + 0.5) * pitch)
        cyl(h=MULTICONNECT_RAMP_LENGTH, r1=MULTICONNECT_RAMP_FLOOR_RADIUS,
          r2=MULTICONNECT_RAMP_OUTER_RADIUS, anchor=BOTTOM);
  }
}

// ---------------------------------------------------------------------------

module openGridAdapter(
  backMountType = "openConnect",
  backUnitsX = 0,
  backUnitsY = 0,
  slotSlideDirection = "Up",
  slotPosition = "All",
  slotLockDistribution = "All",
  slotLockSide = "Left",
  slotEntryRampFlip = false,
  liteSnap = true,
  snapPlacement = "Corners",
  frontMountType = "Multiconnect Studs",
  frontColumns = 3,
  frontRows = 3,
  frontPosition = "All",
  frontPitch = 0,
  frontSlideDirection = "Up",
  headPattern = "Dimple",
  threadDepth = 6.4,
  snapHoleThread = false,
  frontLiteSnap = true,
  frontAlignX = "Center",
  frontAlignY = "Center",
  frontOffset = [0, 0],
  width = 0,
  height = 0,
  thickness = 4,
  cornerRefinementType = "None",
  cornerRefinementSize = 2,
  anchor,
  orient,
  spin
) {
  tile = openGridMountTileSize();

  mcStuds = frontMountType == "Multiconnect Studs";
  mcSlots = frontMountType == "Multiconnect Slots";
  ocStuds = frontMountType == "openConnect Studs";
  ogSnaps = frontMountType == "openGrid Snaps";
  noFront = frontMountType == "None";
  multiconnect = mcStuds || mcSlots;

  // A Multiboard threaded hole's size, or undef for any other front.
  mbThreadSize = frontMountType == "Multiboard Large Thread Holes" ? "Large"
    : frontMountType == "Multiboard Mid Thread Holes" ? "Mid"
    : frontMountType == "Multiboard Small Thread Holes" ? "Small"
    : undef;
  mbThreads = !is_undef(mbThreadSize);
  mbSnaps = frontMountType == "Multiboard Snap Holes";
  multiboard = mbThreads || mbSnaps;

  assert(multiconnect || multiboard || ocStuds || ogSnaps || noFront,
    str("openGridAdapter: frontMountType must be \"Multiconnect Studs\", \"Multiconnect ",
      "Slots\", \"Multiboard Large Thread Holes\", \"Multiboard Mid Thread Holes\", ",
      "\"Multiboard Small Thread Holes\", \"Multiboard Snap Holes\", \"openConnect Studs\", ",
      "\"openGrid Snaps\" or \"None\" - it is \"", frontMountType, "\"."));

  assert(!mbThreads || threadDepth > 0,
    str("openGridAdapter: threadDepth is how deep the threaded holes go, so it must be more ",
      "than 0 - it is ", threadDepth, "."));

  front_noun = mcStuds ? "Multiconnect stud" : mcSlots ? "Multiconnect slot"
    : mbThreads ? str("Multiboard ", downcase(mbThreadSize), " thread hole")
    : mbSnaps ? "Multiboard snap hole"
    : ocStuds ? "openConnect stud" : ogSnaps ? "openGrid snap" : "plain";

  // -------------------------------------------------------------------------
  // Pitch. Multiconnect is drawn on Multiboard's grid, so the two share one.

  own_pitch = multiconnect || multiboard;
  pitch = !own_pitch ? tile : frontPitch > 0 ? frontPitch : MULTICONNECT_PITCH;

  if (!own_pitch && frontPitch > 0 && frontPitch != tile)
    echo(str("opengrid_adapter: Front_Pitch is ", frontPitch, "mm, but ", front_noun,
      "s are on openGrid's own ", tile, "mm, so it is ignored."));

  // The smallest cell each type that has its own pitch keeps a wall round. A
  // stud's flange; a slot's on-ramp where it meets the face, which is the
  // widest the channel is anywhere on the plate; a threaded hole's lead-in;
  // a snap hole's octagon at the face, whose flats face its neighbours.
  ramp_face_radius = MULTICONNECT_RAMP_FLOOR_RADIUS
    + (MULTICONNECT_RAMP_OUTER_RADIUS - MULTICONNECT_RAMP_FLOOR_RADIUS)
      * MULTICONNECT_SLOT_DEPTH / MULTICONNECT_RAMP_LENGTH;
  min_pitch = mcStuds ? MULTICONNECT_HEAD_FLANGE_DIAMETER + FRONT_MIN_WALL
    : mcSlots ? ramp_face_radius * 2 + FRONT_MIN_WALL
    : mbThreads ? openGridAdapterMultiboardHoleDiameter(mbThreadSize) + 2 * MULTIBOARD_HOLE_CHAMFER
        + FRONT_MIN_WALL
    : mbSnaps ? MULTIBOARD_SNAP_HOLE_FACE_WIDTH + FRONT_MIN_WALL
    : 0;

  assert(pitch >= min_pitch,
    str("openGridAdapter: a ", pitch, "mm pitch is too tight for ", front_noun, "s, which ",
      "need at least ", min_pitch, "mm to keep ", FRONT_MIN_WALL,
      "mm of plate between neighbours."));

  // -------------------------------------------------------------------------
  // Counts. Each axis on its own: an Auto side is sized to the other side's
  // footprint, and both Auto leaves nothing to size from.

  back_requested = [backUnitsX, backUnitsY];
  front_requested = noFront ? [1, 1] : [frontColumns, frontRows];

  for (axis = [0, 1])
    assert(back_requested[axis] > 0 || front_requested[axis] > 0,
      str("openGridAdapter: both faces are on Auto ", axis == 0 ? "across (X)" : "down (Y)",
        ", so neither says how big the plate is. Give the back's units or the front's ",
        axis == 0 ? "columns" : "rows", " a number."));

  for (axis = [0, 1])
    assert(back_requested[axis] == floor(back_requested[axis]) && back_requested[axis] >= 0
        && front_requested[axis] == floor(front_requested[axis]) && front_requested[axis] >= 0,
      "openGridAdapter: counts are whole numbers, 0 for Auto.");

  // A plain front has no footprint of its own, so a plain plate is the back.
  front_span_given = [for (axis = [0, 1]) noFront ? 0 : front_requested[axis] * pitch];
  back_auto = openGridMountAutoUnits(backMountType, front_span_given, slotSlideDirection);
  back_units = [for (axis = [0, 1])
    back_requested[axis] > 0 ? back_requested[axis] : max(1, back_auto[axis])];
  back_span = back_units * tile;

  // An Auto front is whole cells within the back's tiles - never fewer than
  // one, for the reason the back is never fewer either.
  front_units = noFront ? [0, 0] : [for (axis = [0, 1])
    front_requested[axis] > 0 ? front_requested[axis]
      : max(1, floor(back_span[axis] / pitch + 1e-9))];
  front_span = front_units * pitch;

  // -------------------------------------------------------------------------
  // Outline. Everything below is in a frame centred on the back's grid until
  // the outline's own centre is known, then moved into that.

  align = [
    frontAlignX == "Left" ? -1 : frontAlignX == "Right" ? 1 : 0,
    frontAlignY == "Bottom" ? -1 : frontAlignY == "Top" ? 1 : 0,
  ];
  front_centre_on_back = [for (axis = [0, 1])
    align[axis] * (back_span[axis] - front_span[axis]) / 2 + frontOffset[axis]];

  lo = [for (axis = [0, 1])
    min(-back_span[axis] / 2, front_centre_on_back[axis] - front_span[axis] / 2)];
  hi = [for (axis = [0, 1])
    max(back_span[axis] / 2, front_centre_on_back[axis] + front_span[axis] / 2)];
  needed = hi - lo;

  given = [width, height];
  for (axis = [0, 1]) {
    name = axis == 0 ? "Width" : "Height";
    if (given[axis] > 0) {
      assert(given[axis] >= front_span[axis] - EPS,
        str("openGridAdapter: ", name, " is ", given[axis], "mm, but the front's ",
          front_units.x, "x", front_units.y, " ", front_noun, "s at ", pitch,
          "mm need ", front_span[axis], "mm - the front does not fit."));
      assert(given[axis] >= back_span[axis] - EPS,
        str("openGridAdapter: ", name, " is ", given[axis], "mm, but the back's ",
          back_units.x, "x", back_units.y, " openGrid grid needs ", back_span[axis],
          "mm - the back does not fit."));
      assert(given[axis] >= needed[axis] - EPS,
        str("openGridAdapter: ", name, " is ", given[axis], "mm. Either face fits on its ",
          "own, but aligned as asked the two span ", needed[axis], "mm together - ",
          "the front hangs off the back's side. Widen it, or change the alignment."));
    }
  }

  outline = [for (axis = [0, 1]) given[axis] > 0 ? given[axis] : needed[axis]];
  outline_centre = (lo + hi) / 2;
  back_offset = -outline_centre;
  front_centre = front_centre_on_back - outline_centre;

  // -------------------------------------------------------------------------
  // Thickness.

  back_slots = backMountType == "openConnect";
  back_cut = back_slots ? openGridMountSlotDepth() : 0;
  front_cut = mcSlots ? MULTICONNECT_SLOT_DEPTH
    : mbThreads ? threadDepth
    : mbSnaps ? MULTIBOARD_SNAP_HOLE_DEPTH
    : 0;
  front_cuts = front_cut > 0;
  min_thickness = back_cut + front_cut + openGridMountMinBaseWall();
  slab = max(thickness, min_thickness);

  if (slab > thickness)
    echo(str("opengrid_adapter: thickness raised from ", thickness, "mm to ", slab,
      "mm: ", back_cut > 0 ? str(back_cut, "mm of openConnect slot from the back, ") : "",
      front_cut > 0 ? str(front_cut, "mm of ", front_noun, " from the front, ") : "",
      "and ", openGridMountMinBaseWall(), "mm of solid floor ",
      back_cut > 0 && front_cut > 0 ? "between them." : "under it."));

  back_standoff = back_slots ? 0
    : backMountType == "openConnect Studs" ? openGridMountStudHeight()
    : openGridMountSnapThickness(liteSnap);
  front_standoff = mcStuds ? MULTICONNECT_HEAD_HEIGHT
    : ocStuds ? openGridMountStudHeight()
    : ogSnaps ? openGridMountSnapThickness(frontLiteSnap)
    : 0;
  total = back_standoff + slab + front_standoff;

  // -------------------------------------------------------------------------
  // Front cells. j counts DOWNWARD, j = 0 the row furthest in +Y, as the mount
  // base and the connector library both count.

  function frontCell(i, j) = [
    front_centre.x + (i - (front_units.x - 1) / 2) * pitch,
    front_centre.y + ((front_units.y - 1) / 2 - j) * pitch,
  ];

  front_cells = noFront ? [] : [
    for (i = [0 : front_units.x - 1], j = [0 : front_units.y - 1])
      if (is_grid_pos_described(i, j, front_units.x, front_units.y, frontPosition))
        [i, j]
  ];

  assert(noFront || len(front_cells) > 0,
    str("openGridAdapter: Front_Position \"", frontPosition, "\" selects none of the ",
      front_units.x, "x", front_units.y, " front cells."));

  // A Multiconnect channel per line of cells along the slide. A line is cut
  // when any cell in it is selected, and its closed end is the cell furthest
  // AGAINST the slide - see the header.
  along_x = frontSlideDirection == "Left" || frontSlideDirection == "Right";
  slide_sign = frontSlideDirection == "Up" || frontSlideDirection == "Right" ? 1 : -1;
  line_count = along_x ? front_units.y : front_units.x;
  line_length = along_x ? front_units.x : front_units.y;

  function lineSelected(k) =
    len([for (c = front_cells) if ((along_x ? c.y : c.x) == k) 1]) > 0;

  // The closed end's cell. Moving +X is i increasing; moving +Y is j DEcreasing.
  function closedEnd(k) =
    along_x
      ? frontCell(slide_sign > 0 ? 0 : front_units.x - 1, k)
      : frontCell(k, slide_sign > 0 ? front_units.y - 1 : 0);

  mc_lines = mcSlots ? [for (k = [0 : line_count - 1]) if (lineSelected(k)) k] : [];

  // -------------------------------------------------------------------------
  // Reporting.

  echo(str(
    "opengrid_adapter: ", outline.x, "x", outline.y, "mm plate, ", slab, "mm slab. ",
    "Back: ", back_units.x, "x", back_units.y, " ", backMountType,
    back_requested.x == 0 || back_requested.y == 0 ? " (Auto)" : "",
    ". Front: ",
    noFront ? "plain"
      : str(front_units.x, "x", front_units.y, " at ", pitch, "mm, ",
          mcSlots ? str(len(mc_lines), " ", front_noun, len(mc_lines) == 1 ? "" : "s")
            : str(len(front_cells), " ", front_noun, len(front_cells) == 1 ? "" : "s"),
          front_requested.x == 0 || front_requested.y == 0 ? " (Auto)" : "",
          approx(front_centre - back_offset, [0, 0]) ? ", centred on the back"
            : str(", centred ", front_centre - back_offset, "mm from the back's centre")),
    "."
  ));

  // -------------------------------------------------------------------------
  // Geometry. The board plane is z = 0 and the front face z = slab, then the
  // whole is centred for attachable().

  module backFace() {
    openGridMountBase(
      baseShape="Rectangular",
      xUnits=back_units.x,
      yUnits=back_units.y,
      size=outline,
      gridOffset=back_offset,
      thickness=slab,
      mountType=backMountType,
      cornerRefinementType=cornerRefinementType,
      cornerRefinementSize=cornerRefinementSize,
      liteSnap=liteSnap,
      snapPlacement=snapPlacement,
      slotSlideDirection=slotSlideDirection,
      slotPosition=slotPosition,
      slotLockDistribution=slotLockDistribution,
      slotLockSide=slotLockSide,
      slotEntryRampFlip=slotEntryRampFlip,
      anchor="board"
    );
  }

  module frontStuds() {
    up(slab - FRONT_FUSE_OVERLAP)
      for (c = front_cells)
        let (p = frontCell(c.x, c.y))
          translate(p) {
            if (mcStuds) openGridAdapterMulticonnectStud(headPattern);
            if (ocStuds) openGridMountStud(slotSlideDirection=frontSlideDirection, lockNotches="Both");
            // The mount base's own snap, the same way up as it stands there:
            // its TOP against the face it stands on, so turned over.
            if (ogSnaps) xrot(180) openGridSnap(lite=frontLiteSnap, anchor=TOP);
          }
  }

  module frontCuts() {
    up(slab) {
      for (k = mc_lines)
        translate(closedEnd(k))
          zrot(openGridMountSlotFacing(frontSlideDirection))
            openGridAdapterMulticonnectSlot(length=(line_length - 0.5) * pitch, pitch=pitch);
      if (multiboard)
        for (c = front_cells)
          translate(frontCell(c.x, c.y)) {
            if (mbThreads) openGridAdapterMultiboardThreadHole(mbThreadSize, threadDepth);
            if (mbSnaps) openGridAdapterMultiboardSnapHole(snapHoleThread);
          }
    }
  }

  module plate() {
    if (front_cuts) difference() { backFace(); frontCuts(); }
    else union() { backFace(); frontStuds(); }
  }

  attachable(size=[outline.x, outline.y, total], anchor=anchor, orient=orient, spin=spin) {
    down(total / 2 - back_standoff) plate();
    children();
  }
}
