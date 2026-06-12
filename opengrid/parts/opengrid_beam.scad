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

// Style of the aesthetic end at corner 1. Extended fills the corner gap with adjacent beams.
Corner_1 = "Extended"; // [Flush,Extended]

// Style of the aesthetic end at corner 2. Extended fills the corner gap with adjacent beams.
Corner_2 = "Extended"; // [Flush,Extended]

{

  //opengrid_beam(lengthUnits=units, tileThickness=6.8, anchor="print_surface", orient=DOWN)
  tileThickness = Grid_Version == "Full" ? 6.8 : 4.0;
  echo(tileThickness1=tileThickness);
  yrot(-45)
    opengrid_beam(
      lengthUnits=Units, tileThickness=tileThickness,
      connectorsA=Connectors_Side_A, connectorsB=Connectors_Side_B,
      corner1=Corner_1, corner2=Corner_2
    );

  module opengrid_beam(lengthUnits, tileSize = 28, tileThickness, connectorsA = true, connectorsB = true, corner1 = "Flush", corner2 = "Flush", anchor, spin, orient) {

    echo(Grid_Version=Grid_Version);
    echo(tileThickness=tileThickness);
    cutterDistance = tileThickness * 0.5;
    echo(cutterDistance=cutterDistance);
    cutterDistanceHypoteneuse = (sqrt(2) * cutterDistance);
    echo(cutterDistanceHypoteneuse=cutterDistanceHypoteneuse);
    print_surface_offset = cutterDistance - (cutterDistance * sin(45));
    echo(print_surface_offset=print_surface_offset);

    print_surface_edge_offset = (sqrt(2) * cutterDistance) - (tileThickness / 2);
    echo(print_surface_edge_offset=print_surface_edge_offset);
    connectors_end_offset = (tileThickness / 2) + (connector_length() / 2);

    halfBeamLength = lengthUnits * tileSize / 2;
    echo(halfBeamLength=halfBeamLength);
    half_beam_thickness = tileThickness / 2;

    module end_cap() {
      p1 = [half_beam_thickness, half_beam_thickness, tileThickness];
      p2 = [-half_beam_thickness, print_surface_edge_offset, 0];
      p3 = [print_surface_edge_offset, -half_beam_thickness, 0];

      my_plane = plane3pt(p1, p2, p3);

      bottom_half(z=(.75 * tileThickness))
        half_of(my_plane, s=3 * tileThickness)
          linear_sweep(beam_shape(), height=tileThickness, center=false);
    }

    ext1 = corner1 == "Extended" ? tileThickness : 0;
    ext2 = corner2 == "Extended" ? tileThickness : 0;

    beam_length = tileSize * lengthUnits;
    size = [tileThickness, beam_length, tileThickness];
    anchors = [
      named_anchor("print_surface", [-print_surface_offset, 0, -print_surface_offset], BOTTOM + LEFT, 0),
      named_anchor("print_surface_left", [-tileThickness / 2, 0, print_surface_edge_offset], BOTTOM + LEFT, 0),
      named_anchor("print_surface_right", [print_surface_edge_offset, 0, -tileThickness / 2], BOTTOM + LEFT, 0),
      named_anchor("print_surface_front", [-print_surface_offset, -halfBeamLength, -print_surface_offset], BOTTOM + LEFT, 0),
      named_anchor("print_surface_front_left", [-tileThickness / 2, -halfBeamLength, print_surface_edge_offset], BOTTOM + LEFT, 0),
      named_anchor("print_surface_front_right", [print_surface_edge_offset, -halfBeamLength, -tileThickness / 2], BOTTOM + LEFT, 0),
      named_anchor("print_surface_back", [-print_surface_offset, halfBeamLength, -print_surface_offset], BOTTOM + LEFT, 0),
      named_anchor("print_surface_back_left", [-tileThickness / 2, halfBeamLength, print_surface_edge_offset], BOTTOM + LEFT, 0),
      named_anchor("print_surface_back_right", [print_surface_edge_offset, halfBeamLength, -tileThickness / 2], BOTTOM + LEFT, 0),
      named_anchor("connectors_end_a", [0, 0, connectors_end_offset], TOP, 0),
      named_anchor("connectors_end_b", [connectors_end_offset, 0, 0], RIGHT, 0),
    ];

    function beam_shape() =
      [
        [-half_beam_thickness, half_beam_thickness],
        [half_beam_thickness, half_beam_thickness],
        [half_beam_thickness, -half_beam_thickness],
        [print_surface_edge_offset, -half_beam_thickness],
        [-half_beam_thickness, print_surface_edge_offset],
      ];

    attachable(size=size, anchor=anchor, spin=spin, orient=orient, anchors=anchors) {
      diff()
        union()
          rot([90, 0, 0])
            linear_sweep(beam_shape(), height=beam_length, center=true) {
              if (connectorsB)
                zcopies(spacing=tileSize, n=lengthUnits - 1, sp=-(halfBeamLength - tileSize))
                  right(half_beam_thickness)
                    yrot(90)
                      color("blue")
                        top_half()
                          up(0.3)
                            connector();
              if (connectorsA)
                zcopies(spacing=tileSize, n=lengthUnits - 1, sp=-(halfBeamLength - tileSize))
                  back(half_beam_thickness)
                    rot([-90, 90, 0])
                      color("lightblue")
                        top_half()
                          up(0.3)
                            connector();
              if (ext1 > 0) {
                color("orange")
                  move([0, 0, beam_length / 2])
                    rot([0, 0, 0])
                      end_cap();
              }
              if (ext2 > 0) {
                color("pink")
                  move([0, 0, -(beam_length / 2)])
                    zflip()
                      end_cap();
              }
            }
      children();
    }
  }
}
