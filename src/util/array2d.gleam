import gleam/string
import gleam/list
import glearray.{type Array} as array
import util/compass.{type Direction}


pub type Array2D(a) = Array(Array(a))
pub type Char = String

fn array_from_string(str: String) -> Array(Char)
{
  array.from_list(string.to_graphemes(str))
}

pub fn from_list_of_strings(str_list: List(String)) -> Array2D(Char)
{
  str_list
  |> list.map(array_from_string)
  |> array.from_list
}

pub fn get(arr: Array2D(a), col x: Int, row y: Int) -> Result(a, Nil)
{
  case array.get(arr, y) {
    Ok(row)    -> array.get(row, x)
    Error(Nil) -> Error(Nil)
  }
}

pub fn take(arr: Array2D(a), x: Int, y: Int, dir: Direction, len: Int) -> List(a)
{
  let mod = len - 1 //don't include starting point
  let xs_ys = case dir {
    compass.N  -> list.zip(list.repeat(x, len),    list.range(y, y - mod))
    compass.NE -> list.zip(list.range(x, x + mod), list.range(y, y - mod))
    compass.E  -> list.zip(list.range(x, x + mod), list.repeat(y, len))
    compass.SE -> list.zip(list.range(x, x + mod), list.range(y, y + mod))
    compass.S  -> list.zip(list.repeat(x, len),    list.range(y, y + mod))
    compass.SW -> list.zip(list.range(x, x - mod), list.range(y, y + mod))
    compass.W  -> list.zip(list.range(x, x - mod), list.repeat(y, len))
    compass.NW -> list.zip(list.range(x, x - mod), list.range(y, y - mod))
  }
  list.filter_map(xs_ys, fn (x_y) { get(arr, x_y.0, x_y.1) }) //drop any that are Error
}

pub fn num_rows(arr: Array2D(a)) -> Int
{
  array.length(arr)
}

pub fn num_cols(arr: Array2D(a)) -> Int
{
  let assert Ok(first_row) = array.get(arr, 0)
  array.length(first_row)
}

pub fn does_vector_fit(arr: Array2D(a), x: Int, y: Int, dir: Direction, len: Int)
{
  let x_max = num_cols(arr) - 1
  let y_max = num_rows(arr) - 1
  case x >= 0 && y >= 0 && x <= x_max && y <= y_max {
    False -> False
    True  -> case len == 0 {
      True  -> True
      False -> {
        let dir = case len > 0 { True -> dir False -> compass.opposite(dir) }
        let mod = len - 1 //don't include starting point
        case dir {
          compass.N  ->                     y - mod >= 0
          compass.NE -> x + mod <= x_max && y - mod >= 0
          compass.E  -> x + mod <= x_max
          compass.SE -> x + mod <= x_max && y + mod <= y_max
          compass.S  ->                     y + mod <= y_max
          compass.SW -> x - mod >= 0     && y + mod <= y_max
          compass.W  -> x - mod >= 0
          compass.NW -> x - mod >= 0     && y - mod >= 0
        }
      }
    }
  }
}

pub fn to_string(arr: Array2D(Char)) -> String
{
  arr
  |> array.to_list
  |> list.map(fn (row) { string.concat(array.to_list(row)) })
  |> list.intersperse("\n")
  |> string.concat
}
