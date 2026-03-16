include <BOSL2/std.scad>
use <../../external/QuackWorks/openGrid/opengrid-snap.scad>

Spacing = 1; // Spacing between the backs of the two snaps
Side_B_Flipped = true; // For directional snaps, orient the opposite way for each side

dualSidedSnap(Lite_A=false, Lite_B=true, Directional_A=true, Directional_B=false, Side_B_Flipped=Side_B_Flipped, Spacing=Spacing);

module dualSidedSnap(Lite = true, Directional = true, Directional_A, Directional_B, Lite_A, Lite_B, Side_B_Flipped = true, Spacing = 3, Tile_Size = 28, anchor, orient, spin) {
  w = Tile_Size - 3.2;
  core = Spacing;
  lite_a_use = Lite_A != undef ? Lite_A : Lite;
  lite_b_use = Lite_B != undef ? Lite_B : Lite;
  snap_thickness_a = lite_a_use ? 3.4 : 6.8;
  snap_thickness_b = lite_b_use ? 3.4 : 6.8;
  directional_a_use = Directional_A != undef ? Directional_A : Directional;
  directional_b_use = Directional_B != undef ? Directional_B : Directional;
  snap_b_spin = (Side_B_Flipped == true ? -90 : 90);
  full_piece_thickness = Spacing + (snap_thickness_a + snap_thickness_b);
  echo(Side_B_Flipped=Side_B_Flipped);
  echo(snap_b_spin=snap_b_spin);
  echo(snap_thickness_a=snap_thickness_a);
  echo(snap_thickness_b=snap_thickness_b);
  echo(full_piece_thickness=full_piece_thickness);

  attachable(size=[w, w, full_piece_thickness], offset=[0, 0, (snap_thickness_a - snap_thickness_b) / 2], anchor=anchor, orient=orient, spin=spin) {
    union()
      cuboid([w, w, core], edges="Z", $fn=2, rounding=3.262743) {
        //Basket side
        color_this(lite_a_use ? "orange" : "blue")
          attach(TOP, TOP, overlap=0.01)
            union()
              openGridSnap(lite=lite_a_use, directional=directional_a_use, anchor=TOP, spin=90);
        // Mount Side
        color_this(lite_b_use ? "green" : "red")
          union()
            attach(BOTTOM, TOP, overlap=0.01) openGridSnap(lite=lite_b_use, directional=directional_b_use, anchor=TOP, spin=snap_b_spin);
      }
    children();
  }
}
