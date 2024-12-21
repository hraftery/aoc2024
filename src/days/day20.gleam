import util/util
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list.{Continue, Stop}
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import gleam/string
import simplifile as file
import util/compass.{type Coord, type Direction}
import util/dijkstra.{type SuccessorNodes}
import util/matrix.{type Char, type Matrix, Matrix}

const day = "20"

const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"

fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.split("\n")
  |> matrix.from_list_of_strings(".")
}

type NodeId = #(Coord, Int) //coord and number of cheats remaining

fn make_graph_fn(input: Matrix(Char)) -> SuccessorNodes(NodeId)
{
  fn(n: NodeId) -> Dict(NodeId, Int) {
    let #(coord, cheats_left) = n
    compass.cardinals
    |> list.map(fn(d) { #(d, compass.get_neighbour(coord, d)) })
    |> list.filter(fn(d_new_coord) { matrix.valid_coord(input, d_new_coord.1) })
    |> list.filter_map(fn(d_new_coord) {
      let #(d, new_coord) = d_new_coord
      let cell = dict.get(input.data, new_coord)
      case cheats_left > 0 && cheatable_wall(cell, d) {
        True  -> Ok(#(new_coord, cheats_left - 1))             //Can use a cheat
        False -> 
          case cell {
            Ok(c) if c != "X" -> Error(Nil)                    //Obstacle in the way
            _                 -> Ok(#(new_coord, cheats_left)) //Otherwise, found a gap
          }
      }
    })
    |> list.map(fn(coord_cheats_left) {
      #(coord_cheats_left, 1) //all moves cost 1 picosecond
    }) 
    |> dict.from_list
  }
}

type CacheNode = #(NodeId, Int) //Node and Dist

fn bfs(f: SuccessorNodes(NodeId), end_node: NodeId, max_dist: Int,
       cache: Dict(CacheNode, Int), node: NodeId, dist: Int) -> #(Int, Dict(CacheNode, Int))
{
  io.debug(#(node, dist, cache))

  case node == end_node, dist == max_dist {
    True,  _     -> #(1, cache)  //found a way to the end within the max_dist
    False, True  -> #(0, cache)  //ran out dist, nothing to see down this path
    False, False -> {            //otherwise, keep searching
      case dict.get(cache, #(node, dist)) {
        Ok(i)    -> { io.print("Cache hit: ") io.debug(#(node, dist, i)) #(i, cache) } //Cache hit
        Error(_) -> {
          let #(count, new_cache) = f(node)
            |> dict.keys
            |> list.fold(#(0, cache), fn(acc, succ_node) {
              let #(sub_count, sub_cache) = bfs(f, end_node, max_dist, acc.1, succ_node, dist + 1)
              #(acc.0 + sub_count, dict.merge(acc.1, sub_cache))
            })
          io.print("Cache add: ")
          io.debug(#(#(node, dist), count))
          #(count, dict.insert(new_cache, #(node, dist), count))
        }
      }
    }
  }
}

fn wall_value(cell: Result(Char, Nil)) -> Result(Int, Nil)
{
  case cell {
    Error(_) -> Error(Nil)
    Ok(c)    -> case c {
      "#" -> Ok(0)
      c   -> case int.base_parse(c, 16) {
        Ok(i) if i >= 0b0000 && i <= 0b1111 -> Ok(i)
        _                                   -> Error(Nil)
      }
    }
  }
}

fn is_wall(cell: Result(Char, Nil)) -> Bool
{
  result.is_ok(wall_value(cell))
}

fn direction_value(d: Direction) -> Int
{
  case d {
    compass.N -> 0b0001
    compass.E -> 0b0010
    compass.S -> 0b0100
    compass.W -> 0b1000
    _ -> panic as "cardinals only"
  }
}

fn cheatable_wall(cell: Result(Char, Nil), d: Direction) -> Bool
{
  case wall_value(cell){
    Error(_) -> False //no need to use a cheat if it's not a wall
    Ok(v)    -> int.bitwise_and(v, direction_value(d)) == 0
  }
}

fn adjust_wall(x: Option(Char), d: Direction) -> Char
{
  let d_val = direction_value(d)
  case x {
    Some(c) -> {
      let assert Ok(w_val) = wall_value(Ok(c))
      int.to_base16(w_val + d_val)
    }
    None    -> panic as "wasn't a wall in the first place"
  }
}

//Much simpler approach for part 2
type NodeId2 = Coord
fn make_graph_fn2(input: Matrix(Char)) -> SuccessorNodes(NodeId2)
{
  fn(coord: NodeId2) -> Dict(NodeId2, Int) {
    compass.cardinals
    |> list.map(compass.get_neighbour(coord, _))
    |> list.filter(fn(new_coord) { dict.get(input.data, new_coord) != Ok("#") })
    |> list.map(fn(new_coord) { #(new_coord, 1) }) //all moves cost 1 picosecond
    |> dict.from_list
  }
}

fn is_normal_track(input: Matrix(Char), coord: Coord) -> Bool
{
  case dict.get(input.data, coord) {
    Error(_)                      -> True
    Ok(c) if c == "S" || c == "E" -> True
    _                             -> False
  }
}

pub fn part1() {
  let input = parse()
  //matrix.draw(input, ".")

  let assert Ok(start_pt) = matrix.find(input, fn(v) { v == "S" })
  let assert Ok(end_pt) = matrix.find(input, fn(v) { v == "E" })

  //Prevent clash with the hexadecimal "E"
  let input = Matrix(..input, data: dict.insert(input.data, end_pt, "X"))

  let f = make_graph_fn(input)
  let shortest_paths = dijkstra.dijkstra(f, #(start_pt, 1))
  let shortest_path_without_cheats =
    dijkstra.shortest_path(shortest_paths, #(end_pt, 1))

  io.println("")
  io.debug(shortest_path_without_cheats.1)

  // let paths_with_cheat = bfs(f, #(end_pt, 0), shortest_path_without_cheats.1 - 10, dict.new(), #(start_pt, 0), 0)
  // io.debug(paths_with_cheat)

  list.fold_until(list.range(0, 10_000), input, fn(acc, _) {
    let shortest_paths = dijkstra.dijkstra(make_graph_fn(acc), #(start_pt, 1))
    let shortest_path_with_cheats =
      dijkstra.shortest_path(shortest_paths, #(end_pt, 0))
    io.debug(shortest_path_with_cheats.1)

    let cheat_coord_pair =
      shortest_path_with_cheats.0
      |> list.window_by_2
      |> list.find(fn(coord_cheats_left_pair) {
        dict.get(acc.data, coord_cheats_left_pair.0.0)
        |> is_wall
      })
      |> result.lazy_unwrap(fn() { panic as "not found" })
      |> pair.map_first(fn(coord_cheats_left) { coord_cheats_left.0 })
      |> pair.map_second(fn(coord_cheats_left) { coord_cheats_left.0 })

    let assert Ok(d) = compass.get_direction(cheat_coord_pair)

    //io.debug(#(cheat_coord_pair, d))

    case shortest_path_without_cheats.1 - shortest_path_with_cheats.1 >= 100 {
      False -> Stop(acc)
      True ->  Continue(Matrix(..acc,
                               data: dict.upsert(acc.data, cheat_coord_pair.0, adjust_wall(_, d))))
    }
  })
}

pub fn part2()
{
  let input = parse()
  //matrix.draw(input, ".")

  let assert Ok(start_pt) = matrix.find(input, fn(v) { v == "S" })
  let assert Ok(end_pt) = matrix.find(input, fn(v) { v == "E" })

  let f = make_graph_fn2(input)
  let shortest_paths = dijkstra.dijkstra(f, start_pt)
  let path_no_cheat = dijkstra.shortest_path(shortest_paths, end_pt)

  //Seed cache with all the coords along the shortest (and only) no-cheat path.
  let cache =
    list.fold(path_no_cheat.0, #([], path_no_cheat.1), fn(acc, coord) {
      let #(l, dist) = acc
      #([#(coord, dist), ..l], dist - 1)
    })
    |> pair.first
    |> dict.from_list

  //And prepare the criteria
  let target_picoseconds = path_no_cheat.1 - 100

  // io.debug(path_no_cheat)
  // io.debug(cache)

  //Now for every coord on the path, cheat and count the new paths.
  // s - path start pt, cs - cheat start pt, ce - cheat end pt, e - path end pt
  let ans = list.index_fold(path_no_cheat.0, #(cache, 0), fn(acc, cs, cs_dist) {
    let ces = cs
    |> compass.get_neighbours(20, compass.cardinals)
    |> dict.filter(fn(ce, _dist) {
      matrix.valid_coord(input, ce) && is_normal_track(input, ce)
    })
    
    let total_dists = ces
    |> dict.map_values(fn(ce, c_dist) {
      let assert Ok(ce_dist) = dict.get(cache, ce) //is it really this easy? Everything's already in the cache?
      //io.debug(#(#(cs, ce), #(cs_dist, c_dist, ce_dist))) Nil }
      cs_dist + c_dist + ce_dist
    })
    |> dict.values

    //Remarkably, cache doesn't have to change.
    #(acc.0, acc.1 + list.count(total_dists, util.le(_, target_picoseconds)))
  })
 
  io.debug(ans.1)
}
