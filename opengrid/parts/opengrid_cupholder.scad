include <BOSL2/std.scad>
use <opengrid_facade.scad>

/* [Cup Holder] */

// Inner diameter at the bottom (open end) of the cup holder, in mm
Cup_Holder_Bottom_Diameter = 75;

// Inner diameter at the top (facade side) of the cup holder, in mm
Cup_Holder_Top_Diameter = 90;

// Height of the cup holder body, in mm
Cup_Holder_Height = 90;

// Thickness of the cup holder walls, in mm
Wall_Thickness = 2;

/* [Base Settings] */

// Version of the tile, Full (6.8mm) or Lite (3.4mm)
Grid_Type = "Lite"; // [Full,Lite]

// Thickness of the mounting base (passed to the facade), in mm
Base_Thickness = 4;

// Use the bottom (open end) diameter to size the grid instead of the top diameter.
// The top diameter may overlap additional tiles slightly, which is fine if enabled.
Size_Grid_To_Bottom_Diameter = false;

// Snap Placement
Snap_Placement = "Corners"; // [All, Edges, Corners]

// How to adjust corners for visual appeal
Corner_Refinement_Type = "Fillet"; // [None, Chamfer, Fillet]

// Measurement for the selected corner refinement
Corner_Refinement_Size = 5; // [2:0.5:20]

/* [Misc] */

// Value of $fn for curves on the design
Smoothing = 150; // [10:10:300]

/* [Hidden] */
gridUnitDimension = 28;

openGridCupholder(
  cupHolderBottomDiameter=Cup_Holder_Bottom_Diameter,
  cupHolderTopDiameter=Cup_Holder_Top_Diameter,
  cupHolderHeight=Cup_Holder_Height,
  wallThickness=Wall_Thickness,
  baseThickness=Base_Thickness,
  sizeGridToBottomDiameter=Size_Grid_To_Bottom_Diameter,
  snapPlacement=Snap_Placement,
  cornerRefinementType=Corner_Refinement_Type,
  cornerRefinementSize=Corner_Refinement_Size,
  liteSnap=(Grid_Type == "Lite"),
);

module openGridCupholder(
  cupHolderBottomDiameter = 85,
  cupHolderTopDiameter = 90,
  cupHolderHeight = 90,
  wallThickness = 2,
  baseThickness = 4,
  sizeGridToBottomDiameter = false,
  snapPlacement = "Corners",
  cornerRefinementType = "Fillet",
  cornerRefinementSize = 5,
  liteSnap = false,
  anchor,
  orient,
  spin
) {
  $fn = Smoothing;

  outer_bottom_diameter = cupHolderBottomDiameter + 2 * wallThickness;
  outer_top_diameter = cupHolderTopDiameter + 2 * wallThickness;

  sizing_diameter = sizeGridToBottomDiameter ? outer_bottom_diameter : outer_top_diameter;
  units = ceil(sizing_diameter / gridUnitDimension);

  // Hollow frustum cup body, attachable so attach() can position it.
  // d1 = bottom (open end), d2 = top (at facade). Centered at z=0.
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
        cyl(h=cupHolderHeight, d1=outer_top_diameter, d2=outer_bottom_diameter);
        down(0.01) cyl(h=cupHolderHeight + 0.02, d1=cupHolderTopDiameter, d2=cupHolderBottomDiameter);
      }
      children();
    }
  }

  // Render: facade base with cup body attached to its bottom face.
  openGridFacade(
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
  ) {
    attach(BOTTOM, TOP, overlap=0.1)
      cupBody();
  }
}
