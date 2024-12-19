//==================================================================================
//
//               Advent Of Code 2024 - Day 18 - Visualisation
//
// Author:  Heath Raftery
// Origin:  https://github.com/hraftery/aoc2024/blob/main/src/days/day18.scad
// License: Creative Commons - Attribution - Share Alike
//
// See Reddit for discussion: https://www.reddit.com/r/adventofcode/comments/1hhln7j/2024_day_18_part_2_openscad_into_the_third/
//
//==================================================================================


//===========
// Constants
//===========

//NOTE: width is in y direction, length is in x direction, height is in z direction
//      thickness is in direction perpendicular to its length.
base_h = 2;
wall_t = 0.5;
wall_h = -0.2;
cell_w = 4;
cell_l = cell_w;
byte_w = 2.5;
byte_l = byte_w;
byte_h = 1.4;
path_t = 1.5;
path_h = 0.6;
blocker_h = 4;
tol = 0.001;


//========
//  Data
//========

//NOTE: To put the OpenSCAD orgin at the top left, the x and y axes swapped.
//      So num_cols is in the OpenSCAD y direction and locs are interpreted in [y,x] order.
example = true;
num_cols = example ? 7 : 71;
num_rows = num_cols;
byte_locs = example ?
  [ [5,4], [4,2], [4,5], [3,0], [2,1], [6,3], [2,4], [1,5], [0,6], [3,3], [2,6], [5,1], [1,2], [5,5], [2,5], [6,5], [1,4], [0,4], [6,4], [1,1], [6,1] ] :
  [ /* your input data here */ ];
path_locs = example ?
  [ [0,0], [0,1], [0,2], [0,3], [1,3], [2,3], [2,2], [3,2], [3,1], [4,1], [4, 0], [5, 0], [6, 0], [6, 1] ] :
  [ /* your calculated path here */ ];


//===========
// Functions
//===========

function arg(p0, p1) = atan2(p1[1]-p0[1], p1[0]-p0[0]);


//=========
// Modules
//=========

module walls(t, h) {
  intersection() {
    union() {
      walls_w(t, h, 0);
      walls_l(t, h, 0);
    }
    translate([-tol, -tol, -tol])
      cube([num_rows*cell_l + 2*tol, num_cols*cell_w + 2*tol, h + 2*tol]);
  }
}

module walls_w(t, h, index) {
  translate([-t/2, -tol, 0])
    cube([t, num_cols*cell_w + 2*tol, h+tol]);
  if(index < num_rows) {
    translate([cell_l, 0, 0])
      walls_w(t, h, index + 1);
  }
}

module walls_l(t, h, index) {
  translate([-tol, -t/2, 0])
    cube([num_rows*cell_l + 2*tol, t, h+tol]);
  if(index < num_cols) {
    translate([0, cell_w, 0])
      walls_l(t, h, index + 1);
  }
}

module bytes(w, l) {
  for(loc=byte_locs) {
    translate([loc[1]*cell_l + cell_l/2 - byte_l/2,
               loc[0]*cell_w + cell_w/2 - byte_w/2,
               0])
      cube([byte_l, byte_w, byte_h]);
  }
}

module path(t, index=0, in=false) {
  for(i=[0:len(path_locs)-2]) {
    translate([path_locs[i][1]*cell_l + cell_l/2,
               path_locs[i][0]*cell_w + cell_w/2,
               0])
      rotate([0, 0, -arg(path_locs[i], path_locs[i+1])])
        translate([-t/2, -t/2, 0])
          cube([t, cell_w + t, path_h]);
  }
}


//========
//  Main
//========

union() {
  if(wall_h < 0)
    difference() {
      cube([num_rows*cell_l, num_cols*cell_w, base_h]);
      translate([0, 0, base_h+wall_h])
        walls(wall_t, -wall_h);
  }
  else
    union() {
      cube([num_rows*cell_l, num_cols*cell_w, base_h]);
      translate([0, 0, base_h])
        walls(wall_t, wall_h);
  }
  
  translate([0, 0, base_h])
    bytes(byte_w, byte_h);

  translate([0, 0, base_h])
    path(path_t);
}
