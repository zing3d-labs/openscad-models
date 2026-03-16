use <../../../external/QuackWorks/openGrid/openGrid.scad>
use <../../parts/opengrid_connector.scad>
use <../../parts/opengrid_beam.scad>
use <../../parts/opengrid_dual_sided_snap.scad>
include <BOSL2/std.scad>

module mw_plate_1() {
  plate_z_beams();
}
module mw_plate_2() {
  plate_xy_beams();
}
module mw_plate_3() {
  plate_bottom_grid();
}
module mw_plate_4() {
  plate_side_grid();
}
module mw_plate_5() {
  plate_side_grid();
}
module mw_plate_6() {
  plate_frontback_grid();
}
module mw_plate_7() {
  plate_frontback_grid();
}

module mw_assembly_view() {
  assembledView(
    basketLiteGrid,
    Basket_X_Units,
    Basket_Y_Units,
    Basket_Z_Units,
    attachToGridThickness=Attach_to_grid_thickness,
    explosionDistance=Explosion_distance,
    dualConnectorSpacing=Dual_connector_spacing
  );
}

if (MakerWorld == false)
  assembledView(
    basketLiteGrid,
    Basket_X_Units,
    Basket_Y_Units,
    Basket_Z_Units,
    attachToGridThickness=Attach_to_grid_thickness,
    explosionDistance=Explosion_distance,
    dualConnectorSpacing=Dual_connector_spacing
  );

//basket(Basket_X_Units, Basket_Y_Units, Basket_Z_Units);
//plate_z_beams();

/* [Basket Settings] */

MakerWorld = true;

// Version of the tile, Full (6.8mm) or Lite (3.4mm)
Grid_thickness = "Full"; // [Full,Lite]

// Width of basket in openGrid units (side to side)
Basket_X_Units = 4;
// Depth of basket in openGrid units (front to back)
Basket_Y_Units = 3;
// Height of basket in openGrid units (up and down)
Basket_Z_Units = 5;

/* [Attachment Options] */

// Thickness of the grid to attach the basket to
Attach_to_grid_thickness = "Full"; // [Full,Lite]

// Extra spacing within dual sided snaps used to attach basket to another grid
Dual_connector_spacing = 3;

/* [Visualization Options] */

// Orient pieces in the way they should be printed (checked=print orientation, unchecked=assembled orientation)
Orient_for_printing = true;

// How far apart to put pieces as they are diplayed.
//Explosion_distance = 0;
Explosion_distance = 5;
//Explosion_distance = 10;

/* [Hidden] */
tileSize = 28;
basketLiteGrid = Grid_thickness == "Lite";
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
    vertical_beam_x_offset_distance = basketXmillimeter / 2 + ( (Explosion_distance + tileThickness) * 4);
    vertical_beam_y_offset_distance = basketYmillimeter / 2 + basketZmillimeter / 2 + tileThickness + Explosion_distance;

    side_grid_offset_distance = (tileSize * Basket_X_Units) / 2 + (tileSize * Basket_Z_Units) / 2 + (Explosion_distance);
    frontback_grid_offset_distance = (tileSize * Basket_Y_Units) / 2 + (tileSize * Basket_Z_Units) / 2 + (Explosion_distance);

    move([-vertical_beam_x_offset_distance, vertical_beam_y_offset_distance, 0])
      plate_z_beams();
    move([-vertical_beam_x_offset_distance, -vertical_beam_y_offset_distance, 0])
      plate_xy_beams();

    plate_bottom_grid();

    // Left Panel
    xmove(-side_grid_offset_distance)
      plate_side_grid();
    // Right Panel
    xmove(side_grid_offset_distance)
      plate_side_grid();
    // Front Panel
    ymove(side_grid_offset_distance)
      plate_frontback_grid();
    // Back Panel
    ymove(-side_grid_offset_distance)
      plate_frontback_grid();

    tag_this("hidden")
      // A block used to position all the parts of the basket.  The box represents the space 
      // directly inside of the basket.
      cube([printable_base_x, printable_base_y, 5], anchor=TOP) {

        //xcopies(n=2, spacing=(tileSize - 3) + Explosion_distance, sp=[dual_mounting_snap_x_offset_distance, dual_mounting_snap_y_offset_distance, 0])
        dualSidedSnap(Lite=basketLiteGrid, Lite_B=attach_to_lite_grid, Directional=true, Spacing=Dual_connector_spacing, anchor=BOTTOM);

        xcopies(n=2, spacing=(tileSize - 3) + Explosion_distance, sp=[dual_mounting_snap_x_offset_distance, dual_mounting_snap_y_offset_distance + (tileSize - 3) + Explosion_distance, 0])
          dualSidedSnap(Lite=basketLiteGrid, Lite_B=attach_to_lite_grid, Directional_A=true, Directional_B=false, Spacing=Dual_connector_spacing, anchor=BOTTOM);
      }
  }
  else
    assembledView(
      basketLiteGrid,
      Basket_X_Units,
      Basket_Y_Units,
      Basket_Z_Units,
      attachToGridThickness=Attach_to_grid_thickness,
      explosionDistance=Explosion_distance,
      dualConnectorSpacing=Dual_connector_spacing
    );
}

module openGridWithDefaults(xUnits, yUnits, thickness, anchor = CENTER, connectorHoles = false, spin = 0) {
  attachable(size=[xUnits * tileSize, yUnits * tileSize, thickness], spin=spin) {
    openGrid(Board_Width=xUnits, Board_Height=yUnits, tileSize=tileSize, Tile_Thickness=tileThickness, anchor=anchor, Connector_Holes=connectorHoles);
    children();
  }
}

module verticalBeam(anchor, orient) {
  color_this("orange")
    opengrid_beam(lengthUnits=Basket_Z_Units, tileSize=tileSize, tileThickness=tileThickness, anchor=anchor, orient=orient);
}

module bottomXBeam(anchor, orient) {
  color_this("blue")
    opengrid_beam(lengthUnits=Basket_X_Units, tileSize=tileSize, tileThickness=tileThickness, anchor=anchor, orient=orient);
}
module bottomYBeam(anchor, orient) {
  color_this("blue")
    opengrid_beam(lengthUnits=Basket_Y_Units, tileSize=tileSize, tileThickness=tileThickness, anchor=anchor, orient=orient);
}

module assembledView(basketLiteGrid, xUnits, yUnits, zUnits, dualConnectorSpacing, attachToGridThickness, explosionDistance) {
  basketXmillimeter = xUnits * tileSize;
  basketYmillimeter = yUnits * tileSize;
  basketZmillimeter = zUnits * tileSize;
  attachTo_lite_grid = attachToGridThickness == "Lite";

  hide("hidden")

    tag_this("hidden")
      cube([basketXmillimeter, basketYmillimeter, basketZmillimeter], anchor=BOTTOM) {
        $anchor_inside = false;
        // Bottom Panel
        attach(BOTTOM, TOP, overlap=-explosionDistance)
          color_this("black")
            openGridWithDefaults(xUnits, yUnits, tileThickness) {
              // Front and Back Bottom Beam
              attach([FRONT, BACK], RIGHT, align=TOP, overlap=-explosionDistance)
                bottomXBeam();
              // Left and Right Bottom Beam
              //align()
              attach([LEFT, RIGHT], RIGHT, align=TOP, overlap=-explosionDistance)
                bottomYBeam();
            }

        // Left and Right Panels
        attach([LEFT, RIGHT], TOP, overlap=-explosionDistance)
          color_this("red")
            openGridWithDefaults(yUnits, zUnits, tileThickness);

        // Front and Back Panels
        attach([FRONT, BACK], TOP, overlap=-explosionDistance)
          color_this("violet")
            openGridWithDefaults(xUnits, zUnits, tileThickness) {

              // Vertical Beam
              attach([RIGHT, LEFT], RIGHT, align=TOP, overlap=-explosionDistance)
                verticalBeam();
            }
        // Top Dual Sided Snaps
        echo(basketLiteGrid=basketLiteGrid);
        xcopies(spacing=basketXmillimeter - tileSize, n=2, sp=[0, 0, 0])
          position(TOP + LEFT + FRONT)
            move([tileSize / 2, 0, -tileSize / 2])
              dualSidedSnap(Lite=basketLiteGrid, Lite_B=attach_to_lite_grid, Directional=true, Spacing=Dual_connector_spacing, anchor=TOP, orient=BACK, spin=180);
        // Bottom Dual Sided Snaps
        xcopies(spacing=basketXmillimeter - tileSize, n=2, sp=[0, 0, 0])
          position(BOTTOM + LEFT + FRONT)
            move([tileSize / 2, 0, tileSize / 2])
              dualSidedSnap(Lite=basketLiteGrid, Lite_B=attach_to_lite_grid, Directional_A=true, Directional_B=false, Spacing=dualConnectorSpacing, anchor=TOP, orient=BACK, spin=180);
      }
}

module plate_z_beams() {
  xcopies(n=4, spacing=(tileThickness * 3))
    yrot(-45)
      verticalBeam(anchor="print_surface");
}

module plate_xy_beams() {
  xcopies(n=2, spacing=-(tileThickness * 3), sp=-(tileThickness * 3) / 2)
    yrot(-45)
      bottomXBeam();
  xcopies(n=2, spacing=(tileThickness * 3), sp=(tileThickness * 3) / 2)
    yrot(-45)
      bottomYBeam();
}

module plate_bottom_grid() {
  color_this("black")
    openGridWithDefaults(Basket_X_Units, Basket_Y_Units, tileThickness, anchor=BOTTOM);
}

module plate_side_grid() {
  color_this("red")
    openGridWithDefaults(Basket_Y_Units, Basket_Z_Units, tileThickness, anchor=BOTTOM, spin=90);
}

module plate_frontback_grid() {
  color_this("violet")
    openGridWithDefaults(Basket_X_Units, Basket_Z_Units, tileThickness);
}
