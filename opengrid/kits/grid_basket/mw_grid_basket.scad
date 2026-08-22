// MakerWorld publishing entry point for the openGrid basket.
//
// grid_basket.scad holds the geometry and the plate decomposition under plain
// names. THIS file is the only place the mw_ names live: mw_plate_1..6(), the
// plates MakerWorld's Parametric Model Maker exports into a multi-plate 3MF,
// and mw_assembly_view(), the preview PMM shows but leaves out of the 3MF.
//
// Why the split, and why it is not stylistic: scad-compiler inlines local
// includes, so mw_plate_* is contagious. Any model that pulled in a library
// carrying those modules would inherit them into its own compiled Customizer
// and silently flip to multi-plate mode -- which costs that model its STL
// downloads on MakerWorld. Publishing behavior must not sit in geometry other
// kits include, so it lives here and grid_basket.scad stays safe to include
// from anywhere.
//
// grid_basket.scad is pulled in with `use`, not `include`, for two reasons:
// its top-level preview render must not fire underneath the plates, and its
// Customizer variables must not compete with the curated set below. That
// means nothing here is inherited implicitly -- every value reaches the
// geometry as an explicit named argument.
//
// TRADEOFF, per MakerWorld's own release note: a script that defines
// mw_plate_N() cannot offer STL downloads. That is a per-model product
// decision, taken deliberately here because a basket has no single-plate
// arrangement that fits a bed.

use <grid_basket.scad>
include <BOSL2/std.scad>

/* [Basket Settings] */

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

/* [Beam Corner Options] */

// Style of beam aesthetic ends of X beams. (Only one of the 3 beams should be set to "Extended" or they will overlap.)
Beam_Corners_X = "Extended"; // [Flush,Extended]

// Style of beam aesthetic ends of Y beams. (Only one of the 3 beams should be set to "Extended" or they will overlap.)
Beam_Corners_Y = "Flush"; // [Flush,Extended]

// Style of beam aesthetic ends of Z beams. (Only one of the 3 beams should be set to "Extended" or they will overlap.)
Beam_Corners_Z = "Flush"; // [Flush,Extended]

/* [Assembly Preview] */

// How far apart to pull the parts in the assembly preview. 0 is the finished basket.
Explosion_distance = 0;

/* [Hidden] */

// Which plate the top-level render emits: 0 for the assembly preview, 1..6
// for that plate on its own. The local build drives this with -D to get one
// STL per plate; MakerWorld ignores it and calls mw_plate_N() directly.
Render_Plate = 0;

basket_lite_grid = false;
basket_tile_thickness = basket_lite_grid ? 3.4 : 6.8;
attach_to_lite_grid = Attach_to_grid_thickness == "Lite";

// Gap between the parts sharing the hardware plate.
plate_part_spacing = 5;

basketRender();

// Top-level render. The if/else chain lives inside a module on purpose:
// scad-compiler keeps module bodies verbatim but drops the else branches of a
// TOP-LEVEL if chain, which would silently pin the published file to the
// assembly view no matter what Render_Plate said.
module basketRender() {
  if (Render_Plate == 0) mw_assembly_view();
  else if (Render_Plate == 1) mw_plate_1();
  else if (Render_Plate == 2) mw_plate_2();
  else if (Render_Plate == 3) mw_plate_3();
  else if (Render_Plate == 4) mw_plate_4();
  else if (Render_Plate == 5) mw_plate_5();
  else if (Render_Plate == 6) mw_plate_6();
  else assert(false, str("Render_Plate must be 0..6, got ", Render_Plate));
}

// Plate 1 -- base panel.
module mw_plate_1() { basketPlate(1); }

// Plate 2 -- left wall.
module mw_plate_2() { basketPlate(2); }

// Plate 3 -- right wall.
module mw_plate_3() { basketPlate(3); }

// Plate 4 -- front wall.
module mw_plate_4() { basketPlate(4); }

// Plate 5 -- back wall.
module mw_plate_5() { basketPlate(5); }

// Plate 6 -- the beams and the dual sided snaps.
module mw_plate_6() { basketPlate(6); }

// Assembled preview. PMM shows this to the user and leaves it out of the
// exported 3MF, so it costs nothing to make it the whole product.
module mw_assembly_view() {
  basket_assembly(
    Basket_X_Units, Basket_Y_Units, Basket_Z_Units,
    tile_thickness=basket_tile_thickness,
    lite_grid=basket_lite_grid,
    attach_lite=attach_to_lite_grid,
    snap_spacing=Dual_connector_spacing,
    corner_x=Beam_Corners_X, corner_y=Beam_Corners_Y, corner_z=Beam_Corners_Z,
    explosion=Explosion_distance
  );
}

// The one place the Customizer values are wired to the shared decomposition,
// so all six plates can never disagree about what they were built from.
module basketPlate(plate) {
  basket_plate(
    plate,
    Basket_X_Units, Basket_Y_Units, Basket_Z_Units,
    tile_thickness=basket_tile_thickness,
    lite_grid=basket_lite_grid,
    attach_lite=attach_to_lite_grid,
    snap_spacing=Dual_connector_spacing,
    corner_x=Beam_Corners_X, corner_y=Beam_Corners_Y, corner_z=Beam_Corners_Z,
    part_spacing=plate_part_spacing
  );
}
