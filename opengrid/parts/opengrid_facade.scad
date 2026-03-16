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
  removalNotchDepth
) {

  $fn = Smoothing;

  halfGridUnitDimension = gridUnitDimension / 2;
  x_size_mm = xUnits * gridUnitDimension;
  y_size_mm = yUnits * gridUnitDimension;

  center_to_y_edge_distance = y_size_mm / 2;
  center_to_x_edge_distance = x_size_mm / 2;

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
}
