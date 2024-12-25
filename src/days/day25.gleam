import util/util
import gleam/io
import gleam/string
import gleam/int
import gleam/list
import gleam/dict.{type Dict}
import simplifile as file


const day = "25"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"

pub type Shape  = Dict(Int, Int)
pub type Shapes = List(Shape)
pub type Schematics {
  Schematics(locks: Shapes, keys: Shapes, num_cols: Int, num_rows: Int)
}

fn parse() -> Schematics
{
  let assert Ok(raw_input) = file.read(input_file)
  let #(locks, keys) = raw_input
  |> string.trim
  |> string.split("\n")
  |> list.chunk(string.is_empty)
  |> list.fold(#([], []), fn(acc, chunk) {
    let #(locks, keys) = acc
    case chunk == [""] {
      True  -> acc
      False -> {
        let num_rows = list.length(chunk)
        let assert Ok(first_row) = list.first(chunk)
        let num_cols = string.length(first_row)
        case first_row == string.repeat("#", num_cols) {
          True  -> #([#(parse_shape(chunk), num_cols, num_rows), ..locks], keys)
          False -> #(locks, [#(parse_shape(list.reverse(chunk)), num_cols, num_rows), ..keys])
        }
      }
    }
  })
  let assert Ok(#(_, num_cols, num_rows)) = list.first(locks)
  case list.all(locks, fn(x) { x.1 == num_cols && x.2 == num_rows }) &&
       list.all(keys,  fn(x) { x.1 == num_cols && x.2 == num_rows })
  {
    False -> panic as "keys/locks are difference sizes"
    True  -> Schematics(locks: list.map(locks, fn(x) { x.0 }),
                        keys:  list.map(keys,  fn(x) { x.0 }),
                        num_cols: num_cols, num_rows: num_rows)
  }
}

fn parse_shape(lines: List(String)) -> Dict(Int, Int)
{
  let lines = list.drop(lines, 1)
  list.index_fold(lines, dict.new(), fn(acc, line, row) {
    list.index_fold(string.to_graphemes(line), acc, fn(acc, c, col) {
      case c == "." {
        True  -> util.insert_if_unique(acc, col, row)
        False -> acc
      }
    })
  })
}

fn shape_to_string(shape: Shape, num_cols: Int) -> String
{
  list.fold(list.range(0, num_cols - 1), "", fn(acc, col) {
    let assert Ok(height) = dict.get(shape, col)
    case col == num_cols - 1 {
      False -> acc <> int.to_string(height) <> ","
      True  -> acc <> int.to_string(height)
    }
  })
}

fn shapes_to_string(shapes: Shapes, num_cols: Int) -> String
{
  list.fold(shapes, "", fn(acc, shape) {
    acc <> shape_to_string(shape, num_cols) <> "\n"
  })
}

fn check_fit(lock: Shape, key: Shape, num_cols: Int, num_rows: Int) -> Bool
{
  list.all(list.range(0, num_cols - 1), fn(i) {
    let assert Ok(lock_height) = dict.get(lock, i)
    let assert Ok(key_height)  = dict.get(key, i)
    lock_height + key_height <= num_rows - 2 //-2 for the two full rows
  })
}

pub fn part1()
{
  let Schematics(locks, keys, num_cols, num_rows) as schematics = parse()
  // io.print(shapes_to_string(locks, num_cols))
  // io.print(shapes_to_string(keys,  num_cols))

  let ans = locks
  |> list.flat_map(fn(lock) {
    list.map(keys, fn(key) {
      #(lock, key)
    })
  })
  |> list.count(fn(lock_key) {
    // io.debug(#(shape_to_string(lock_key.0, num_cols), 
    //            shape_to_string(lock_key.1, num_cols),
    //            check_fit(lock_key.0, lock_key.1, num_cols, num_rows)))
    check_fit(lock_key.0, lock_key.1, num_cols, num_rows)
  })

  io.debug(ans)
}

pub fn part2()
{
  io.println("Day " <> day <> ", part 2.")
}

pub fn suppress_warnings()
{
  shapes_to_string([], 0)
}
