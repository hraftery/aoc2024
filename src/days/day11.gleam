import gleam/result
import gleam/io
import gleam/string
import gleam/int
import gleam/list
import gleam/dict.{type Dict}
import gleam/option.{Some, None}
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

type Stone = Int
type Stones = Dict(Stone, Int) //multiple stones, each with a quantity

fn blink_single(stone: Stone) -> List(Stone) //only ever one or two
{
  case stone {
    0 -> [1]
    _ -> {
      let x_str = int.to_string(stone)
      let x_str_len = string.length(x_str)
      case int.is_even(x_str_len) {
        True -> {
          x_str
          |> util.string_split_at(x_str_len/2)
          |> list.map(int.parse)
          |> result.values
        }
        False -> [stone * 2024]
      }
    }
  }
}

fn blink(input: List(Int)) -> List(Int)
{
  io.debug(util.now())
  
  list.flat_map(input, blink_single)
}

fn blink_groups(input: Stones) -> Stones
{
  //io.debug(input)
  let add = fn(existing_qty, new_qty) {
    case existing_qty {
      Some(i) -> i + new_qty
      None    -> new_qty
    }
  }
  dict.fold(input, dict.new(), fn(acc, stone, qty) {
    case blink_single(stone) {
      [x]    -> dict.upsert(acc, x, add(_, qty))
      [x, y] -> dict.upsert(acc, x, add(_, qty))
                |> dict.upsert(y, add(_, qty))
      _      -> panic as "blink_single() should only return a list of one or two vales"
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
              |> list.map(fn(x) { #(x, 1) }) //start with one of each
              |> dict.from_list()
  
  let it = yielder.iterate(input, blink_groups)

  let assert Ok(stones) = yielder.at(it, 75)
  let ans = dict.fold(stones, 0, fn(acc, _stone, qty) { acc + qty })
  io.debug(ans)
}
