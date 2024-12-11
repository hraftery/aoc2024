import gleam/int
import gleam/result
import gleam/io
import gleam/string
import gleam/list
import gleam/dict.{type Dict}
import simplifile as file
import util/array2d.{type Array2D, type Coord, type Coords}
import util/compass


const day = "10"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"
//const input_file = "input/" <> day <> "_example2.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.split("\n")
  |> array2d.from_list_of_strings_of_digits
}

fn find_good_trails(map: Array2D(Int)) -> Dict(Coord, List(Coords))
{
  let trailheads = array2d.locate_all(map, fn(x) { x == 0 } )
  
  trailheads
  |> list.map(fn (th) { #(th, do_find_good_trails(map, [], th)) })
  |> dict.from_list
}

fn do_find_good_trails(map: Array2D(Int), path: Coords, curr_pt: Coord) -> List(Coords)
{
  let assert Ok(curr_val) = array2d.get(map, curr_pt)
  case curr_val == 9 {
    True  -> [list.reverse([curr_pt, ..path])]
    False -> {
      let neighbours = [compass.N, compass.E, compass.S, compass.W]
                       |> list.map(array2d.get_neighbour(map, curr_pt, _))
      let new_pts = list.filter_map(neighbours, fn(n) {
        let #(pt, val) = n
        case val {
          Ok(v) if v == curr_val + 1 -> Ok(pt)
          _                          -> Error(Nil)
        }
      })
      let new_path = [curr_pt, ..path]
      list.flat_map(new_pts, do_find_good_trails(map, new_path, _))
    }
  }
}

// fn do_gaurds_route(map: Array2D(Char), route: Coords, dir: Direction) -> Coords
// {
//   let assert Ok(curr_pt) = list.first(route)
//   case array2d.get_neighbour(map, curr_pt, dir) {
//     #(_,      Error(_)) -> route // left the map, so return the route so far
//     #(_,      Ok("#"))  -> do_gaurds_route(map, route, compass.turn_right_90(dir))
//     #(new_pt, Ok(_))    -> do_gaurds_route(map, [new_pt, ..route], dir)
//   }
// }

pub fn part1()
{
  let input = parse()
  let good_trails = find_good_trails(input)
  //io.debug(good_trails)
  let scores = dict.map_values(good_trails, fn(_k, v) {
    v
    |> list.map(list.last)
    |> result.values
    |> list.unique
    |> list.length
  })
  let ans = int.sum(dict.values(scores))
  io.debug(ans)
}

pub fn part2()
{
  let input = parse()
  let good_trails = find_good_trails(input)
  let num_trails = dict.map_values(good_trails, fn(_k, v) {
    list.length(v)
  })
  //io.debug(num_trails)
  let ans = int.sum(dict.values(num_trails))
  io.debug(ans)
}
