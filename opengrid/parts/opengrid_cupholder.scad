include <BOSL2/std.scad>
use <opengrid_facade.scad>

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
// follow evenly around from it.
Handle_Slot_Start_Angle = 0; // [0:5:355]

// How to break the two ends of each slot - the mouth at the rim and the closed
// inner end
Handle_Slot_End_Refinement_Type = "Fillet"; // [None, Chamfer, Fillet]

// Measurement for the selected refinement - fillet radius or chamfer leg, in mm
Handle_Slot_End_Refinement_Size = 3; // [0.5:0.5:20]

/* [Base Settings] */

// Version of the tile, Full (6.8mm) or Lite (3.4mm)
Grid_Type = "Lite"; // [Full,Lite]

// Thickness of the mounting base (passed to the facade), in mm
Base_Thickness = 4;

// Use the bottom (open end) diameter to size the grid instead of the top diameter.
// The top diameter may overlap additional tiles slightly, which is fine if enabled.
Size_Base_Units_To_Bottom_Diameter = false;

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
  handleSlotCount=Handle_Slot_Count,
  handleSlotHeight=Handle_Slot_Height,
  handleSlotWidth=Handle_Slot_Width,
  handleSlotStartAngle=Handle_Slot_Start_Angle,
  handleSlotEndRefinementType=Handle_Slot_End_Refinement_Type,
  handleSlotEndRefinementSize=Handle_Slot_End_Refinement_Size,
  baseThickness=Base_Thickness,
  sizeGridToBottomDiameter=Size_Base_Units_To_Bottom_Diameter,
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
  handleSlotCount = 0,
  handleSlotHeight = 45,
  handleSlotWidth = 30,
  handleSlotStartAngle = 0,
  handleSlotEndRefinementType = "Fillet",
  handleSlotEndRefinementSize = 3,
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

  // Cross-section of one slot cutter, drawn across the slot (X) and along it
  // (Y), with Y = 0 at the rim. Both ends are broken by the same refinement:
  // the closed end takes it as a relief cut into the slot, and the rim end
  // takes it negated, which flares the mouth outward as a lead-in for the
  // handle.
  module slotProfile() {
    // Corner order is [X+Y+, X-Y+, X-Y-, X+Y-]: the two Y+ corners are the
    // closed end of the slot, the two Y- corners are the mouth at the rim.
    ends = [slot_end_size, slot_end_size, -slot_end_size, -slot_end_size];
    fwd(slot_overhang) {
      if (handleSlotEndRefinementType == "Chamfer") {
        rect([handleSlotWidth, slot_height + slot_overhang], chamfer=ends, anchor=FRONT);
      } else {
        rect([handleSlotWidth, slot_height + slot_overhang], rounding=ends, anchor=FRONT);
      }
    }
  }

  // Handle slot cutters, in cupBody's local frame: the cup opening is that
  // frame's BOTTOM face, so the slots are measured down from there and reach
  // up toward the facade. Emits nothing when slots are switched off, which
  // leaves the cup body exactly as it would be without this feature.
  module handleSlotCutters() {
    $fn = Smoothing;
    if (handleSlotCount > 0 && slot_height > 0 && handleSlotWidth > 0) {
      for (i = [0 : handleSlotCount - 1]) {
        zrot(handleSlotStartAngle + i * 360 / handleSlotCount)
          down(cupHolderHeight / 2)
            // Swing the profile round so it extrudes radially outward from the
            // cup axis, which keeps the slot sides parallel through the wall.
            rotate([90, 0, 90])
              linear_extrude(height=slot_reach)
                slotProfile();
      }
    }
  }

  // Hollow tapered cup body, attachable so attach() can position it.
  // Cup opening (top) is the free end; facade connection is the mounting end.
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
        handleSlotCutters();
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
