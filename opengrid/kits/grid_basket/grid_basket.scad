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

// Orient pieces in the way they should be printed (checked=print orientation, unchecked=assembled orientation)
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
connectorHoles = true;

attach_to_lite_grid = Attach_to_grid_thickness == "Lite";

module basket(Basket_X_Units, Basket_Y_Units, Basket_Z_Units) {
  basketXmillimeter = Basket_X_Units * tileSize;
  basketYmillimeter = Basket_Y_Units * tileSize;
  basketZmillimeter = Basket_Z_Units * tileSize;

  hide("hidden")

  if (Orient_for_printing) {
    printable_base_x = basketXmillimeter + (4 * Explosion_distance) + (2 * tileThickness) + (2 * basketZmillimeter);
    printable_base_y = basketYmillimeter + (4 * Explosion_distance) + (2 * tileThickness) + (2 * basketZmillimeter);
    x_beams_offset_distance = basketYmillimeter / 2 + Explosion_distance + tileThickness / 2;
    y_beams_offset_distance = basketXmillimeter / 2 + Explosion_distance + tileThickness / 2;

    dual_mounting_snap_x_offset_distance = basketXmillimeter / 2 + tileSize / 2 + Explosion_distance;
    dual_mounting_snap_y_offset_distance = basketYmillimeter / 2 + tileSize / 2 + Explosion_distance;
    vertical_beam_x_offset_distance = basketXmillimeter / 2 + 2 * tileThickness + Explosion_distance;
    vertical_beam_y_offset_distance = basketYmillimeter / 2 + basketZmillimeter / 2 + tileThickness + Explosion_distance;

    tag_this("hidden")
      // A block used to position all the parts of the basket.  The box represents the space 
      // directly inside of the basket.
      cube([printable_base_x, printable_base_y, 5], anchor=TOP) {
        color_this("black")
          align(TOP)
            openGridWithDefaults(Basket_X_Units, Basket_Y_Units, tileThickness, anchor=BOTTOM);
        // Front and Back Bottom Beam
        for (local_spin = [90, -90]) {
          attach(TOP, "print_surface", spin=local_spin)
            left(x_beams_offset_distance)
              bottomXBeams();
        }
        //// Left and Right Bottom Beams
        for (local_spin = [0, 180]) {
          attach(TOP, "print_surface", spin=local_spin)
            left(y_beams_offset_distance)
              bottomYBeams();
        }

        // Vertical Beams
        xcopies(n=4, spacing=-(tileSize + Explosion_distance), sp=[-vertical_beam_x_offset_distance, vertical_beam_y_offset_distance, 0])
          attach(TOP, "print_surface")
            verticalBeam();

        // Left and Right Panels
        color_this("red")
          align(TOP, [RIGHT, LEFT])
            openGridWithDefaults(Basket_Y_Units, Basket_Z_Units, tileThickness, spin=90);

        // Front and Back Panels
        color_this("violet")
          align(TOP, [FRONT, BACK])
            openGridWithDefaults(Basket_X_Units, Basket_Z_Units, tileThickness);

        xcopies(n=2, spacing=(tileSize - 3) + Explosion_distance, sp=[dual_mounting_snap_x_offset_distance, dual_mounting_snap_y_offset_distance, 0])
          dualSidedSnap(Lite=basketLiteGrid, Lite_B=attach_to_lite_grid, Directional=true, Spacing=Dual_connector_spacing, anchor=BOTTOM);

        xcopies(n=2, spacing=(tileSize - 3) + Explosion_distance, sp=[dual_mounting_snap_x_offset_distance, dual_mounting_snap_y_offset_distance + (tileSize - 3) + Explosion_distance, 0])
          dualSidedSnap(Lite=basketLiteGrid, Lite_B=attach_to_lite_grid, Directional_A=true, Directional_B=false, Spacing=Dual_connector_spacing, anchor=BOTTOM);
      }
  } else {
    tag_this("hidden")
      cube([basketXmillimeter, basketYmillimeter, basketZmillimeter], anchor=BOTTOM) {
        $anchor_inside = false;
        // Bottom Panel
        attach(BOTTOM, TOP, overlap=-Explosion_distance)
          color_this("black")
            openGridWithDefaults(Basket_X_Units, Basket_Y_Units, tileThickness) {
              // Front and Back Bottom Beam
              attach([FRONT, BACK], RIGHT, align=TOP, overlap=-Explosion_distance)
                bottomXBeams();
              // Left and Right Bottom Beams
              //align()
              attach([LEFT, RIGHT], RIGHT, align=TOP, overlap=-Explosion_distance)
                bottomYBeams();
            }

        // Left and Right Panels
        attach([LEFT, RIGHT], TOP, overlap=-Explosion_distance)
          color_this("red")
            openGridWithDefaults(Basket_Y_Units, Basket_Z_Units, tileThickness);

        // Front and Back Panels
        attach([FRONT, BACK], TOP, overlap=-Explosion_distance)
          color_this("violet")
            openGridWithDefaults(Basket_X_Units, Basket_Z_Units, tileThickness) {

              // Vertical Beams
              attach([RIGHT, LEFT], RIGHT, align=TOP, overlap=-Explosion_distance)
                verticalBeam();
            }
        // Top Dual Sided Snaps
        xcopies(spacing=basketXmillimeter - tileSize, n=2, sp=[0, 0, 0])
          position(TOP + LEFT + FRONT)
            move([tileSize / 2, 0, -tileSize / 2])
              dualSidedSnap(Lite=basketLiteGrid, Lite_B=attach_to_lite_grid, Directional=true, Spacing=Dual_connector_spacing, anchor=TOP, orient=BACK, spin=180);
        // Bottom Dual Sided Snaps
        xcopies(spacing=basketXmillimeter - tileSize, n=2, sp=[0, 0, 0])
          position(BOTTOM + LEFT + FRONT)
            move([tileSize / 2, 0, tileSize / 2])
              dualSidedSnap(Lite=basketLiteGrid, Lite_B=attach_to_lite_grid, Directional_A=true, Directional_B=false, Spacing=Dual_connector_spacing, anchor=TOP, orient=BACK, spin=180);
      }
  }

  module openGridWithDefaults(xUnits, yUnits, thickness, anchor = CENTER, connectorHoles = false, spin = 0) {

    attachable(size=[xUnits * tileSize, yUnits * tileSize, thickness], spin=spin) {
      openGrid(Board_Width=xUnits, Board_Height=yUnits, tileSize=tileSize, Tile_Thickness=tileThickness, anchor=anchor, Connector_Holes=connectorHoles);
      children();
    }
  }

  module verticalBeam(anchor, orient) {
    color_this("orange")
      opengrid_beam(lengthUnits=Basket_Z_Units, tileSize=tileSize, tileThickness=tileThickness, anchor=anchor, orient=orient, corner1=Beam_Corners_Z, corner2=Beam_Corners_Z);
  }

  module bottomXBeams(anchor, orient) {
    color_this("blue")
      opengrid_beam(
        lengthUnits=Basket_X_Units, tileSize=tileSize, tileThickness=tileThickness, anchor=anchor, orient=orient, corner1=Beam_Corners_X, corner2=Beam_Corners_X
      );
  }

  module bottomYBeams() {
    color_this("green")
      opengrid_beam(lengthUnits=Basket_Y_Units, tileSize=tileSize, tileThickness=tileThickness, corner1=Beam_Corners_Y, corner2=Beam_Corners_Y);
  }
}
