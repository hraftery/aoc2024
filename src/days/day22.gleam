import gleam/io
import gleam/string
import gleam/int
import gleam/list
import gleam/dict.{type Dict}
import gleam/result
import simplifile as file
import util/util


const day = "22"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"
//const input_file = "input/" <> day <> "_example2.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.split("\n")
  |> list.map(int.parse)
  |> result.values
}

fn evolve(secret: Int) -> Int
{
  let secret = secret * 64
  |> mix(secret)
  |> prune

  let secret = secret / 32 //round down
  |> mix(secret)
  |> prune

  let secret = secret * 2048
  |> mix(secret)
  |> prune

  secret
}

fn mix(secret: Int, value: Int)
{
  int.bitwise_exclusive_or(value, secret)
}

fn prune(secret: Int)
{
  secret % 16777216
}

fn evolve_n(secret: Int, times: Int) -> List(Int)
{
  case times {
    0 -> []
    _ -> {
      let new_secret = evolve(secret)
      [new_secret, ..evolve_n(new_secret, times - 1)]
    }
  }
}

fn secrets_to_price_and_change_pairs(secret_sequence: List(Int)) -> List(#(Int, Int))
{
  secret_sequence
  |> list.map(fn(secret) { secret % 10 })               //prices
  |> list.window_by_2                                   //pairs of price neighbours
  |> list.map(fn(pair) { #(pair.1, pair.1 - pair.0) })  //price and price changes
}

type ChangeSequence = #(Int,Int,Int,Int)
fn price_and_change_pairs_to_price_for_change_sequence_dict(pairs: List(#(Int, Int))) -> Dict(ChangeSequence, Int)
{
  pairs
  |> list.window(4) //[[#(3, 0), #(9, 6), #(5, -4), #(9, 4)], [#(9, 6), #(5, -4), #(9, 4), #(0, -9)], ... ]
  |> list.map(fn(group_of_4) {
    let assert [a, b, c, d] = group_of_4
    #(#(a.1, b.1, c.1, d.1), d.0) //[#(#(0, 6, -4, 4), 9], #(#(6, -4, 4, -9), 0], ... ]
  })
  |> util.from_list_ignore_dups
}

pub fn part1()
{
  let input = parse()
  //io.debug(input)
  let ans = list.map(input, util.apply(_, 2000, evolve))
  |> int.sum

  io.debug(ans)
}

pub fn part2()
{
  let input = parse()

  let dict_of_price_sum_for_change_sequence = input
  |> list.map(evolve_n(_, 2000))
  |> list.fold(dict.new(), fn(acc, secrets) {
    let new_dict = secrets
    |> secrets_to_price_and_change_pairs
    |> price_and_change_pairs_to_price_for_change_sequence_dict

    dict.combine(acc, new_dict, fn(old, new) { old + new })
  })

  //io.debug(dict_of_price_sum_for_change_sequence)

  let ans = dict_of_price_sum_for_change_sequence
  |> util.key_for_max_value(int.compare)
  |> result.lazy_unwrap(fn() { panic as "bug" })
  |> dict.get(dict_of_price_sum_for_change_sequence, _)
  
  io.debug(ans)
}
