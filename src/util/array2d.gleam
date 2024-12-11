import gleam/int
import gleam/string
import gleam/list.{Stop, Continue}
import gleam/result
import glearray.{type Array} as array
import gleam/yielder
import util/compass.{type Direction}


pub type Array2D(a) = Array(Array(a))
pub type Char = String
pub type Coord = #(Int, Int)
pub type Coords = List(Coord)

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

pub fn get(arr: Array2D(a), pt: Coord) -> Result(a, Nil)
{
  let #(x, y) = pt
  case array.get(arr, y) {
    Ok(row)    -> array.get(row, x)
    Error(Nil) -> Error(Nil)
  }
}

pub fn get_neighbour(arr: Array2D(a), pt: Coord, dir: Direction) -> #(Coord, Result(a, Nil))
{
  let #(x, y) = pt
  let neighbour_pt = case dir {
    compass.N  -> #(x    , y - 1)
    compass.NE -> #(x + 1, y - 1)
    compass.E  -> #(x + 1, y    )
    compass.SE -> #(x + 1, y + 1)
    compass.S  -> #(x    , y + 1)
    compass.SW -> #(x - 1, y + 1)
    compass.W  -> #(x - 1, y    )
    compass.NW -> #(x - 1, y - 1)
  }
  #(neighbour_pt, get(arr, neighbour_pt))
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
  list.filter_map(xs_ys, fn (x_y) { get(arr, x_y) }) //drop any that are Error
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

//like list.find but for Array2D, and returns the coords not the element. PS. why is this so hard?
pub fn locate(in arr: Array2D(a), one_that is_desired: fn(a) -> Bool) -> Result(Coord, Nil)
{
  arr
  |> array.yield
  |> yielder.index
  |> yielder.fold_until(Error(Nil), fn(_, row_y) {
      let #(row, y) = row_y
      let inner_ret = row
      |> array.yield
      |> yielder.index
      |> yielder.fold_until(Error(Nil), fn(_, elem_x) {
          let #(elem, x) = elem_x
          case is_desired(elem) {
            True  -> Stop(Ok(x))
            False -> Continue(Error(Nil))
          }
        })
      case inner_ret {
        Ok(x)    -> Stop(Ok(#(x,y)))
        Error(_) -> Continue(Error(Nil))
      }
    })
}
