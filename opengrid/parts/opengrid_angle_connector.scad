/*
  opengrid_angle_connector.scad

  A load-bearing part that holds something at a set tilt off an openGrid
  board. It slides onto openConnect connectors screwed into the board, and the
  object slides onto a second face standing at the chosen angle. Written to
  tent a split keyboard on a desk tray, and meant to be general beyond that.

  This is a WORKING DRAFT. The decisions behind it, the options that were
  weighed and the questions still open are in opengrid_angle_connector.md
  beside this file - read that first.

  ---------------------------------------------------------------------------
  Frame

  Built as it is used, the same way round as opengrid_mount_base.scad:

      board face    the Z = 0 plane, facing DOWN. Its plate is an
                    openGridMountBase() - openConnect slots or snaps.
      hinge axis    X. The tilt is a rotation about X, so the object face's
                    low edge runs along X and the face rises toward +Y.
      object face   the tilted face, looking up and toward -Y. Its own frame
                    (the "object frame") has the face in its local Z = 0
                    plane, outward +Z, local +X along the hinge and local +Y
                    up the slope. Everything on that face is drawn in that
                    frame and placed by one matrix, angleConnectorObjectPose().

  Where the face sits is three numbers, all about its LOW EDGE: its height
  above the board surface, how far it is set across the hinge from the
  board's trailing edge (the edge the face rises away from), and how far the
  face is slid along the hinge. The board and the face are sized
  independently in grid units, so a 3x3 board can carry a 5x3 face set out
  past its far edge. The part refuses a face that would run into the board
  plate or below the board surface, or that would put the board plate where
  the object goes, and it says when a placement leaves the body standing on
  little of the board, the face and board barely overlapping along the
  hinge, or an object less room below the low edge than asked for.

  The body fills whatever lies between the plates EXCEPT two zones: the
  object plate itself (so it never fills a slot), and the space in front of
  the face reaching Low_Edge_Clearance below its low edge (so an object that
  overhangs the low edge has room). Further below that, the body may reach in
  front of the face plane - that is what buttresses a face whose low edge is
  set out over the board - and directly behind the face below its low edge it
  takes hold of the plate's lower end.

  That one matrix is the whole angle mechanism. The draft offers a single tilt
  axis, but the pose already takes a toe angle (about the board normal) and a
  roll (about the face's up-slope axis), and everything placed through it -
  the object plate, its studs or slots, the Solid and Ribbed bodies, which
  are hulls of the two plates - follows any pose it is given. Only the bodies
  drawn from a side profile (Tube, Truss, Arch) assume one axis, and they say
  so in an assert. Toe and roll are module parameters, not Customizer ones,
  until they have been printed.

  ---------------------------------------------------------------------------
  Directions

  Slide directions use the mount base's own names, read in each face's own
  axes: "Left" is -X, "Right" is +X (both along the hinge on either face),
  "Up" is +Y and "Down" is -Y. On the object face "Up" means up the slope.
  As everywhere in this repository, the part carrying the SLOTS slides the
  named way to come off.

  The default for both faces is "Left": along the hinge. That is deliberate:

    - Gravity has no component along the hinge, so it can neither seat nor
      unseat either joint. Down the slope it would seat the object; up the
      slope it would pull it off. Along the hinge it does neither, and the
      lock nubs hold the position.
    - Both joints then share one axis, which is what lets the part print on
      its side with every stud and slot the right way up - see Printing.

  ---------------------------------------------------------------------------
  Handedness

  With one tilt axis, the left-hand part IS the right-hand part turned 180
  degrees about the board normal, so one print serves both keyboard halves.
  Handedness = "Right" builds that mirror image properly anyway, so the
  slides point the same world way on both halves: the BODY is mirrored, and
  every slot and stud is re-placed and asked for by the mirrored name -
  never mirrored itself, because the openConnect head is chiral. Once toe or
  roll are in play the two halves are genuinely different parts, and this is
  the path they will take.

  ---------------------------------------------------------------------------
  Printing

  "On Side" lays the part on its +X or -X end, which puts every layer in the
  plane the tilt happens in. Typing load bends the part in exactly that
  plane, so the layers carry it rather than peel apart - the strong
  orientation for a tent. Both faces print as vertical walls, and so do the
  Tube, Truss and Arch bodies, whose walls all run along the hinge. Ribbed
  does not: its gussets lie across the hinge and become shelves with a free
  edge, so print Ribbed As Mounted.

  The end that goes down is chosen from the object face's slide, so that
  every stud's flat FRONT faces the bed. Measured layer by layer on a stud
  standing off a vertical wall (anything more than 45 degrees out from the
  layer beneath counts), that leaves a single unsupported layer: a 2.4mm
  ledge straight off the wall, on the one face of the head that mates with
  nothing. Every other way up leaves less area unsupported, but spread over
  several layers of the flange and its lock notches - the parts that do the
  holding. With both slides along the hinge the board's slot mouths face the
  bed too. A slide up or down the slope cannot be laid that way, and is
  echoed.

  "As Mounted" leaves the board face on the bed, for looking at.

  ---------------------------------------------------------------------------
  Licensing

  Original work by zing3d-labs, CC BY-NC-SA 4.0 (see ../../LICENSE). Both
  mounts and the studs come in through opengrid_mount_base.scad, which carries
  the licensing note for mitufy's openConnect connector library (CC BY 4.0)
  and QuackWorks' openGrid snap (CC BY-NC-SA 4.0).
  ---------------------------------------------------------------------------
*/

include <BOSL2/std.scad>
use <opengrid_mount_base.scad>

/* [Face Placement] */

// Tilt of the object face off the board, in degrees. 0 is a flat spacer, 90
// stands the face upright.
Tilt_Angle = 45; // [0:1:90]

// Height of the object face's low edge above the board surface, in mm. 0
// picks the least that keeps the object plate clear of the board plate.
Low_Edge_Height = 0;

// Where the low edge sits across the hinge, in mm from the board plate's
// trailing edge - the edge the face rises away from (-Y for a left-hand
// part). Positive moves it the way the face rises. It may be negative, or
// run past the far edge, so the face overhangs the board.
Low_Edge_Offset = 0;

// Slides the object face along the hinge, in mm, relative to the board
// plate's centre.
Face_Offset_X = 0;

// How far below the face's low edge, measured down the slope, the space in
// front of the face is kept clear - for an object that overhangs the low
// edge. Below that the body may reach in front of the face to buttress it
// from the board, which is what holds a face whose low edge is set well over
// the board.
Low_Edge_Clearance = 10;

/* [Board Face] */

Board_Units_X = 4; // [1:1:12]
Board_Units_Y = 2; // [1:1:12]

// Thickness of the board plate. openConnect needs at least 3.5mm.
Board_Thickness = 5;

Board_Mount_Type = "openConnect"; // [openConnect, Snaps]

// Way the part slides to come off the board's connectors.
Board_Slide_Direction = "Left"; // [Left, Right, Up, Down]

Board_Slot_Position = "All"; // [All, Staggered, Edge Rows, Edge Columns, Corners]
Board_Slot_Lock_Distribution = "All"; // [All, Staggered, Corners, Top Corners, Bottom Corners, None]
Board_Slot_Lock_Side = "Left"; // [Left, Right]

// Tile version, for a snap mount
Grid_Type = "Lite"; // [Full, Lite]
Snap_Placement = "Corners"; // [All, Edges, Corners]

/* [Object Face] */

Object_Units_X = 4; // [1:1:12]
Object_Units_Y = 3; // [1:1:12]

// Thickness of the object plate behind the face.
Object_Thickness = 5;

// What the object face carries. Studs mate with openConnect slots in the
// object; Slots take connectors (or studs) on the object; Snaps click into
// openGrid tiles carried by the object.
Object_Mount_Type = "Studs"; // [Studs, Slots, Snaps]

// Way the OBJECT slides to come off this face. "Up" is up the slope.
Object_Slide_Direction = "Left"; // [Left, Right, Up, Down]

// Which grid positions on the object face carry a stud or slot.
Object_Mount_Position = "Corners"; // [All, Staggered, Edge Rows, Edge Columns, Corners]

/* [Body] */

// What joins the two plates. See opengrid_angle_connector.md for pictures.
// Tube, Truss and Arch are walls running along the hinge and print on their
// side with no support inside the body; Ribbed is gussets across it and
// prints As Mounted.
Body_Shape = "Truss"; // [Solid, Tube, Truss, Arch, Ribbed]

// Wall thickness of the Tube, Truss and Arch shells and the Truss webs.
Wall_Thickness = 3;

// Bays in the Truss - each one is an upright and a diagonal.
Truss_Bays = 3; // [1:1:8]

// Close the ends of a Tube, Truss or Arch. Printed on side, the top end is a
// bridge across the whole profile.
End_Walls = false;

// Gussets in a Ribbed body. The outer two sit flush with the ends.
Rib_Count = 3; // [2:1:12]

Rib_Thickness = 4;

/* [Layout] */

Handedness = "Left"; // [Left, Right]
Print_Orientation = "On Side"; // [On Side, As Mounted]

/* [Hidden] */

Smoothing = 40; // [10:10:300]

opengridAngleConnector(
  tiltAngle=Tilt_Angle,
  lowEdgeHeight=Low_Edge_Height,
  lowEdgeOffset=Low_Edge_Offset,
  faceOffsetX=Face_Offset_X,
  lowEdgeClearance=Low_Edge_Clearance,
  boardUnitsX=Board_Units_X,
  boardUnitsY=Board_Units_Y,
  boardThickness=Board_Thickness,
  boardMountType=Board_Mount_Type,
  boardSlideDirection=Board_Slide_Direction,
  boardSlotPosition=Board_Slot_Position,
  boardSlotLockDistribution=Board_Slot_Lock_Distribution,
  boardSlotLockSide=Board_Slot_Lock_Side,
  liteSnap=Grid_Type == "Lite",
  snapPlacement=Snap_Placement,
  objectUnitsX=Object_Units_X,
  objectUnitsY=Object_Units_Y,
  objectThickness=Object_Thickness,
  objectMountType=Object_Mount_Type,
  objectSlideDirection=Object_Slide_Direction,
  objectMountPosition=Object_Mount_Position,
  bodyShape=Body_Shape,
  wallThickness=Wall_Thickness,
  trussBays=Truss_Bays,
  endWalls=End_Walls,
  ribCount=Rib_Count,
  ribThickness=Rib_Thickness,
  handedness=Handedness,
  printOrientation=Print_Orientation,
  $fn=Smoothing
);

// ---------------------------------------------------------------------------
// The angle mechanism.

// Overlap between the body and the plates it joins, so they share volume
// rather than meeting across a face.
ANGLE_CONNECTOR_OVERLAP = 0.1;

// Larger than any part this file draws; used for the clipping half-spaces.
ANGLE_CONNECTOR_REACH = 2000;

// How far past the board plate's edge the face may reach before the part
// says so. Reaching that far is allowed - it is a note, not a check.
ANGLE_CONNECTOR_CANTILEVER_NOTE = 10;

// Places the object frame in the part's frame. The hinge line - the object
// face's low edge - runs along X at height `lift` and position `hingeY`, and
// the face's centre sits `offsetX` along it; the face rises from it at
// `tilt`. `toe` turns it about the board normal and `roll` about its own
// up-slope axis. A face of depth `objectDepth` has its centre at the object
// frame's origin.
//
// This is the single source of truth for where the object face is. Shared in
// spirit with a lighter angle bracket for beams: anything that hangs a face
// at an angle off an openGrid face needs exactly this and a plate either end.
function angleConnectorObjectPose(tilt, lift, hingeY, objectDepth, toe = 0, roll = 0, offsetX = 0) =
  move([offsetX, hingeY, lift]) * zrot(toe) * xrot(tilt) * yrot(roll) * back(objectDepth / 2);

// A lift that keeps the object plate's lowest corner on or above the board
// plate's top face wherever the face is, for a single tilt axis. It is the
// least that fits when the low edge is over the board; a face set off the
// board can go lower, and Low_Edge_Height says how much.
function angleConnectorMinLift(tilt, boardThickness, objectThickness) =
  boardThickness + objectThickness * cos(tilt);

// A reflection across the XZ plane, for the right-hand part.
ANGLE_CONNECTOR_MIRROR = scale([1, -1, 1]);

// A slide name re-read after a reflection across Y, in whichever frame the
// reflection happened: Up and Down trade, Left and Right stay.
function angleConnectorYFlipDirection(direction) =
  direction == "Up" ? "Down" : direction == "Down" ? "Up" : direction;

// The lock side re-read after the same reflection. The side is named across
// the slide, so it only trades when the slide runs along X and the across
// axis is the one reflected.
function angleConnectorYFlipLockSide(direction, side) =
  (direction == "Left" || direction == "Right") ? (side == "Left" ? "Right" : "Left") : side;

// Grid position centres of a units grid centred on the origin, filtered by
// the mount base's placement names. i counts to the right, j DOWNWARD from
// the +Y row, as the mount base counts them.
function angleConnectorGridPositions(unitsX, unitsY, placement) =
  let (t = openGridMountTileSize())
  [
    for (i = [0:unitsX - 1], j = [0:unitsY - 1])
      let (
        edgeRow = j == 0 || j == unitsY - 1,
        edgeCol = i == 0 || i == unitsX - 1,
        keep = placement == "All" ? true
          : placement == "Staggered" ? (i + j) % 2 == 0
          : placement == "Edge Rows" ? edgeRow
          : placement == "Edge Columns" ? edgeCol
          : placement == "Corners" ? edgeRow && edgeCol
          : assert(false, str("Unknown mount position: ", placement))
      )
      if (keep) [(i - (unitsX - 1) / 2) * t, ((unitsY - 1) / 2 - j) * t]
  ];

// ---------------------------------------------------------------------------

module opengridAngleConnector(
  tiltAngle = 45,
  lowEdgeHeight = 0,
  lowEdgeOffset = 0,
  faceOffsetX = 0,
  lowEdgeClearance = 10,
  toeAngle = 0,
  rollAngle = 0,
  boardUnitsX = 4,
  boardUnitsY = 2,
  boardThickness = 5,
  boardMountType = "openConnect",
  boardSlideDirection = "Left",
  boardSlotPosition = "All",
  boardSlotLockDistribution = "All",
  boardSlotLockSide = "Left",
  liteSnap = true,
  snapPlacement = "Corners",
  objectUnitsX = 4,
  objectUnitsY = 3,
  objectThickness = 5,
  objectMountType = "Studs",
  objectSlideDirection = "Left",
  objectMountPosition = "Corners",
  bodyShape = "Truss",
  wallThickness = 3,
  trussBays = 3,
  endWalls = false,
  ribCount = 3,
  ribThickness = 4,
  handedness = "Left",
  printOrientation = "On Side"
) {
  t = openGridMountTileSize();
  eps = ANGLE_CONNECTOR_OVERLAP;
  reach = ANGLE_CONNECTOR_REACH;
  singleAxis = toeAngle == 0 && rollAngle == 0;
  rightHand = handedness == "Right";

  board_w = boardUnitsX * t;
  board_d = boardUnitsY * t;
  object_w = objectUnitsX * t;
  object_d = objectUnitsY * t;
  // The body spans whatever the two plates span along the hinge.
  body_x0 = min(-board_w / 2, faceOffsetX - object_w / 2);
  body_x1 = max(board_w / 2, faceOffsetX + object_w / 2);
  body_w = body_x1 - body_x0;
  body_xc = (body_x0 + body_x1) / 2;
  x_overlap = min(board_w / 2, faceOffsetX + object_w / 2) - max(-board_w / 2, faceOffsetX - object_w / 2);

  lift_used = lowEdgeHeight == 0
    ? angleConnectorMinLift(tiltAngle, boardThickness, objectThickness)
    : lowEdgeHeight;
  hinge_y = -board_d / 2 + lowEdgeOffset;

  assert(tiltAngle >= 0 && tiltAngle <= 90,
    str("Tilt_Angle must be between 0 and 90 degrees - it is ", tiltAngle, "."));
  assert(lowEdgeHeight >= 0,
    str("Low_Edge_Height is a height above the board, so it cannot be negative - it is ", lowEdgeHeight, "mm."));
  assert(lowEdgeClearance >= 0,
    str("Low_Edge_Clearance cannot be negative - it is ", lowEdgeClearance, "mm."));
  assert(boardMountType != "openConnect" || boardThickness >= openGridMountMinThickness(),
    str("Board_Thickness must be at least ", openGridMountMinThickness(),
      "mm for openConnect slots - it is ", boardThickness, "mm."));
  assert(objectMountType != "Slots" || objectThickness >= openGridMountMinThickness(),
    str("Object_Thickness must be at least ", openGridMountMinThickness(),
      "mm for openConnect slots - it is ", objectThickness, "mm."));
  assert(singleAxis || bodyShape == "Solid" || bodyShape == "Ribbed",
    str("A toe or roll angle needs Body_Shape = Solid or Ribbed for now - ", bodyShape,
      " is drawn from a single-axis side profile."));
  assert(bodyShape != "Ribbed" || ribCount >= 2,
    "A Ribbed body needs at least two ribs, one at each end.");

  pose_left = angleConnectorObjectPose(tiltAngle, lift_used, hinge_y, object_d, toeAngle, rollAngle, faceOffsetX);
  // M * P * M: a proper motion, so whatever it places is placed, not
  // mirrored, while it lands where the mirrored part's face is.
  pose = rightHand ? ANGLE_CONNECTOR_MIRROR * pose_left * ANGLE_CONNECTOR_MIRROR : pose_left;

  // Slide names as each plate's own builder has to be asked for them.
  // The right hand re-reads every name in its reflected frame; the object
  // plate's slots and snaps are drawn by openGridMountBase() turned over by
  // xrot(180), which reflects Y once more in the base's own frame.
  board_dir = rightHand ? angleConnectorYFlipDirection(boardSlideDirection) : boardSlideDirection;
  board_lock = rightHand ? angleConnectorYFlipLockSide(boardSlideDirection, boardSlotLockSide) : boardSlotLockSide;
  object_dir = rightHand ? angleConnectorYFlipDirection(objectSlideDirection) : objectSlideDirection;
  object_base_dir = angleConnectorYFlipDirection(object_dir);
  // Which side the object plate's nubs sit on is this file's choice, not the
  // user's, so it takes the side that fits a true head in every direction:
  // the base's "Right" nub, under a slide of Down or Right, leaves 0.126mm^3
  // per slot standing against openconnect_head() (see the .md, Findings).
  object_base_lock = "Left";

  // Which end goes down for an on-side print: the one the studs' flat
  // fronts face, which is opposite the object's slide name. The board's
  // slot mouths face the same way when the two slides agree.
  side_down_is_plus_x = objectSlideDirection == "Left";
  stud_side_printable = objectSlideDirection == "Left" || objectSlideDirection == "Right";

  if (printOrientation == "On Side" && !stud_side_printable && objectMountType == "Studs")
    echo(str("opengridAngleConnector: WARNING - studs sliding '", objectSlideDirection,
      "' cannot be laid flat-front-down when printed on side, so their flanges print over air. ",
      "Slide them Left or Right, or print As Mounted."));
  if (printOrientation == "On Side" && bodyShape == "Ribbed")
    echo("opengridAngleConnector: WARNING - a Ribbed body printed on side turns its inner ribs into shelves with a free edge. Print it As Mounted.");
  if (printOrientation == "On Side" && boardSlideDirection != objectSlideDirection)
    echo("opengridAngleConnector: note - the board and object slides differ, so only the object face is laid the printable way up.");

  // --- placement sanity, in the side view (Y, Z) ------------------------
  //
  // Everything here is measured in the face's own slope coordinates: s down
  // the face from its low edge (negative below it) and n out of the face
  // (negative behind it). The checks sample lines at 1mm, which is finer
  // than anything they guard against.
  slope_u = [cos(tiltAngle), sin(tiltAngle)];
  slope_n = [-sin(tiltAngle), cos(tiltAngle)];
  low_edge = [hinge_y, lift_used];
  function slopeS(p) = (p - low_edge) * slope_u;
  function slopeN(p) = (p - low_edge) * slope_n;
  function samples(a, b) = let (k = max(1, ceil(norm(b - a)))) [for (i = [0:k]) lerp(a, b, i / k)];

  stud_reach = objectMountType == "Studs" ? openGridMountStudHeight()
    : objectMountType == "Snaps" ? openGridMountSnapThickness(liteSnap) : 0;
  face_lo = low_edge;
  face_hi = low_edge + object_d * slope_u;
  // The object plate's outline in the side view, mount included.
  plate_outline = concat(
    samples(face_lo - objectThickness * slope_n, face_hi - objectThickness * slope_n),
    samples(face_lo + stud_reach * slope_n, face_hi + stud_reach * slope_n),
    samples(face_lo - objectThickness * slope_n, face_lo + stud_reach * slope_n),
    samples(face_hi - objectThickness * slope_n, face_hi + stud_reach * slope_n)
  );
  board_top = samples([-board_d / 2, boardThickness], [board_d / 2, boardThickness]);
  plates_share_x = x_overlap > 0;

  plate_lowest = min([for (p = plate_outline) p.y]);
  plate_in_board = [for (p = plate_outline)
    if (plates_share_x && abs(p.x) < board_d / 2 - 1e-6 && p.y < boardThickness - 1e-6) p];
  // The board's top face where the object goes: in front of the face, from
  // its low edge up.
  board_under_object = [for (p = board_top) if (slopeN(p) > 1e-6 && slopeS(p) >= 0) p];
  // ...and below the low edge, within the clearance asked for.
  board_in_clearance = [for (p = board_top) if (slopeN(p) > 1e-6 && slopeS(p) < 0) p];
  clearance_available = len(board_in_clearance) == 0 ? undef
    : -max([for (p = board_in_clearance) slopeS(p)]);
  // How much of the board's depth the body may stand on: everything outside
  // the zone kept clear in front of the face.
  joint_depth = len([for (p = board_top)
    if (!(slopeN(p) > -objectThickness && slopeS(p) > 0) && !(slopeN(p) > 0 && slopeS(p) > -lowEdgeClearance)) p]) - 1;
  face_overhang = max(0, max(face_hi.x, face_lo.x) - board_d / 2, -board_d / 2 - min(face_hi.x, face_lo.x));

  if (singleAxis) {
    assert(plate_lowest >= -1e-6,
      str("The object face reaches ", -plate_lowest, "mm below the board surface. Raise ",
        "Low_Edge_Height, or lower Tilt_Angle."));
    assert(len(plate_in_board) == 0,
      str("The object plate", stud_reach > 0 ? " or its mount" : "", " runs into the board plate (at Y = ",
        plate_in_board[0].x, ", Z = ", plate_in_board[0].y, "). Raise Low_Edge_Height to at least ",
        angleConnectorMinLift(tiltAngle, boardThickness, objectThickness),
        "mm, or move the low edge off the board with Low_Edge_Offset."));
    assert(!plates_share_x || len(board_under_object) == 0,
      str("The board plate sits in front of the object face, where the object goes (at Y = ",
        board_under_object[0].x, "). Move the low edge back with Low_Edge_Offset, or raise it."));
    if (plates_share_x && clearance_available != undef && clearance_available < lowEdgeClearance)
      echo(str("opengridAngleConnector: WARNING - the board plate is only ", clearance_available,
        "mm below the face's low edge (down the slope), less than the ", lowEdgeClearance,
        "mm Low_Edge_Clearance asks for. An object overhanging the low edge further than that meets the board."));
    if (joint_depth < t)
      echo(str("opengridAngleConnector: WARNING - the body stands on only ", max(joint_depth, 0),
        "mm of the board's ", board_d, "mm depth, so the face hangs off a narrow joint. Lower ",
        "Low_Edge_Clearance, or move the low edge back over the board."));
    // Only worth saying once it is more than a plate's slop: at the defaults
    // the face's top edge already passes the board's by a few mm.
    if (face_overhang > ANGLE_CONNECTOR_CANTILEVER_NOTE)
      echo(str("opengridAngleConnector: note - the face reaches ", face_overhang,
        "mm past the board plate's edge, as a cantilever."));
  }
  if (x_overlap < t)
    echo(str("opengridAngleConnector: WARNING - the face and the board plate overlap by only ",
      max(x_overlap, 0), "mm along the hinge, so the body twists between them. Bring Face_Offset_X back."));

  echo(str("opengridAngleConnector: tilt ", tiltAngle, " deg; low edge ", lift_used,
    "mm above the board, ", lowEdgeOffset, "mm from its trailing edge, ", faceOffsetX,
    "mm along the hinge; face ", object_w, " x ", object_d, "mm on a ", board_w, " x ", board_d,
    "mm board; top edge ", lift_used + object_d * sin(tiltAngle), "mm up"));

  // --- the side profile, for the single-axis bodies, in (Y, Z) -----------
  function objectCorner(y, z) = let (p = apply(pose_left, [0, y, z])) [p.y, p.z];
  // Set into the object plate by twice the overlap, so the plate zone (which
  // starts at one overlap) cuts them cleanly. Sitting exactly on its edge
  // they leave a zero-volume sliver behind.
  back_low = objectCorner(-object_d / 2, -objectThickness + 2 * eps);
  back_high = objectCorner(object_d / 2, -objectThickness + 2 * eps);
  board_lo = [-board_d / 2, boardThickness - eps];
  board_hi = [board_d / 2, boardThickness - eps];
  profile_points = [board_lo, board_hi, back_high, back_low];
  profile = select(profile_points, hull2d_path(profile_points));

  // The Arch: a quarter-ellipse from the board plate's far edge round to the
  // object plate's high edge, sprung from the corner where the two meet. It
  // needs that corner over the board with room ahead of it.
  arch_corner = [back_low.x, boardThickness - eps];
  assert(bodyShape != "Arch" || !singleAxis
      || (arch_corner.x >= board_lo.x && arch_corner.x <= board_hi.x - 2 * wallThickness),
    str("An Arch springs from below the face's low edge, so that has to be over the board with ",
      2 * wallThickness, "mm to spare before its far edge. Use Truss, Tube or Solid for a face set ",
      "this far out, or bring Low_Edge_Offset back."));
  // Wound counter-clockwise, as polygon() and offset() expect.
  arch_region = concat(
    [arch_corner],
    [for (a = [0:5:90]) arch_corner + cos(a) * (board_hi - arch_corner) + sin(a) * (back_high - arch_corner)],
    [back_low]
  );
  arch_region_ccw = is_polygon_clockwise(arch_region) ? reverse(arch_region) : arch_region;

  rib_xs = [for (k = [0:max(ribCount, 2) - 1]) body_x0 + ribThickness / 2 + k * (body_w - ribThickness) / (max(ribCount, 2) - 1)];

  // What the body has to keep clear of, in the side view, as two zones in
  // the face's slope coordinates:
  //   - the object plate and everything in front of it, from its low end up,
  //     so the body never fills a slot. It starts `eps` above the low end so
  //     a body meeting the plate's end overlaps it rather than touching.
  //   - the space in front of the face plane, reaching Low_Edge_Clearance
  //     below the low edge, which is where an overhanging object goes.
  // Behind the face plane below its low edge is NOT kept clear - the object
  // can never be there - and that is where the body takes hold of the plate's
  // lower end when the face is set out over the board.
  function slopeQuad(s0, n0) = [for (sn = [[s0, n0], [reach, n0], [reach, reach], [s0, reach]])
    low_edge + sn[0] * slope_u + sn[1] * slope_n];
  plate_zone = slopeQuad(eps, -objectThickness + eps);
  object_zone = slopeQuad(-lowEdgeClearance, 0);

  // The Truss's webs: an upright from the board to the object plate at each
  // bay, and a diagonal from the top of one to the foot of the next, so every
  // bay is triangulated. Drawn as a path and stroked to Wall_Thickness.
  truss_path = [
    for (i = [1:trussBays])
      each [lerp(board_lo, board_hi, i / (trussBays + 1)), lerp(back_low, back_high, i / (trussBays + 1))]
  ];

  // Extrudes a 2D (Y, Z) child across X, centred on the body's span. The
  // builtin offset() is used on these rather than BOSL2's function, because
  // a lightening hole on a shallow tilt can shrink to nothing, and the
  // builtin returns nothing where BOSL2's asserts.
  module extrudeAcross(width) {
    translate([body_xc - width / 2, 0, 0]) rotate([90, 0, 90]) linear_extrude(height=width) children();
  }

  // A side profile with the clear zones taken out BEFORE it is shelled, so a
  // Tube or Truss cut back by the zone keeps a wall along the cut rather than
  // opening its hollow to the air.
  module clippedProfile(region) {
    difference() { polygon(region); polygon(plate_zone); polygon(object_zone); }
  }

  // The hollow of a shelled profile. Inset from the profile together with
  // the two plates it meets, so that along a plate the hollow runs right up
  // to the plate and the plate is the wall - a shell wall there would only
  // double it - while along any other edge, the clearance cut included, it
  // stops a Wall_Thickness short.
  module profileHollow(region) {
    intersection() {
      offset(delta=-wallThickness) union() {
        clippedProfile(region);
        polygon([face_lo, face_hi, face_hi - objectThickness * slope_n, face_lo - objectThickness * slope_n]);
        translate([-board_d / 2, 0]) square([board_d, boardThickness]);
      }
      clippedProfile(region);
    }
  }

  module solidHull() {
    hull() {
      up(boardThickness - eps) cuboid([board_w, board_d, eps], anchor=BOTTOM);
      multmatrix(pose_left) down(objectThickness - eps) cuboid([object_w, object_d, eps], anchor=TOP);
    }
  }

  module ribSlab(x) {
    translate([x, 0, 0]) cuboid([ribThickness, reach, reach]);
  }

  module bodyUnclipped() {
    if (bodyShape == "Solid") {
      solidHull();
    } else if (bodyShape == "Ribbed") {
      for (x = rib_xs) intersection() { solidHull(); ribSlab(x); }
    } else if (bodyShape == "Tube" || bodyShape == "Truss" || bodyShape == "Arch") {
      region = bodyShape == "Arch" ? arch_region_ccw : profile;
      difference() {
        extrudeAcross(body_w) clippedProfile(region);
        // The hollow, less the end walls if asked for. The Truss's webs are
        // taken out of the hollow rather than added to the shell, so they
        // stop at its inside face.
        difference() {
          extrudeAcross(body_w + 2) profileHollow(region);
          if (endWalls) for (x = [body_x0 + wallThickness / 2, body_x1 - wallThickness / 2]) translate([x, 0, 0])
            cuboid([wallThickness, reach, reach]);
          if (bodyShape == "Truss") extrudeAcross(body_w + 4) stroke(truss_path, width=wallThickness);
        }
      }
    } else {
      assert(false, str("Unknown Body_Shape: ", bodyShape));
    }
  }

  // Everything the body may NOT occupy: the board plate (its slots) and the
  // ground under the board's surface, and the two zones kept clear around
  // the face (the object plate's slots and the object itself). The same
  // zones as plate_zone and object_zone, drawn in 3D through the pose so they
  // hold for any pose.
  module bodyLeft() {
    difference() {
      bodyUnclipped();
      down(reach / 2 - boardThickness + eps) cuboid([board_w, board_d, reach]);
      cuboid([reach, reach, reach], anchor=TOP);
      multmatrix(pose_left) {
        translate([0, -object_d / 2 + eps, -objectThickness + eps])
          cuboid([reach, reach, reach], anchor=FRONT + BOTTOM);
        translate([0, -object_d / 2 - lowEdgeClearance, 0])
          cuboid([reach, reach, reach], anchor=FRONT + BOTTOM);
      }
    }
  }

  module boardPlate() {
    openGridMountBase(
      xUnits=boardUnitsX,
      yUnits=boardUnitsY,
      thickness=boardThickness,
      mountType=boardMountType,
      liteSnap=liteSnap,
      snapPlacement=snapPlacement,
      slotSlideDirection=board_dir,
      slotPosition=boardSlotPosition,
      slotLockDistribution=boardSlotLockDistribution,
      slotLockSide=board_lock,
      anchor="board"
    );
  }

  // Drawn in the object frame: face at Z = 0, plate behind it, mount in
  // front of it.
  module objectPlate() {
    if (objectMountType == "Studs") {
      down(objectThickness) cuboid([object_w, object_d, objectThickness], anchor=BOTTOM);
      for (p = angleConnectorGridPositions(objectUnitsX, objectUnitsY, objectMountPosition))
        translate([p.x, p.y, 0]) openGridMountStud(object_dir);
    } else {
      // The mount base is built face DOWN with material above; turned over
      // here (a rotation, not a mirror) so its material is behind the face.
      xrot(180) openGridMountBase(
        xUnits=objectUnitsX,
        yUnits=objectUnitsY,
        thickness=objectThickness,
        mountType=objectMountType == "Slots" ? "openConnect" : "Snaps",
        liteSnap=liteSnap,
        snapPlacement=snapPlacement,
        slotSlideDirection=object_base_dir,
        slotPosition=objectMountPosition,
        slotLockDistribution="All",
        slotLockSide=object_base_lock,
        anchor="board"
      );
    }
  }

  module assembled() {
    union() {
      if (rightHand) multmatrix(ANGLE_CONNECTOR_MIRROR) bodyLeft(); else bodyLeft();
      boardPlate();
      multmatrix(pose) objectPlate();
    }
  }

  if (printOrientation == "On Side")
    // yrot(90) takes +X down and yrot(-90) takes -X down; either way the
    // end that lands on the bed is lifted onto it.
    up(side_down_is_plus_x ? body_x1 : -body_x0) yrot(side_down_is_plus_x ? 90 : -90) assembled();
  else
    assembled();
}
