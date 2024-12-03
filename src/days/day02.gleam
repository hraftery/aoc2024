import gleam/result
import gleam/io
import gleam/string
import gleam/int
import gleam/list
import simplifile as file
import util/util

const day = "02"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.split("\n")
  |> list.map(parse_line)
}

fn parse_line(line)
{
  string.split(line, " ")
    |> list.map(int.parse)
    |> list.map(result.unwrap(_, 0))
}

//For brevity
fn abs(i : Int) -> Int
{
  int.absolute_value(i)
}

fn is_safe1(levels : List(Int)) -> Bool
{
  //Classic FP style would be to zip levels with its rest or something and
  //then fold over the whole thing. Instead we make it easy on ourselves
  //and evaluate an initial state based on the first two levels.
  let assert [l0,l1,..] = levels
  let state = #(
    True,  //result: safe until proven otherwise
    l1>l0, //is_inc: true if levels are increasing
    l0     //prev: previous level
  )
  let assert Ok(rest) = list.rest(levels) 

  let state = list.fold_until(rest, state, fn(state, curr)
    {
      let #(result, is_inc, prev) = state
      case curr > prev == is_inc && //still increasing or decreasing
           curr != prev          && //differ by at least one
           abs(curr - prev) <= 3    //differ by at most three
      {
        True  -> list.Continue(#(result, is_inc, curr))
        False -> list.Stop(#(False, is_inc, curr))
      }
    })

  state.0
}

//Brute-force, baby!
fn is_safe2(levels : List(Int)) -> Bool
{
  let first_idx = 0
  let last_idx = list.length(levels) - 1
  //safe if safe without the Dampener, or with the Dampener at any level
  is_safe1(levels) ||
    list.any(list.map(list.range(first_idx, last_idx),
                      util.drop_elem(levels, _)),
             is_safe1)
}

//Earlier, "smarter" algorithm that missed some cases.
// fn do_is_safe2(levels : List(Int), increasing : Bool, used_dampener : Bool) -> Bool
// {
//   let assert Ok(l0) = list.first(levels)
//   let state = #(
//     True,         //result: safe until proven otherwise
//     increasing,   //is_inc: true if levels are increasing
//     l0,           //prev: previous level
//     used_dampener //used_dampener: True if we've used the Problem Dampener already
//   )
//   let assert Ok(rest) = list.rest(levels) 

//   let state = list.fold_until(rest, state, fn(state, curr)
//     {
//       let #(result, is_inc, prev, used_dampener) = state
//       case curr > prev == is_inc && //still increasing or decreasing
//            curr != prev          && //differ by at least one
//            abs(curr - prev) <= 3    //differ by at most three
//       {
//         True  -> list.Continue(#(result, is_inc, curr, used_dampener))
//         False -> case used_dampener //possible second chance
//           {
//             True  -> list.Stop(#(False, is_inc, curr, used_dampener))
//             False -> list.Continue(#(result, is_inc, prev, True)) //skip curr
//           }
//       }
//     })

//   state.0
// }

pub fn part1()
{
  let result = list.count(parse(), is_safe1)
  
  io.debug(result)
}

pub fn part2()
{
  let result = list.count(parse(), is_safe2)
  
  io.debug(result)
}
