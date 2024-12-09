import gleam/list
import gleam/io
import gleam/string
//import gleam/int
//import gleam/list
import simplifile as file
import util/array2d.{type Array2D, type Char, type Coord, type Coords}
import util/compass.{type Direction}


const day = "06"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.split("\n")
  |> array2d.from_list_of_strings
}

fn determine_gaurds_route(map: Array2D(Char)) -> Coords
{
  let assert Ok(start_loc) = array2d.locate(map, fn(x) { x == "^" } )
  
  do_gaurds_route(map, [start_loc], compass.N)
}

fn do_gaurds_route(map: Array2D(Char), route: Coords, dir: Direction) -> Coords
{
  let assert Ok(curr_pt) = list.first(route)
  case array2d.get_neighbour(map, curr_pt, dir) {
    #(_,      Error(_)) -> route // left the map, so return the route so far
    #(_,      Ok("#"))  -> do_gaurds_route(map, route, compass.turn_right_90(dir))
    #(new_pt, Ok(_))    -> do_gaurds_route(map, [new_pt, ..route], dir)
  }
}

fn does_obstacle_make_a_loop(obs_pt: Coord, map: Array2D(Char), start: Coord) -> Bool
{
  case obs_pt == start {
    True  -> False
    False -> do_obstacle_makes_a_loop(obs_pt, map, [#(start, compass.N)])
  }
}

fn do_obstacle_makes_a_loop(obs_pt: Coord, map: Array2D(Char), route: List(#(Coord, Direction))) -> Bool
{
  let assert Ok(#(curr_pt, curr_dir)) = list.first(route)
  let new_pt_dir_result = case array2d.get_neighbour(map, curr_pt, curr_dir) {
    #(_,       Error(_)) -> Error(Nil) // left the map, so didn't form a loop
    #(new_pt,  Ok(cell)) -> case cell == "#" || new_pt == obs_pt {
                    True -> Ok(#(curr_pt, compass.turn_right_90(curr_dir)))
                   False -> Ok(#(new_pt, curr_dir))}
  }
  case new_pt_dir_result {
    Error(Nil) -> False
    Ok(new_pt_dir) -> case list.contains(route, new_pt_dir) {
      True  -> True //If we've been here before, we're in a loop!
      False -> do_obstacle_makes_a_loop(obs_pt, map, [new_pt_dir, ..route])
    } 
  }
}

pub fn part1()
{
  let ans = parse()
  |> determine_gaurds_route
  |> list.unique
  |> list.length
  
  io.debug(ans)
}

pub fn part2()
{
  let map = parse()
  let gaurd_locs = map
    |> determine_gaurds_route
    |> list.unique
  let assert Ok(start_loc) = array2d.locate(map, fn(x) { x == "^" } )
   
  let ret = list.count(gaurd_locs, does_obstacle_make_a_loop(_, map, start_loc))
  
  io.debug(ret)
}
