import gleam/io
import gleam/int
import gleam/string
import gleam/list
import gleam/dict.{type Dict}
import gleam/pair
import simplifile as file
import util/util
import util/matrix.{type Matrix, type InverseMatrix}
import util/compass.{type Coord, type Coords}
import util/dijkstra


const day = "21"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"

pub type Char     = String
pub type Key      = Char //Either a Num key or a Arrow key
pub type Num      = Key
pub type Code     = List(Num)
pub type Arrow    = Key
pub type Presses  = List(Arrow)
pub type KeyMove  = #(Key, Key) //A robot move from a src key to a dst key

fn parse() -> List(Code)
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.split("\n")
  |> list.map(string.to_graphemes)
}

fn numpad() -> #(Matrix(Num), InverseMatrix(Num))
{
  let pad = [
    "789",
    "456",
    "123",
    ".0A"]
  
  #(matrix.from_list_of_strings(pad, "."),
    matrix.inv_from_list_of_strings(pad, "."))
}

fn arrow_pad() -> #(Matrix(Arrow), InverseMatrix(Arrow))
{
  let pad = [
    ".^A",
    "<v>"]
  
  #(matrix.from_list_of_strings(pad, "."),
    matrix.inv_from_list_of_strings(pad, "."))
}

pub type Level { NumPad DirPad(Int) Human }
fn inc_level(level: Level)
{
  let part2 = False
  case level {
    NumPad    -> DirPad(1)
    DirPad(i) -> case part2, i {
      True,  25 -> Human
      False, 2  -> Human
      _,     _  -> DirPad(i+1)
    }
    _ -> panic as "bug"
  }
}
pub type Node = #(KeyMove, Level)
//Map from src/dst pairs of Num or Arrow, to the minimum press list
pub type Cache = Dict(Node, Presses)
pub type LUTs {
  LUTs(numpad_moves: Dict(KeyMove, List(Presses)),
       dirpad_moves: Dict(KeyMove, List(Presses)))
}

fn bfs(move: KeyMove, cache: Cache) -> #(Presses, Cache)
{
  let luts = LUTs(
    numpad_moves: make_presses_lists(True),
    dirpad_moves: make_presses_lists(False)
  )
  do_bfs(#(move, NumPad), cache, luts)
}

fn do_bfs(node: Node, cache: Cache, luts: LUTs) -> #(Presses, Cache)
{
  case dict.get(cache, node)
  {
    Ok(presses) -> #(presses, cache)
    _ -> {
      let #(move, level) = node
      case level {
        Human -> {
          let #(_src, dst) = move
          #([dst], cache) //no expansion
        }
        _ -> {
          let moves_lut = case level { NumPad -> luts.numpad_moves _ -> luts.dirpad_moves }
          let assert Ok(new_moves) = dict.get(moves_lut, move)

          //outer fold: get minimum of all possible moves
          let #(best_presses, new_cache) = new_moves
          |> list.fold(#([], cache), fn(acc, new_move) {
            let #(best_presses, outer_cache) = acc
            let move_pairs = ["A", ..new_move] //always start from A
            |> list.window_by_2
            //io.print("Outer: ") io.debug(#(acc, move_pairs))

            //inner fold: get sum of best move pairs
            let #(new_presses, new_cache) = move_pairs
            |> list.fold(#([], outer_cache), fn(acc, move_pair) {
              //io.print("Inner: ") io.debug(#(acc, move_pair))
              let #(acc_presses, inner_cache) = acc
              let new_node = #(move_pair, inc_level(level))
              let #(inner_presses, inner_cache) = do_bfs(new_node, inner_cache, luts)
              #(list.flatten([acc_presses, inner_presses]), inner_cache)
            })
            
            let best_length = list.length(best_presses)
            case best_length == 0 || list.length(new_presses) < best_length {
              True  -> #(new_presses, new_cache)
              False -> #(best_presses, new_cache)
            }
          })

          #(best_presses, dict.insert(new_cache, node, best_presses))
        }
      }
    }
  }
}

//Every move from Key to Key has a list of one or more shortest press lists.
//All press lists end with an "A" press. If for_numpad is false, it produces these 4, and 16 more:
//  #(#("<", ">"), [[">", ">", "A"]]),
//  #(#("<", "A"), [[">", "^", ">", "A"], [">", ">", "^", "A"]]),
//  #(#("<", "^"), [[">", "^", "A"]]),
//  #(#("<", "v"), [[">", "A"]]),
fn make_presses_lists(for_numpad: Bool) -> Dict(KeyMove, List(Presses))
{
  let #(pad, _) = case for_numpad { True -> numpad() False -> arrow_pad() }

  let f = fn(coord: Coord) -> Dict(Coord, Int) {
    compass.cardinals
    |> list.map(compass.get_neighbour(coord, _))
    |> list.filter(dict.has_key(pad.data, _)) //avoid "panicking unrecoverably"
    |> list.map(fn(new_coord) { #(new_coord, 1) }) //all moves have same length
    |> dict.from_list
  }

  pad.data
  |> dict.keys
  |> util.permutation_pairs_with_repetition
  |> list.map(fn(src_dst) {
    let #(src, dst) = src_dst
    let shortest_paths = f
    |> dijkstra.dijkstra_all(src)
    |> dijkstra.shortest_paths(dst)
    let assert Ok(src_arrow) = dict.get(pad.data, src)
    let assert Ok(dst_arrow) = dict.get(pad.data, dst)
    let presses = list.map(shortest_paths.0, to_presses)
    #(#(src_arrow, dst_arrow), presses)
  })
  |> dict.from_list
}

fn to_presses(coords: Coords) -> Presses
{
  coords
  |> list.window_by_2
  |> list.map(fn(src_dst) {
    case compass.get_direction(src_dst) {
      Ok(compass.N) -> "^"
      Ok(compass.E) -> ">"
      Ok(compass.S) -> "v"
      Ok(compass.W) -> "<"
      _ -> { panic as "not a valid path" }
    }
  })
  |> list.append(["A"])
}

// fn path(src: Coord, dst: Coord, is_code: Bool) -> List(Arrow)
// {
//   let #(#(x0, y0), #(x1, y1)) = #(src, dst)
  
//   let ys = case y1 >= y0 {
//     True  -> list.repeat("v", y1 - y0)
//     False -> list.repeat("^", y0 - y1)
//   }
//   let xs = case x1 >= x0 {
//     True  -> list.repeat(">", x1 - x0)
//     False -> list.repeat("<", x0 - x1)
//   }

//   case x1 >= x0, y1 >= y0, is_code {
//     True,  _,     _ -> list.flatten([xs, ys])
//     False, True,  _ -> list.flatten([ys, xs])
//     False, False, _ -> list.flatten([ys, xs])
//   }
// }

// fn to_arrows(keys: List(Char), is_code: Bool) -> Presses
// {
//   let #(_, pad) = case is_code { True -> numpad() False -> arrow_pad() }

//   let assert Ok(start_pt) = dict.get(pad.data, "A")
//   let coords = keys
//   |> list.map(dict.get(pad.data, _))
//   |> result.values
  
//   [start_pt, ..coords]
//   |> list.window_by_2
//   |> list.map(fn(src_dst) { path(src_dst.0, src_dst.1, is_code) })
//   |> list.map(list.append(_, ["A"]))
//   |> list.flatten
// }

// fn solve(code: Code) -> String
// {
//   let ans = to_arrows(code, True)
//   //|> io.debug
//   |> to_arrows(False)
//   //|> io.debug
//   |> to_arrows(False)
//   //|> io.debug
//   |> string.concat

//   io.debug(ans)
//   ans
// }

fn solve(code: Code) -> Presses
{
  ["A", ..code]
  |> list.window_by_2
  |> list.fold(#([], dict.new()), fn(acc, move) {
    let #(acc_presses, acc_cache) = acc
    let #(presses, new_cache) = bfs(move, acc_cache)
    #(list.append(acc_presses, presses), new_cache)
  })
  |> pair.first
}

fn score(code: Code) -> Int
{
  let sol_len = list.length(solve(code))
  let assert Ok(#(init, _last)) = util.init_last(code)
  let assert Ok(code_val) = int.parse(string.concat(init))

  io.debug(#(sol_len, code_val))
  sol_len * code_val
}

//Just the next best move, as determined by one move ahead
pub type Cache2 = Dict(KeyMove, Presses)

fn bfs2(move: KeyMove, cache: Cache2) -> Presses
{
  do_bfs2(#(move, DirPad(1)), cache, make_presses_lists(False))
}

fn do_bfs2(node: Node, cache: Cache2, lut) -> Presses
{
  let #(move, level) = node

  case dict.get(cache, move)
  {
    Ok(presses) -> presses
    _ -> {
      case level {
        DirPad(i) if i <= 2 -> {
          let assert Ok(new_moves) = dict.get(lut, move)

          case list.length(new_moves) {
            1 -> { //no need to recurse, there can be only 1 winner
              let assert Ok(new_move) = list.first(new_moves)
              new_move
            }
            _ -> {
              //outer fold: get minimum of all possible moves
              let best_move_and_presses = new_moves
              |> list.fold(#([], []), fn(best_move_and_presses, new_move) {
                let #(best_move, best_presses) = best_move_and_presses
                let move_pairs = ["A", ..new_move] //always start from A
                |> list.window_by_2
                // io.print("Outer: ") io.debug(#(best_presses, move_pairs))
                // io.println("")

                //inner fold: get sum of best move pairs
                let new_presses = move_pairs
                |> list.fold([], fn(acc_presses, move_pair) {
                  // io.print("Inner: ") io.debug(#(acc_presses, move_pair))
                  // io.println("")
                  let new_node = #(move_pair, inc_level(level))
                  let inner_presses = do_bfs2(new_node, cache, lut)
                  list.flatten([acc_presses, inner_presses])
                })
                
                let best_length = list.length(best_presses)
                case best_length == 0 || list.length(new_presses) < best_length {
                  True  -> #(new_move, new_presses)
                  False -> #(best_move, best_presses)
                }
              })

              best_move_and_presses.0
            }
          }
        }
        _ -> {
          let #(_src, dst) = move
          [dst] //no expansion
        }
      }
    }
  }
}

fn expand_move(move: KeyMove, times: Int, cache: Cache2) -> Presses
{
  let assert Ok(ans) = dict.get(cache, move)
  case times == 1 {
    True  -> ans
    False -> {
      ["A", ..ans]
      |> list.window_by_2
      |> list.flat_map(expand_move(_, times - 1, cache))
    }
  }
}

fn expand_path(path: Presses, times: Int, cache: Cache2) -> Presses
{
  ["A", ..path]
  |> list.window_by_2
  |> list.flat_map(expand_move(_, times, cache))
}

fn solve2(code: Code, num_cache: Cache2, dir_cache: Cache2) -> Presses
{
  ["A", ..code]
  |> list.window_by_2
  |> list.flat_map(fn(num_move) {
    let assert Ok(best_path) = dict.get(num_cache, num_move)
    expand_path(best_path, 25, dir_cache)
  })
}

fn score2(code: Code, num_cache: Cache2, dir_cache: Cache2) -> Int
{
  let sol_len = list.length(solve2(code, num_cache, dir_cache))
  let assert Ok(#(init, _last)) = util.init_last(code)
  let assert Ok(code_val) = int.parse(string.concat(init))

  io.debug(#(sol_len, code_val))
  sol_len * code_val
}


pub fn part1()
{
  let codes = parse()
  //io.debug(codes)

  //let ans = to_arrows(["3","7","9","A"], True)
  //let ans = to_arrows(["^", "A", "^", "^", "<", "<", "A", ">", ">", "A", "v", "v", "v", "A"], False)
  //let ans = to_arrows(["<", "A", ">", "A", "<", "A", "A", "v", "<", "A", "A", ">", ">", "^", "A", "v", "A", "A", "^", "A", "v", "<", "A", "A", "A", ">", "^", "A"], False)

  //let ans = score(["3","7","9","A"])
  let ans = int.sum(list.map(codes, score))
  
  io.debug(ans)
}

pub fn part2()
{
  let dir_cache = arrow_pad()
  |> fn(pad_and_inv_pad) { pad_and_inv_pad.1.data }
  |> dict.keys
  |> util.permutation_pairs_with_repetition
  |> list.fold(dict.new(), fn(cache, move) {
    let best_move = bfs2(move, cache)
    dict.insert(cache, move, best_move)
  })
  //io.debug(dir_cache)

  let lut = make_presses_lists(True)
  let num_cache = numpad()
  |> fn(pad_and_inv_pad) { pad_and_inv_pad.1.data }
  |> dict.keys
  |> util.permutation_pairs_with_repetition
  |> list.fold(dict.new(), fn(cache, move) {
    let assert Ok(all_paths) = dict.get(lut, move)

    let best_path_and_presses = all_paths
    |> list.fold(#([], []), fn(best_path_and_presses, new_path) {
      let #(best_path, best_presses) = best_path_and_presses
      let new_presses = expand_path(new_path, 3, dir_cache)
      let best_length = list.length(best_presses)
      case best_length == 0 || list.length(new_presses) < best_length {
        True  -> #(new_path, new_presses)
        False -> #(best_path, best_presses)
      }
    })
    dict.insert(cache, move, best_path_and_presses.0)
  })
  //io.debug(num_cache)

  let codes = parse()
  let ans = codes
  |> list.map(score2(_, num_cache, dir_cache))
  |> int.sum

  io.debug(ans)
}
