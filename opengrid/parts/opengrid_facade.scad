include <BOSL2/std.scad>
use <../../external/QuackWorks/openGrid/opengrid-snap.scad>

// This file adds a flat facade to an opengrid. Could be
// useful for baskets or walls made of opengrid.
//

/* [Required Dimensions] */

// Version of the tile, Full (6.8mm) or Lite (3.4mm)
Grid_Type = "Lite"; // [Full,Lite]

// Thickness of flat surface
Facade_Thickness = 1;

// OpenGrid units on the X dimension
Units_Y = 4;

// OpenGrid units on the Y dimension
Units_X = 3;

/* [Snap Options] */

// Snap Placement - Fill in all grid spots or only certain ones
Snap_Placement = "Corners"; // [All, Edges, Corners]

// How to adjust corners for visual appeal
Corner_Refinement_Type = "Fillet"; // [None, Chamfer, Fillet]

// Measurement for the selected corner refinement
Corner_Refinement_Size = 5; // [2:0.5:20]

// Should the top corner snaps be directional
Top_Corner_Directional_Snaps = false;

// Should the top, non-corner edge snaps be directional
Top_Edge_Directional_Snaps = false;

/* [Removal Notch] */

// Should include a removal notch that can be used to pry off the facade with a
// screwdriver.
Include_Removal_Notches = true;

// The size of the removal notch on the dimension that runs along the side of the facade.
Removal_Notch_Width = 7; // [1:1:10]

// The size of the removal notch on the dimension that runs away from the side of the facade.
Removal_Notch_Depth = 2; // [1:1:10]

/* [Misc] */

// Value of $fn for curves on the design
Smoothing = 40; // [10:10:300]

/* [Hidden] */
gridUnitDimension = 28;

openGridFacade(
  xUnits=Units_X,
  yUnits=Units_Y,
  facadeThickness=Facade_Thickness,
  cornerRefinementType=Corner_Refinement_Type,
  cornerRefinementSize=Corner_Refinement_Size,
  topCornerDirectionalSnaps=Top_Corner_Directional_Snaps,
  topEdgeDirectionalSnaps=Top_Edge_Directional_Snaps,
  liteSnap=(Grid_Type == "Lite"),
  includeCornerSnaps=true,
  includeEdgeSnaps=(Snap_Placement == "All" || Snap_Placement == "Edges"),
  includeInternalSnaps=(Snap_Placement == "All"),
  includeRemovalNotches=Include_Removal_Notches,
  removalNotchWidth=Removal_Notch_Width,
  removalNotchDepth=Removal_Notch_Depth,
);

module openGridFacade(
  xUnits = 4,
  yUnits = 3,
  facadeThickness = 1,
  cornerRefinementType = "None",
  cornerRefinementSize = 1,
  liteSnap = false,
  includeCornerSnaps = true,
  includeEdgeSnaps = false,
  includeInternalSnaps = false,
  topCornerDirectionalSnaps = false,
  topEdgeDirectionalSnaps = false,
  includeRemovalNotches,
  removalNotchWidth,
  removalNotchDepth,
  anchor, orient, spin
) {

  $fn = Smoothing;

  halfGridUnitDimension = gridUnitDimension / 2;
  x_size_mm = xUnits * gridUnitDimension;
  y_size_mm = yUnits * gridUnitDimension;

  center_to_y_edge_distance = y_size_mm / 2;
  center_to_x_edge_distance = x_size_mm / 2;

  snap_thickness = liteSnap ? 3.4 : 6.8;
  total_thickness = facadeThickness + snap_thickness;

  snap_top_z  = total_thickness / 2;
  corner_x    = x_size_mm / 2 - halfGridUnitDimension;
  corner_y    = y_size_mm / 2 - halfGridUnitDimension;

  _corner_anchors = [
    named_anchor("snap_bl",                       [-corner_x, -corner_y, snap_top_z], TOP, 0),
    named_anchor("snap_br",                       [ corner_x, -corner_y, snap_top_z], TOP, 0),
    named_anchor("snap_tl",                       [-corner_x,  corner_y, snap_top_z], TOP, 0),
    named_anchor("snap_tr",                       [ corner_x,  corner_y, snap_top_z], TOP, 0),
    named_anchor(str("snap_0_0"),                 [-corner_x, -corner_y, snap_top_z], TOP, 0),
    named_anchor(str("snap_", xUnits-1, "_0"),    [ corner_x, -corner_y, snap_top_z], TOP, 0),
    named_anchor(str("snap_0_", yUnits-1),        [-corner_x,  corner_y, snap_top_z], TOP, 0),
    named_anchor(str("snap_", xUnits-1, "_", yUnits-1), [ corner_x, corner_y, snap_top_z], TOP, 0),
  ];

  _top_bottom_edge_anchors = includeEdgeSnaps ? [
    for (i = [0 : xUnits - 3], y_sign = [-1, 1])
      let(
        ex = (i - (xUnits - 3) / 2) * gridUnitDimension,
        ey = y_sign * corner_y,
        gx = i + 1,
        gy = y_sign < 0 ? 0 : yUnits - 1
      )
        named_anchor(str("snap_", gx, "_", gy), [ex, ey, snap_top_z], TOP, 0)
  ] : [];

  _side_edge_anchors = includeEdgeSnaps ? [
    for (x_sign = [-1, 1], j = [0 : yUnits - 3])
      let(
        ex = x_sign * corner_x,
        ey = (j - (yUnits - 3) / 2) * gridUnitDimension,
        gx = x_sign < 0 ? 0 : xUnits - 1,
        gy = j + 1
      )
        named_anchor(str("snap_", gx, "_", gy), [ex, ey, snap_top_z], TOP, 0)
  ] : [];

  _internal_anchors = includeInternalSnaps ? [
    for (i = [0 : xUnits - 3], j = [0 : yUnits - 3])
      named_anchor(
        str("snap_", i + 1, "_", j + 1),
        [(i - (xUnits - 3) / 2) * gridUnitDimension,
         (j - (yUnits - 3) / 2) * gridUnitDimension,
         snap_top_z],
        TOP, 0
      )
  ] : [];

  anchors = concat(
    [named_anchor("bottom_center", [0, 0, -total_thickness / 2], BOTTOM, 0)],
    _corner_anchors,
    _top_bottom_edge_anchors,
    _side_edge_anchors,
    _internal_anchors
  );

  attachable(size=[x_size_mm, y_size_mm, total_thickness], anchors=anchors, anchor=anchor, orient=orient, spin=spin) {
    down(total_thickness / 2)
    diff()
      cuboid(
      [x_size_mm, y_size_mm, facadeThickness],
      rounding=(cornerRefinementType == "Fillet" ? cornerRefinementSize : 0),
      chamfer=(cornerRefinementType == "Chamfer" ? cornerRefinementSize : 0),
      edges="Z",
      anchor=BOTTOM
    ) {

      // Top Corner Snaps
      xcopies(spacing=(x_size_mm - gridUnitDimension), n=2, sp=0)
        color(topCornerDirectionalSnaps ? "pink" : "lightblue")
          move([-(center_to_x_edge_distance - halfGridUnitDimension), center_to_y_edge_distance - halfGridUnitDimension, 0])
            attach(TOP, TOP)
              openGridSnap(lite=liteSnap, directional=topCornerDirectionalSnaps, spin=-90);

      // Top Edge Snaps
      if (includeEdgeSnaps)
        xcopies(spacing=gridUnitDimension, n=xUnits - 2)
          color(topEdgeDirectionalSnaps ? "orange" : "lightblue")
            move([0, center_to_y_edge_distance - halfGridUnitDimension, 0])
              attach(TOP, TOP)
                openGridSnap(lite=liteSnap, directional=topEdgeDirectionalSnaps, spin=-90);

      // Bottom Corner Snaps
      xcopies(spacing=(x_size_mm - gridUnitDimension), n=2, sp=0)
        color("lightblue")
          move([-(center_to_x_edge_distance - halfGridUnitDimension), -(center_to_y_edge_distance - halfGridUnitDimension), 0])
            attach(TOP, TOP)
              openGridSnap(lite=liteSnap);

      // Bottom Edge Snaps
      if (includeEdgeSnaps)
        xcopies(spacing=gridUnitDimension, n=xUnits - 2)
          color("lightblue")
            move([0, -(center_to_y_edge_distance - halfGridUnitDimension), 0])
              attach(TOP, TOP)
                openGridSnap(lite=liteSnap);

      // Side Edge Snaps
      if (includeEdgeSnaps)
        color("lightblue")
          grid_copies(spacing=[x_size_mm - gridUnitDimension, gridUnitDimension], n=[2, yUnits - 2])
            attach(TOP, TOP)
              openGridSnap(lite=liteSnap);

      // Internal Snaps
      if (includeInternalSnaps)
        color("lightblue")
          grid_copies(spacing=[gridUnitDimension, gridUnitDimension], n=[xUnits - 2, yUnits - 2])
            attach(TOP, TOP)
              openGridSnap(lite=liteSnap);

      // Removal Notches
      if (includeRemovalNotches)
        attach([FRONT, BACK, LEFT, RIGHT], FRONT, inside=true, shiftout=0.01)
          tag("remove")
            cuboid([removalNotchWidth, removalNotchDepth, facadeThickness + 0.1]);
      }
    children();
  }
}
