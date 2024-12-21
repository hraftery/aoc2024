import gleam/dict.{type Dict}
import gleam/list
import gleam/set
import util/util

pub type Direction
{
  N
  NE
  E
  SE
  S
  SW
  W
  NW
}

pub type Coord = #(Int, Int)
pub type Coords = List(Coord)
pub type Directions = List(Direction)

//Oh how I miss integer enums. The next ~100 lines is mostly just hand
//made functionality normally implicitly provided by integer enums.
pub const all:       Directions = [N, NE, E, SE, S, SW, W, NW]
pub const all_ccw:   Directions = [N, NW, W, SW, S, SE, E, NE]
pub const cardinals: Directions = [N, E, S, W]
pub const ordinals:  Directions = [NE, SE, SW, NW]

pub fn to_degrees(dir: Direction) -> Int
{
  case dir {
    N  -> 0
    NE -> 45
    E  -> 90
    SE -> 135
    S  -> 180
    SW -> 225
    W  -> 270
    NW -> 315
  }
}

pub fn from_degrees(deg: Int) -> Direction
{
  case deg % 360 {
    0   -> N
    45  -> NE
    90  -> E
    135 -> SE
    180 -> S
    225 -> SW
    270 -> W
    315 -> NW
    _   -> panic
  }
}

pub fn turn_clockwise(dir: Direction) -> Direction
{
  case dir {
    N  -> NE
    NE -> E
    E  -> SW
    SE -> S
    S  -> SW
    SW -> W
    W  -> NW
    NW -> N
  }
}

pub fn turn_anticlockwise(dir: Direction) -> Direction
{
  case dir {
    N  -> NW
    NE -> N
    E  -> NE
    SE -> E
    S  -> SE
    SW -> S
    W  -> SW
    NW -> W
  }
}

pub fn turn_right_90(dir: Direction) -> Direction
{
  from_degrees(to_degrees(dir) + 90)
}

pub fn turn_left_90(dir: Direction) -> Direction
{
  from_degrees(to_degrees(dir) - 90)
}

pub fn opposite(dir: Direction) -> Direction
{
  case dir {
    N  -> S
    NE -> SW
    E  -> W
    SE -> NW
    S  -> N
    SW -> NE
    W  -> E
    NW -> SE
  }
}

pub fn get_neighbour(coord: Coord, dir: Direction) -> Coord
{
  let #(x, y) = coord
  case dir {
    N  -> #(x    , y - 1)
    NE -> #(x + 1, y - 1)
    E  -> #(x + 1, y    )
    SE -> #(x + 1, y + 1)
    S  -> #(x    , y + 1)
    SW -> #(x - 1, y + 1)
    W  -> #(x - 1, y    )
    NW -> #(x - 1, y - 1)
  }
}

pub fn get_neighbours_in_direction(coord: Coord, dir: Direction, len: Int) -> Coords
{
  let #(x, y) = coord
  let mod = len - 1 //don't include starting point
  case dir {
    N  -> list.zip(list.repeat(x, len),    list.range(y, y - mod))
    NE -> list.zip(list.range(x, x + mod), list.range(y, y - mod))
    E  -> list.zip(list.range(x, x + mod), list.repeat(y, len))
    SE -> list.zip(list.range(x, x + mod), list.range(y, y + mod))
    S  -> list.zip(list.repeat(x, len),    list.range(y, y + mod))
    SW -> list.zip(list.range(x, x - mod), list.range(y, y + mod))
    W  -> list.zip(list.range(x, x - mod), list.repeat(y, len))
    NW -> list.zip(list.range(x, x - mod), list.range(y, y - mod))
  }
}

pub fn get_neighbours(coord: Coord, max_dist: Int, directions: Directions) -> Dict(Coord, Int)
{
  do_get_neighbours([coord], 1, max_dist, directions, dict.new())
  |> dict.delete(coord) //don't include starting point
}

fn do_get_neighbours(front_line: Coords, dist: Int, max_dist: Int, directions: Directions, ret: Dict(Coord, Int)) -> Dict(Coord, Int)
{
  case dist > max_dist
  {
    True -> ret
    False -> {
      let new_coords = front_line
        |> list.fold(set.new(), fn(acc, coord) {
          list.fold(directions, acc, fn(acc, d) {
            set.insert(acc, get_neighbour(coord, d))
          })
        })
        |> set.filter(util.has_no_key(ret, _))
        |> set.to_list

      let ret = list.fold(new_coords, ret, fn(acc, coord) {
        dict.insert(acc, coord, dist)
      })
      do_get_neighbours(new_coords, dist + 1, max_dist, directions, ret)
    }
  }
}

pub fn get_direction(coord_pair: #(Coord, Coord)) -> Result(Direction, Nil) {
  [N, NE, E, SE, S, SW, W, NW]
  |> list.find(fn(d) { get_neighbour(coord_pair.0, d) == coord_pair.1 })
}
