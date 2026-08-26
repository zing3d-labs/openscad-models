use <../../../external/QuackWorks/openGrid/openGrid.scad>
use <../../parts/opengrid_connector.scad>
use <../../parts/opengrid_beam.scad>
use <../../parts/opengrid_dual_sided_snap.scad>
include <BOSL2/std.scad>

basket(Basket_X_Units, Basket_Y_Units, Basket_Z_Units);

/* [Basket Settings] */

// Version of the tile, Full (6.8mm) or Lite (3.4mm)
grid_thickness = "Full"; // [Full,Lite]

// Width of basket in openGrid units (side to side)
Basket_X_Units = 4;
// Depth of basket in openGrid units (front to back)
Basket_Y_Units = 3;
// Height of basket in openGrid units (up and down)
Basket_Z_Units = 6;

/* [Attachment Options] */

// Thickness of the grid to attach the basket to
Attach_to_grid_thickness = "Full"; // [Full,Lite]

// Extra spacing within dual sided snaps used to attach basket to another grid
Dual_connector_spacing = 3;

/* [Visualization Options] */

// Orient pieces in the way they should be printed (checked=print plates, unchecked=assembled orientation)
Orient_for_printing = true;

// How far apart to put pieces as they are diplayed.
Explosion_distance = 5;

/* [Beam Corner Options] */

// Style of beam aesthetic ends of X beams. (Only one of the 3 beams should be set to "Extended" or they will overlap.)
Beam_Corners_X = "Extended"; // [Flush,Extended]

// Style of beam aesthetic ends of Y beams. (Only one of the 3 beams should be set to "Extended" or they will overlap.)
Beam_Corners_Y = "Flush"; // [Flush,Extended]

// Style of beam aesthetic ends of Z beams. (Only one of the 3 beams should be set to "Extended" or they will overlap.)
Beam_Corners_Z = "Flush"; // [Flush,Extended]

/* [Hidden] */
tileSize = 28;
basketLiteGrid = false;
tileThickness = basketLiteGrid ? 3.4 : 6.8;

// openGrid.scad is pulled in via `use`, which imports modules/functions only
// -- not top-level variable assignments. openGrid()'s connector-hole cutout
// logic reads these four as free variables, so they must be declared here or
// they're undef (falsy) and every panel silently gets zero connector holes.
Connector_Holes_Right = true;
Connector_Holes_Left = true;
Connector_Holes_Top = true;
Connector_Holes_Bottom = true;

attach_to_lite_grid = Attach_to_grid_thickness == "Lite";

// Gap left between parts sharing a plate. Only plate 6 holds more than one
// part, so this is purely the hardware plate's part spacing.
plate_part_spacing = 5;

// Bed footprint of one beam lying on its 45-degree print face. Measured from
// a rendered beam -- 13.78mm across at tileThickness 6.8 -- and rounded up.
// It is NOT derivable from tileThickness alone: the cross-section diagonal is
// only 9.6mm and the rest is the connectors protruding from the two faces.
// Over-estimating is the safe direction, since it only widens the gaps.
beam_print_width = 14.5;

// Bed footprint of one dual sided snap standing on its base. Measured from a
// rendered snap -- 25.6 x 26.4mm -- and rounded up, for the same reason: the
// snap's nubs stick out past the Tile_Size - 3.2 core.
snap_print_size = 27;

// ---------------------------------------------------------------------------
// Printable plate decomposition
// ---------------------------------------------------------------------------
// The basket prints as a fixed set of plates, one part per plate:
//
//   1  base panel        openGrid X x Y
//   2  left wall         openGrid Y x Z
//   3  right wall        openGrid Y x Z
//   4  front wall        openGrid X x Z
//   5  back wall         openGrid X x Z
//   6  hardware          2 X beams, 2 Y beams, 4 vertical beams, 4 snaps
//
// The count is fixed rather than packed, so plate N names the same part at
// every basket size and the assembly copy on the model page stays true.
//
// This decomposition is the single source of truth for BOTH consumers -- the
// local build, which renders one STL per plate and packs them into a
// multi-plate 3MF, and mw_grid_basket.scad, which wraps each plate in the
// mw_plate_N() module MakerWorld's Parametric Model Maker exports from. If it
// were written down twice the two would drift, and the 3MF users download from
// the listing would quietly stop matching the one uploaded as the print
// profile.
//
// Plate size is bounded by the largest panel, 28mm per unit: a 7x7x7 basket
// gives 196 x 196mm plates, and 8 units (224mm) is the last size that fits
// MakerWorld's practical 240 x 235mm ceiling. The build pipeline's bed-fit
// check is the authority on this; it is deliberately not duplicated here.
//
// NOTE: mw_ names must never appear in this file. scad-compiler inlines local
// includes, so any model that includes this library would inherit them into
// its own compiled Customizer and silently flip to multi-plate mode -- which
// costs that model its STL downloads. Publishing behavior lives in
// mw_grid_basket.scad.

// Number of printable plates. Fixed for every basket size.
function basket_plate_count() = 6;

// Geometry for one plate, print-oriented, centred on the origin and sitting on
// Z=0. `plate` is 1..basket_plate_count().
module basket_plate(
  plate,
  x_units = 4,
  y_units = 3,
  z_units = 6,
  tile_thickness = 6.8,
  lite_grid = false,
  attach_lite = false,
  snap_spacing = 3,
  corner_x = "Extended",
  corner_y = "Flush",
  corner_z = "Flush",
  part_spacing = 5
) {
  assert(
    plate >= 1 && plate <= basket_plate_count(),
    str("basket_plate: plate must be 1..", basket_plate_count(), ", got ", plate)
  );

  if (plate == 1) {
    basketPanel(x_units, y_units, tile_thickness, anchor=BOTTOM);
  } else if (plate == 2 || plate == 3) {
    basketPanel(y_units, z_units, tile_thickness, anchor=BOTTOM);
  } else if (plate == 4 || plate == 5) {
    basketPanel(x_units, z_units, tile_thickness, anchor=BOTTOM);
  } else {
    basketHardwarePlate(
      x_units, y_units, z_units,
      tile_thickness=tile_thickness, lite_grid=lite_grid, attach_lite=attach_lite,
      snap_spacing=snap_spacing, corner_x=corner_x, corner_y=corner_y, corner_z=corner_z,
      part_spacing=part_spacing
    );
  }
}

// Every plate laid out in a row -- a preview of the decomposition, not a
// printable arrangement. Each plate is a separate print job.
module basket_plates_preview(
  x_units = 4,
  y_units = 3,
  z_units = 6,
  tile_thickness = 6.8,
  lite_grid = false,
  attach_lite = false,
  snap_spacing = 3,
  corner_x = "Extended",
  corner_y = "Flush",
  corner_z = "Flush",
  part_spacing = 5
) {
  count = basket_plate_count();
  pitch = max(x_units, y_units, z_units) * tileSize + 60;

  for (i = [0:count - 1])
    right((i - (count - 1) / 2) * pitch)
      basket_plate(
        i + 1, x_units, y_units, z_units,
        tile_thickness=tile_thickness, lite_grid=lite_grid, attach_lite=attach_lite,
        snap_spacing=snap_spacing, corner_x=corner_x, corner_y=corner_y, corner_z=corner_z,
        part_spacing=part_spacing
      );
}

// Everything on plate 6: the beams that stiffen the panel joints and the dual
// sided snaps that hang the basket off a grid. Beams run along X because it is
// the longer bed axis, and they are the longest parts here.
module basketHardwarePlate(
  x_units,
  y_units,
  z_units,
  tile_thickness,
  lite_grid,
  attach_lite,
  snap_spacing,
  corner_x,
  corner_y,
  corner_z,
  part_spacing
) {
  beam_units = [x_units, x_units, y_units, y_units, z_units, z_units, z_units, z_units];
  beam_corners = [corner_x, corner_x, corner_y, corner_y, corner_z, corner_z, corner_z, corner_z];
  beam_count = len(beam_units);
  snap_count = 4;

  beams_span_y = beam_count * beam_print_width + (beam_count - 1) * part_spacing;
  snaps_span_x = snap_count * snap_print_size + (snap_count - 1) * part_spacing;
  total_y = beams_span_y + part_spacing + snap_print_size;

  // Beams: one row, stacked from the back of the plate forward.
  for (i = [0:beam_count - 1])
    translate([0, total_y / 2 - beam_print_width / 2 - i * (beam_print_width + part_spacing), 0])
      zrot(90)
        basketPrintableBeam(beam_units[i], tile_thickness, beam_corners[i]);

  // Snaps: one row across the front of the plate. The first pair mounts at the
  // top of the basket and is directional on both faces; the second pair mounts
  // at the bottom and is directional on the basket side only.
  for (j = [0:snap_count - 1])
    translate([
      -snaps_span_x / 2 + snap_print_size / 2 + j * (snap_print_size + part_spacing),
      -total_y / 2 + snap_print_size / 2,
      0,
    ])
      dualSidedSnap(
        Lite=lite_grid, Lite_B=attach_lite,
        Directional_A=true, Directional_B=j < 2,
        Spacing=snap_spacing, anchor=BOTTOM
      );
}

// A beam lying on the bed on its 45-degree print face, running along Y and
// centred on the origin. This is the orientation opengrid_beam.scad previews
// itself in: the "print_surface" named anchor is the midpoint of that face, so
// anchoring there and rotating -45 degrees about Y drops the face flat onto
// Z=0.
module basketPrintableBeam(length_units, tile_thickness, corner) {
  yrot(-45)
    opengrid_beam(
      lengthUnits=length_units, tileSize=tileSize, tileThickness=tile_thickness,
      corner1=corner, corner2=corner, anchor="print_surface"
    );
}

// One openGrid panel, attachable so the assembly view can hang beams off it.
module basketPanel(a_units, b_units, tile_thickness, anchor = CENTER, spin = 0, orient = UP) {
  attachable(size=[a_units * tileSize, b_units * tileSize, tile_thickness], anchor=anchor, spin=spin, orient=orient) {
    openGrid(
      Board_Width=a_units, Board_Height=b_units, tileSize=tileSize,
      Tile_Thickness=tile_thickness, anchor=CENTER, Connector_Holes=true
    );
    children();
  }
}

module basketBeam(length_units, tile_thickness, corner, anchor, orient) {
  opengrid_beam(
    lengthUnits=length_units, tileSize=tileSize, tileThickness=tile_thickness,
    anchor=anchor, orient=orient, corner1=corner, corner2=corner
  );
}

// ---------------------------------------------------------------------------
// Assembled view
// ---------------------------------------------------------------------------

// The basket as it ends up on the wall. `explosion` pushes the parts apart to
// show how they meet; 0 is the finished product.
module basket_assembly(
  x_units = 4,
  y_units = 3,
  z_units = 6,
  tile_thickness = 6.8,
  lite_grid = false,
  attach_lite = false,
  snap_spacing = 3,
  corner_x = "Extended",
  corner_y = "Flush",
  corner_z = "Flush",
  explosion = 0
) {
  basketXmillimeter = x_units * tileSize;
  basketYmillimeter = y_units * tileSize;
  basketZmillimeter = z_units * tileSize;

  hide("hidden")
    tag_this("hidden")
      cube([basketXmillimeter, basketYmillimeter, basketZmillimeter], anchor=BOTTOM) {
        $anchor_inside = false;
        // Bottom Panel
        attach(BOTTOM, TOP, overlap=-explosion)
          color_this("black")
            basketPanel(x_units, y_units, tile_thickness) {
              // Front and Back Bottom Beam
              attach([FRONT, BACK], RIGHT, align=TOP, overlap=-explosion)
                color_this("blue")
                  basketBeam(x_units, tile_thickness, corner_x);
              // Left and Right Bottom Beams
              attach([LEFT, RIGHT], RIGHT, align=TOP, overlap=-explosion)
                color_this("green")
                  basketBeam(y_units, tile_thickness, corner_y);
            }

        // Left and Right Panels
        attach([LEFT, RIGHT], TOP, overlap=-explosion)
          color_this("red")
            basketPanel(y_units, z_units, tile_thickness);

        // Front and Back Panels
        attach([FRONT, BACK], TOP, overlap=-explosion)
          color_this("violet")
            basketPanel(x_units, z_units, tile_thickness) {
              // Vertical Beams
              attach([RIGHT, LEFT], RIGHT, align=TOP, overlap=-explosion)
                color_this("orange")
                  basketBeam(z_units, tile_thickness, corner_z);
            }

        // Top Dual Sided Snaps
        xcopies(spacing=basketXmillimeter - tileSize, n=2, sp=[0, 0, 0])
          position(TOP + LEFT + FRONT)
            move([tileSize / 2, 0, -tileSize / 2])
              dualSidedSnap(Lite=lite_grid, Lite_B=attach_lite, Directional=true, Spacing=snap_spacing, anchor=TOP, orient=BACK, spin=180);
        // Bottom Dual Sided Snaps
        xcopies(spacing=basketXmillimeter - tileSize, n=2, sp=[0, 0, 0])
          position(BOTTOM + LEFT + FRONT)
            move([tileSize / 2, 0, tileSize / 2])
              dualSidedSnap(Lite=lite_grid, Lite_B=attach_lite, Directional_A=true, Directional_B=false, Spacing=snap_spacing, anchor=TOP, orient=BACK, spin=180);
      }
}

// Preview entry point. Wires the Customizer variables above to the shared
// modules; every other consumer calls basket_plate()/basket_assembly()
// directly with explicit arguments.
module basket(Basket_X_Units, Basket_Y_Units, Basket_Z_Units) {
  if (Orient_for_printing) {
    basket_plates_preview(
      Basket_X_Units, Basket_Y_Units, Basket_Z_Units,
      tile_thickness=tileThickness, lite_grid=basketLiteGrid, attach_lite=attach_to_lite_grid,
      snap_spacing=Dual_connector_spacing,
      corner_x=Beam_Corners_X, corner_y=Beam_Corners_Y, corner_z=Beam_Corners_Z,
      part_spacing=plate_part_spacing
    );
  } else {
    basket_assembly(
      Basket_X_Units, Basket_Y_Units, Basket_Z_Units,
      tile_thickness=tileThickness, lite_grid=basketLiteGrid, attach_lite=attach_to_lite_grid,
      snap_spacing=Dual_connector_spacing,
      corner_x=Beam_Corners_X, corner_y=Beam_Corners_Y, corner_z=Beam_Corners_Z,
      explosion=Explosion_distance
    );
  }
}
