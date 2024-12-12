import gleam/dict.{type Dict}
import gleam/string
import gleam/list
import gleam/pair


pub type Char = String
pub type Coord = #(Int, Int)
pub type Coords = List(Coord)
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
