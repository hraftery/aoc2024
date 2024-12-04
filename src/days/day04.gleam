import gleam/list
import gleam/io
import gleam/string
//import gleam/int
//import gleam/list
import simplifile as file
import util/array2d.{type Array2D, type Char}
import util/compass.{type Direction}


const day = "04"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.split("\n")
  |> array2d.from_list_of_strings
}

fn does_match(arr: Array2D(Char), str: String, x: Int, y: Int, dir: Direction)
{
  let len = string.length(str)
  //checking fit first is not required, but may prevent wasted cycles sometimes
  case array2d.does_vector_fit(arr, x, y, dir, len) {
    False -> False
    True  -> str == string.concat(array2d.take(arr, x, y, dir, len))
  }
}

fn is_x_mas(arr: Array2D(Char), x: Int, y: Int)
{
  case array2d.does_vector_fit(arr, x, y, compass.SE, 3) {
    False -> False
    True  -> list.any([#("MAS", "SAM"), #("MAS", "MAS"), #("SAM", "MAS"), #("SAM", "SAM")],
                      fn (strs) { string.concat(array2d.take(arr, x,   y, compass.SE, 3)) == strs.0 &&
                                  string.concat(array2d.take(arr, x+2, y, compass.SW, 3)) == strs.1 })
  }
}

pub fn part1()
{
  let input = parse()
  let x_max = array2d.num_cols(input) - 1
  let y_max = array2d.num_rows(input) - 1

  let all_vectors =
    list.flat_map(list.range(0, x_max),
                  fn (x) { list.flat_map(list.range(0, y_max),
                                         fn (y) { list.map(compass.list_clockwise(),
                                                           fn (dir) { #(x, y, dir) })})})
  
  let count = list.count(all_vectors, fn (x_y_dir) { does_match(input, "XMAS", x_y_dir.0, x_y_dir.1, x_y_dir.2) })
  io.debug(count)
}

pub fn part2()
{
  let input = parse()
  let x_max = array2d.num_cols(input) - 1
  let y_max = array2d.num_rows(input) - 1

  let all_vectors =
    list.flat_map(list.range(0, x_max),
                  fn (x) { list.map(list.range(0, y_max),
                                    fn (y) { #(x, y) })})
  
  let count = list.count(all_vectors, fn (x_y) { is_x_mas(input, x_y.0, x_y.1) })
  io.debug(count)
}
