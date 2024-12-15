import gleam/io
import gleam/string
import gleam/list
import gleam/dict
import simplifile as file
import util/util
import util/matrix
import util/compass.{type Coords}
import gleam/yielder


const day = "08"
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

fn find_antinodes(antennas: Coords)
{
  antennas
  |> list.combination_pairs
  |> list.fold([], fn(acc, pair) {
    let #(#(x0, y0), #(x1, y1)) = pair
    let dx = x1 - x0
    let dy = y1 - y0
    [#(x0 - dx, y0 - dy), #(x1 + dx, y1 + dy), ..acc]
  })
}

fn find_antinodes2(antennas: Coords, num_rows: Int, num_cols: Int)
{
  yielder.unfold(2, fn(acc) { yielder.Next(acc, acc * 2) })
  |> yielder.take(5)
  |> yielder.to_list
 
  antennas
  |> list.combination_pairs
  |> list.fold([], fn(acc, pair) {
    let #(#(x0, y0), #(x1, y1)) = pair
    let dx = x1 - x0
    let dy = y1 - y0
    let f = fn(acc, anti0) {
      let #(x, y) = acc
      case x >= 0 && y >= 0 && x < num_cols && y < num_rows {
        True  -> yielder.Next(acc, case anti0 {
                                     True  -> #(x - dx, y - dy)
                                     False -> #(x + dx, y + dy)
                                   })
        False -> yielder.Done
      }
    }
    let anti0 = yielder.unfold(pair.0, f(_, True))
    let anti1 = yielder.unfold(pair.1, f(_, False))
    list.flatten([yielder.to_list(anti0), yielder.to_list(anti1), acc])
  })
  |> list.unique
}

pub fn part1()
{
  let matrix = parse()
  let ans = matrix.data
  |> util.invert
  |> dict.fold([], fn(acc, _key, value) {
    list.flatten([find_antinodes(value), acc])
  })
  |> list.unique
  |> list.filter(fn (coord) {
    let #(x,y) = coord
    x >= 0 && y >= 0 && x < matrix.num_cols && y < matrix.num_rows
  })
  |> list.length

  io.debug(ans)
}

pub fn part2()
{
  let matrix = parse()
  let ans = matrix.data
  |> util.invert
  |> dict.fold([], fn(acc, _key, value) {
    list.flatten([find_antinodes2(value, matrix.num_cols, matrix.num_rows), acc])
  })
  |> list.unique
  |> list.length

  //let ans2 = find_antinodes2([#(0, 0), #(3, 1), #(1, 2)], matrix.num_cols, matrix.num_rows)
  io.debug(ans)
}
