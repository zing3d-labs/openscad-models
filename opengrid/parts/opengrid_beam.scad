use <opengrid_connector.scad>
include <BOSL2/std.scad>

// Number of Opengrid Units the beam connects.
Units = 4;

// Grid version
Grid_Version = "Lite"; // [Full,Lite]

// Include connectors on side A
Connectors_Side_A = true;

// Include connectors on side B
Connectors_Side_B = true;

{

  tileThickness = Grid_Version == "Full" ? 6.8 : 4.0;
  //tileThickness=6.8;
  //opengrid_beam(lengthUnits=units, tileThickness=6.8, anchor="print_surface", orient=DOWN)
  echo(tileThickness1=tileThickness);
  yrot(-45)
    opengrid_beam(lengthUnits=Units, tileThickness=tileThickness,
                  connectorsA=Connectors_Side_A, connectorsB=Connectors_Side_B);

  module opengrid_beam(lengthUnits, tileSize = 28, tileThickness, connectorsA = true, connectorsB = true, anchor, spin, orient) {
    echo(Grid_Version=Grid_Version);
    echo(tileThickness=tileThickness);
    cutterDistance = tileThickness * 0.5;
    echo(cutterDistance=cutterDistance);
    cutterDistanceHypoteneuse = (sqrt(2) * cutterDistance);
    echo(cutterDistanceHypoteneuse=cutterDistanceHypoteneuse);
    print_surface_offset = cutterDistance - (cutterDistance * sin(45));
    echo(print_surface_offset=print_surface_offset);

    print_surface_edge_offset = (tileThickness / 2) - (sqrt(2) * cutterDistance);
    echo(print_surface_edge_offset=print_surface_edge_offset);
    connectors_end_offset = (tileThickness / 2) + (connector_length() / 2);

    halfBeamLength = lengthUnits * tileSize / 2;
    echo(halfBeamLength=halfBeamLength);

    size = [tileThickness, tileSize * lengthUnits, tileThickness];
    anchors = [
      named_anchor("print_surface", [-print_surface_offset, 0, -print_surface_offset], BOTTOM + LEFT, 0),
      named_anchor("print_surface_left", [-tileThickness / 2, 0, -print_surface_edge_offset], BOTTOM + LEFT, 0),
      named_anchor("print_surface_right", [-print_surface_edge_offset, 0, -tileThickness / 2], BOTTOM + LEFT, 0),
      named_anchor("print_surface_front", [-print_surface_offset, -halfBeamLength, -print_surface_offset], BOTTOM + LEFT, 0),
      named_anchor("print_surface_front_left", [-tileThickness / 2, -halfBeamLength, -print_surface_edge_offset], BOTTOM + LEFT, 0),
      named_anchor("print_surface_front_right", [-print_surface_edge_offset, -halfBeamLength, -tileThickness / 2], BOTTOM + LEFT, 0),
      named_anchor("print_surface_back", [-print_surface_offset, halfBeamLength, -print_surface_offset], BOTTOM + LEFT, 0),
      named_anchor("print_surface_back_left", [-tileThickness / 2, halfBeamLength, -print_surface_edge_offset], BOTTOM + LEFT, 0),
      named_anchor("print_surface_back_right", [-print_surface_edge_offset, halfBeamLength, -tileThickness / 2], BOTTOM + LEFT, 0),
      named_anchor("connectors_end_a", [0, 0, connectors_end_offset], TOP, 0),
      named_anchor("connectors_end_b", [connectors_end_offset, 0, 0], RIGHT, 0),
    ];

    attachable(size=size, anchor=anchor, spin=spin, orient=orient, anchors=anchors) {
      diff()
        union()
          cube(size=size, center=true) {
            if (connectorsB)
              ycopies(spacing=tileSize, n=lengthUnits - 1, sp=0)
                ymove(-(lengthUnits * tileSize) / 2 + tileSize)
                  attach(RIGHT)
                    color("blue")
                      top_half()
                        up(0.3)
                          connector();
            if (connectorsA)
              ycopies(spacing=tileSize, n=lengthUnits - 1, sp=0)
                ymove(-(lengthUnits * tileSize) / 2 + tileSize)
                  attach(TOP, spin=90)
                    color("lightblue")
                      top_half()
                        up(0.3)
                          connector();
            tag("remove") attach(parent=BOTTOM + LEFT, child=TOP, overlap=cutterDistance, shiftout=.01)
                cube(size=[tileThickness, tileSize * lengthUnits + 1, tileThickness], center=true);
          }
      children();
    }
  }
}
