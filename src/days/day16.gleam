import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleam/pair
import gleam/result
//import gleam/int
import gleam/dict.{type Dict}
import simplifile as file
import util/matrix.{type Matrix, type Char}
import util/compass.{type Direction, type Coord}
import util/dijkstra.{type SuccessorNodes}

const day = "16"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"
//const input_file = "input/" <> day <> "_example2.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.split("\n")
  |> matrix.from_list_of_strings(".")
}

type NodeId = #(Coord, Direction)

fn make_graph_fn(input: Matrix(Char)) -> SuccessorNodes(NodeId)
{
  fn(n: NodeId) -> Dict(NodeId, Int) {
    let #(coord, dir) = n
    compass.cardinals
    |> list.filter(fn(d) { d != compass.opposite(dir) }) //don't go backwards
    |> list.map(fn(d) { #(compass.get_neighbour(coord, d), d) })
    |> list.filter(fn(coord_dir) {
      case dict.get(input.data, coord_dir.0) {
        Ok(x) if x != "E" -> False //Obstacle in the way.
        _                 -> True  //Otherwise, found a gap
      }
    })
    |> list.map(fn(coord_dir) {
      #(coord_dir, case coord_dir.1 == dir { True -> 1  False -> 1001 })
    })
    |> dict.from_list
  }
}

pub fn part1()
{
  let input = parse()
  //matrix.draw(input, ".")

  let f = make_graph_fn(input)
  let assert Ok(start_pt) = matrix.find(input, fn(v) { v == "S" })
  let assert Ok(end_pt)   = matrix.find(input, fn(v) { v == "E" })

  let shortest_path = dijkstra.dijkstra(f, #(start_pt, compass.E)).distances
  |> dict.filter(fn(k, _v) { k.0 == end_pt })
  |> dict.values
  |> list.sort(int.compare)
  |> list.first
  |> result.lazy_unwrap(fn() { panic as "no result" })

  io.debug(shortest_path)
}

pub fn part2()
{
  let input = parse()

  let assert Ok(start_pt) = matrix.find(input, fn(v) { v == "S" })
  let assert Ok(end_pt)   = matrix.find(input, fn(v) { v == "E" })

  let shortest_paths = make_graph_fn(input)
  |> dijkstra.dijkstra_all(#(start_pt, compass.E))

  let sorted_distances_to_end_pts = shortest_paths
  |> fn(x) { x.distances }
  |> dict.filter(fn(k, _v) { k.0 == end_pt })
  |> dict.to_list
  |> list.sort(fn(a,b) { int.compare(a.1, b.1) })

  let shortest_distance = sorted_distances_to_end_pts
  |> list.first
  |> result.lazy_unwrap(fn() { panic as "no result" })
  |> pair.second

  let shortest_end_pts = sorted_distances_to_end_pts
  |> list.take_while(fn(x) { x.1 == shortest_distance })
  |> list.map(pair.first)
  
  let shortest_paths = shortest_end_pts
  |> list.flat_map(fn(end_pt) { dijkstra.shortest_paths(shortest_paths, end_pt).0 })

  let path_coords = shortest_paths
  |> list.flatten
  |> list.map(fn(x) { x.0 })
  |> list.unique
  
  // let new_data = path_coords
  // |> list.fold(input.data, fn(acc, x) { dict.insert(acc, x, "O") })

  // let input = matrix.Matrix(..input, data:new_data)

  // matrix.draw(input, ".")
  
  io.debug(list.length(path_coords))
}
