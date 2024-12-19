import gleam/io
import gleam/dict.{type Dict}
import gleam/string
import gleam/list
import gleam/pair
import util/compass.{type Coord}


pub type Char = String
pub type Matrix(a) {
  Matrix(data: Dict(Coord, a), num_rows: Int, num_cols: Int)
}


pub fn from_list_of_strings(str_list: List(String), ignore: Char) -> Matrix(Char)
{
  let data = str_list
  |> list.index_map(fn (row, y) { import_row(row, ignore, y) })
  |> list.flatten
  |> dict.from_list

  let assert Ok(first_row) = list.first(str_list)
  Matrix(data:data, num_rows: list.length(str_list),
                    num_cols: list.length(string.to_graphemes(first_row))) //so arduous...
}

fn import_row(str: String, ignore: Char, y: Int) -> List(#(Coord, Char))
{
  str
  |> string.to_graphemes
  |> list.index_map(pair.new)
  |> list.filter(fn (char_x) { char_x.0 != ignore })
  |> list.map(fn (char_x) { #(#(char_x.1, y), char_x.0) })
}

pub fn valid_coord(matrix: Matrix(a), coord: Coord) -> Bool
{
  let #(x,y) = coord
  x >= 0 && x < matrix.num_cols &&
  y >= 0 && y < matrix.num_rows
}

//like list.find but for Matrix, and returns the coord not the element. PS. why is this so hard?
pub fn find(in mat: Matrix(a), one_that is_desired: fn(a) -> Bool) -> Result(Coord, Nil)
{
  mat.data
  |> dict.to_list //OMG, nothing in gleam/dict to get this done?
  |> list.find_map(fn(coord_elem) {
    case is_desired(coord_elem.1) {
      True  -> Ok(coord_elem.0)
      False -> Error(Nil)
    }
  })
}

pub fn draw(mat: Matrix(Char), missing_char: Char)
{
  let xs = list.range(0, mat.num_cols - 1)
  let ys = list.range(0, mat.num_rows - 1)

  list.each(ys, fn (y) {
    list.each(xs, fn (x) {
      case dict.get(mat.data, #(x,y)) {
        Ok(c)    -> io.print(c)
        Error(_) -> io.print(missing_char)
      }
    })
    io.println("")
  })
}
