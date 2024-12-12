import gleam/result
import gleam/io
import gleam/string
import gleam/int
import gleam/list
import simplifile as file
import util/util
import gleam/yielder//.{Next}


const day = "11"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example1.txt"
//const input_file = "input/" <> day <> "_example2.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.split(" ")
  |> list.map(int.parse)
  |> result.values
}

fn blink(input: List(Int)) -> List(Int)
{
  io.debug(util.now())
  input
  |> list.flat_map(fn (x) {
    case x {
      0 -> [1]
      _ -> {
        let x_str = int.to_string(x)
        let x_str_len = string.length(x_str)
        case int.is_even(x_str_len) {
          True -> {
            x_str
            |> util.string_split_at(x_str_len/2)
            |> list.map(int.parse)
            |> result.values
          }
          False -> [x * 2024]
        }
      }
    }
  })
}

pub fn part1()
{
  let input = parse()
  
  let it = yielder.iterate(input, blink)

  // let assert Next(a, it) = yielder.step(it)
  // io.debug(a)
  // let assert Next(a, _) = yielder.step(it)
  // io.debug(a)

  // let ans = yielder.to_list(yielder.take(it, 7))
  // list.each(ans, fn (x) { io.debug(x)} )

  let assert Ok(stones) = yielder.at(it, 25)
  io.debug(list.length(stones))
}

pub fn part2()
{
  let input = parse()
  
  let it = yielder.iterate(input, blink)

  let assert Ok(stones) = yielder.at(it, 75)
  io.debug(list.length(stones))
}
