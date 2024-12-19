import gleam/io
import gleam/string
import gleam/int
import gleam/list
import gleam/set.{type Set}
import simplifile as file
import util/util
import util/array2d.{type Array2D, type Char}
import util/compass.{type Direction, type Coord, type Coords}


const day = "12"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"
//const input_file = "input/" <> day <> "_example2.txt"
//const input_file = "input/" <> day <> "_example3.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.split("\n")
  |> array2d.from_list_of_strings
}

pub type Edge = #(Coord, Direction)
pub type Region {
  Region(plant: Char, coords: Coords, edges: Set(Edge))
}
type Perimeter = List(Edge) //An ordered list of edges

fn find_all_regions(map: Array2D(Char)) -> List(Region)
{
  map
  |> array2d.coords
  |> set.from_list
  |> do_find_all_regions(map, _)
}

fn do_find_all_regions(map: Array2D(Char), remaining_coords: Set(Coord)) -> List(Region)
{
  case set.is_empty(remaining_coords) {
    True  -> [] //done
    False -> {
      let assert Ok(next_region_start_pt) = list.first(set.to_list(remaining_coords))
      let new_region = find_region(map, next_region_start_pt)
      let new_remaining_coords = set.difference(remaining_coords,
                                                set.from_list(new_region.coords))
      [new_region, ..do_find_all_regions(map, new_remaining_coords)]
    }
  }
}

type RegionAcc {
  RegionAcc(plant: Char, region: Coords, edges: Set(Edge), front_line: Coords)
}

fn find_region(map: Array2D(Char), start_pt: Coord) -> Region
{
  let assert Ok(plant) = array2d.get(map, start_pt)
  expand_region(map, RegionAcc(plant, [start_pt], set.new(), [start_pt]))
}

fn expand_region(map: Array2D(Char), region_acc: RegionAcc) -> Region
{
  //io.debug(region_acc)
  let in = RegionAcc(..region_acc, front_line: [])
  let out = list.fold(region_acc.front_line, in, fn(outer_acc, pt) {
    [compass.N, compass.E, compass.S, compass.W]
    |> list.map(fn(dir) { #(dir, array2d.get_neighbour(map, pt, dir)) })
    |> list.fold(outer_acc, fn(acc, dir_neighbour) {
      case dir_neighbour.1 {
        #(new_pt, Ok(p)) if p == acc.plant
          -> {  case list.contains(acc.region, new_pt) || list.contains(acc.front_line, new_pt) {
                  True  -> acc //going backwards or already counted, so no change
                  False -> RegionAcc(..acc, front_line: [new_pt, ..acc.front_line]) // expand
                }
             }
        _ -> RegionAcc(..acc, edges: set.insert(acc.edges, #(pt, dir_neighbour.0))) // off map or wrong plant
      }
    })
  })

  case list.is_empty(out.front_line) {
    True -> Region(out.plant, coords:out.region, edges:out.edges) //we're done
    False -> expand_region(map, //otherwise, go again after expanding the region to the new front_line
                           RegionAcc(..out, region: list.flatten([out.region, out.front_line])))
  }
}

fn find_perimeters(edges: Set(Edge)) -> List(Perimeter)
{
  case set.is_empty(edges) {
    True  -> []
    False -> {
      let next_perimeter = find_perimeter(edges)
      //Seems crazy I need to create "remaining" again, but it's too hard to return a
      //side-effect when you need to use recursion for looping.
      let remaining_edges = set.difference(edges, set.from_list(next_perimeter))

      [next_perimeter, ..find_perimeters(remaining_edges)]
    }
  }
}

fn find_perimeter(edges: Set(Edge)) -> Perimeter
{
  let as_list = set.to_list(edges) //unfortunately with no set.pop, we're going to be stuck without a list
  let assert Ok(#(first,rest)) = util.first_rest(as_list)
  do_find_perimeter(first, first, rest)
}

fn do_find_perimeter(start: Edge, curr: Edge, remaining: List(Edge)) -> Perimeter
{
  let #(#(curr_x, curr_y) as curr_pt, curr_dir) = curr

  //otherwise, find the next edge (clockwise)
  let #(before_next, next_rest) = list.split_while([start, ..remaining], fn(e) {
    let #(#(x,y) as pt, dir) = e
    let is_next = case curr_dir {
      compass.N -> pt == curr_pt && dir == compass.E ||                      //right turn
                   x == curr_x + 1 && y == curr_y - 1 && dir == compass.W || //left turn
                   x == curr_x + 1 && y == curr_y     && dir == compass.N    //straight
      compass.E -> pt == curr_pt && dir == compass.S ||                      //right turn
                   x == curr_x + 1 && y == curr_y + 1 && dir == compass.N || //left turn
                   x == curr_x     && y == curr_y + 1 && dir == compass.E    //straight
      compass.S -> pt == curr_pt && dir == compass.W ||                      //right turn
                   x == curr_x - 1 && y == curr_y + 1 && dir == compass.E || //left turn
                   x == curr_x - 1 && y == curr_y     && dir == compass.S    //straight
      compass.W -> pt == curr_pt && dir == compass.N ||                      //right turn
                   x == curr_x - 1 && y == curr_y - 1 && dir == compass.S || //left turn
                   x == curr_x     && y == curr_y - 1 && dir == compass.W    //straight
      _ -> panic as "Diagonals not supported."
    }
    !is_next
  })
  let assert Ok(#(next, after_next)) = util.first_rest(next_rest)

  case next == start {
    True  -> [curr] //That's a wrap
    False -> [curr, ..do_find_perimeter(start, next, list.flatten([before_next, after_next]))]
  }
}

fn count_sides(perimeter: Perimeter) -> Int
{
  let assert Ok(first) = list.first(perimeter)

  perimeter
  |> list.append([first]) // why so hard to add the first to the end?
  |> list.window_by_2
  |> list.filter(fn (x) { x.0.1 != x.1.1 }) //if direction doesn't match, it's a corner
  |> list.length //in a polygon the number of corners is the number of sides
}

pub fn part1()
{
  let input = parse()
  //let coords = set.from_list(array2d.coords(input))
  //let region = find_region(input, #(0,0))
  let regions = find_all_regions(input)

  let ans = regions
  |> list.map(fn(r) {
    #(list.length(r.coords), set.size(r.edges))
  })
  |> list.fold(0, fn(acc, area_len) {
    acc + area_len.0 * area_len.1
  })

  io.debug(ans)
}

pub fn part2()
{
  let input = parse()
  //let region = find_region(input, #(0,0))
  let regions = find_all_regions(input)

//   list.each(regions, fn(r) {
//     io.debug(r.plant)
// //    io.debug(set.to_list(r.edges))
//     io.debug(find_perimeters(r.edges))
//   })
  
  let ans = regions
  |> list.map(fn(r) {
    #(list.length(r.coords),
      int.sum(list.map(find_perimeters(r.edges), count_sides)))
  })
  |> list.fold(0, fn(acc, area_len) {
    acc + area_len.0 * area_len.1
  })

  io.debug(ans)
}
