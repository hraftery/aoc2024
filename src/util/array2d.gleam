import gleam/int
import gleam/string
import gleam/list.{Stop, Continue}
import gleam/result
import glearray.{type Array} as array
import gleam/yielder
import util/compass.{type Coord, type Coords, type Direction}


pub type Array2D(a) = Array(Array(a))
pub type Char = String

fn array_from_string(str: String) -> Array(Char)
{
  array.from_list(string.to_graphemes(str))
}

fn array_from_string_of_digits(str: String) -> Array(Int)
{
  str
  |> string.to_graphemes()
  |> list.map(int.parse)
  |> result.values
  |> array.from_list
}

pub fn from_list_of_strings(str_list: List(String)) -> Array2D(Char)
{
  str_list
  |> list.map(array_from_string)
  |> array.from_list
}

pub fn from_list_of_strings_of_digits(str_list: List(String)) -> Array2D(Int)
{
  str_list
  |> list.map(array_from_string_of_digits)
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
  let neighbour_pt = compass.get_neighbour(pt, dir)
  #(neighbour_pt, get(arr, neighbour_pt))
}

pub fn take(arr: Array2D(a), x: Int, y: Int, dir: Direction, len: Int) -> List(a)
{
  let xs_ys = compass.get_neighbours_in_direction(#(x, y), dir, len)
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

pub fn coords(arr: Array2D(a)) -> Coords
{
  let xs = list.range(0, num_cols(arr) - 1)
  let ys = list.range(0, num_rows(arr) - 1)

  list.flat_map(xs, fn (x) {
    list.map(ys, fn (y) {
      #(x, y)
    })
  })
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

//like list.find but for Array2D, and returns the coord not the element. PS. why is this so hard?
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

pub fn locate_all(in arr: Array2D(a), all_that is_desired: fn(a) -> Bool) -> Coords
{
  arr
  |> array.yield
  |> yielder.index
  |> yielder.flat_map(fn(row_y) {
      let #(row, y) = row_y
      row
      |> array.yield
      |> yielder.index
      |> yielder.filter_map(fn(elem_x) {
          let #(elem, x) = elem_x
          case is_desired(elem) {
            True  -> Ok(#(x,y))
            False -> Error(Nil)
          }
        })
    })
  |> yielder.to_list
}
