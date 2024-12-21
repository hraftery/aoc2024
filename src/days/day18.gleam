import gleam/result
import gleam/dict.{type Dict}
import gleam/io
import gleam/string
import gleam/int
import gleam/list.{Continue, Stop}
import gleam/set.{type Set}
import simplifile as file
import util/util
import util/matrix.{Matrix, type Matrix, type Char}
import util/compass.{type Coord, type Coords}
import util/dijkstra.{type SuccessorNodes}


const day = "18"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.split("\n")
  |> list.map(string.split(_, ","))
  |> list.map(list.map(_, int.parse))
  |> list.map(fn(x) {
    let assert [Ok(a), Ok(b)] = x
    #(a,b)
  })
}

fn space_size() -> #(Int, Int) {
  case string.contains(input_file, "example") {
    True  -> #(7, 7)
    False -> #(71, 71)
  }
}

fn take_scenario(coords: Coords) -> Coords
{
  case string.contains(input_file, "example") {
    True  -> list.take(coords, 12)
    False -> list.take(coords, 1024)
  }
}

fn make_matrix(coords: Coords) -> Matrix(Char)
{
  let data = coords
  |> list.map(fn(coord) { #(coord, "#") })
  |> dict.from_list
  let #(rows, cols) = space_size()
  Matrix(data: data, num_rows:rows, num_cols: cols)
}

type NodeId = Coord

fn make_graph_fn(input: Matrix(Char)) -> SuccessorNodes(NodeId)
{
  fn(coord: NodeId) -> Dict(NodeId, Int) {
    compass.cardinals
    |> list.map(fn(d) { compass.get_neighbour(coord, d) })
    |> list.filter(fn(coord) {
      case matrix.valid_coord(input, coord), dict.get(input.data, coord) {
        False, _ -> False //Out of space
        _, Ok(_) -> False //Obstacle in the way.
        _, _     -> True  //Otherwise, found a gap
      }
    })
    |> list.map(fn(coord) {
      #(coord, 1)
    })
    |> dict.from_list
  }
}

fn make_graph_fn2(coords: Set(Coord)) -> SuccessorNodes(Coord)
{
  let size = space_size()

  fn(coord: Coord) -> Dict(Coord, Int) {
    compass.cardinals
    |> list.map(fn(d) { compass.get_neighbour(coord, d) })
    |> list.filter(fn(coord) {
      coord.0 >= 0 && coord.0 < size.0 &&
      coord.1 >= 0 && coord.1 < size.1 &&
      !set.contains(coords, coord)
    })
    |> list.map(fn(coord) {
      #(coord, 1)
    })
    |> dict.from_list
  }
}

pub fn part1()
{
  let input = parse()
  let space = make_matrix(take_scenario(input))
  let start_pt = #(0, 0)
  let end_pt = #(space.num_rows - 1, space.num_cols - 1)

  //matrix.draw(space, ".")

  let shortest_path = make_graph_fn(space)
  |> dijkstra.dijkstra(start_pt)
  |> dijkstra.shortest_path(end_pt)

  // let matrix = shortest_path.0
  // |> list.fold(space.data, fn(acc, x) { dict.insert(acc, x, "0") })
  // |> fn(new_data) { Matrix(..space, data: new_data) }
  // matrix.draw(matrix, ".")

  io.debug(shortest_path.1)
}

pub fn part2()
{
  let input = parse()
  let size = space_size()
  
  let start_pt = #(0, 0)
  let end_pt = #(size.0 - 1, size.1 - 1)

  let ans = list.fold_until(input, set.new(), fn(space, byte) {
    let space = set.insert(space, byte)

    let can_reach_end_pt = make_graph_fn2(space)
    |> dijkstra.dijkstra(start_pt)
    |> dijkstra.has_path_to(end_pt)

    case can_reach_end_pt {
      True  -> Continue(space)
      False -> Stop(space)
    }
  })
  |> set.size()
  |> util.decrement
  |> util.get(input, _)
  |> result.lazy_unwrap(fn() { panic as "no result" })
  |> fn(byte) { int.to_string(byte.0) <> "," <> int.to_string(byte.1) }

  io.println(ans)
}
