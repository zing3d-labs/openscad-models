include <BOSL2/std.scad>

//intersection() 
difference() {
  connector();

  //xmove(x=20)
  color("blue")
    import("./opengrid_connector.stl");
}

function connector_height() = 2.2 - .01;
function connector_radius() = 2.5;
function connector_length() = 9.9;
module connector() {
  $fn = 200;

  rot([90, 90, 0])
    diff() union()
        cube(size=[connector_length() - 2 * connector_radius(), 2 * connector_radius(), connector_height()], center=true) {
          attach(LEFT, RIGHT, overlap=connector_radius())
            cylinder(h=connector_height(), r=connector_radius(), center=true);
          attach(RIGHT, LEFT, overlap=connector_radius())
            cylinder(h=connector_height(), r=connector_radius(), center=true);
          tag("remove")
            attach([BACK, FRONT], FRONT, overlap=connector_radius() * 0.3)
              cylinder(h=connector_height() + 1, r=connector_radius(), center=true);
        }
}
