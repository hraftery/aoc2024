import gleam/result
import gleam/io
import gleam/string
import gleam/int
import gleam/list
import simplifile as file


const day = "07"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.split("\n")
  |> list.map(fn (line) {
    let assert Ok(#(test_val_str, eqn_vals_str)) = string.split_once(line, ": ")
    let assert Ok(test_val) = int.parse(test_val_str)
    let eqn_vals = result.values(list.map(string.split(eqn_vals_str, " "), int.parse))
    #(test_val, eqn_vals)
  })
}

fn has_solution(test_val_eqn_vals: #(Int, List(Int)), part2: Bool) -> Bool
{
  let #(test_val, eqn_vals) = test_val_eqn_vals
  
  let assert Ok(first_val) = list.first(eqn_vals)
  let assert Ok(rest_vals) = list.rest(eqn_vals)

  case list.is_empty(rest_vals) {
    True  -> first_val == test_val
    False -> case part2 { False -> do_has_solution1(test_val, first_val, rest_vals)
                          True  -> do_has_solution2(test_val, first_val, rest_vals)
                        }
  }
}

fn do_has_solution1(target_total: Int, running_total: Int, vals: List(Int)) -> Bool
{
  case running_total > target_total {
    True  -> False
    False -> case list.is_empty(vals) {
      True  -> running_total == target_total
      False -> {
        let assert Ok(next_val) = list.first(vals)
        let assert Ok(rest_vals) = list.rest(vals)
        do_has_solution1(target_total, running_total + next_val, rest_vals) ||
        do_has_solution1(target_total, running_total * next_val, rest_vals)
      }
    }
  }
}

fn do_has_solution2(target_total: Int, running_total: Int, vals: List(Int)) -> Bool
{
  case running_total > target_total {
    True  -> False
    False -> case list.is_empty(vals) {
      True  -> running_total == target_total
      False -> {
        let assert Ok(next_val) = list.first(vals)
        let assert Ok(rest_vals) = list.rest(vals)
        do_has_solution2(target_total, running_total + next_val, rest_vals) ||
        do_has_solution2(target_total, running_total * next_val, rest_vals) ||
        do_has_solution2(target_total, concat(running_total, next_val), rest_vals)
      }
    }
  }
}

fn concat(a: Int, b: Int) -> Int
{
  let assert Ok(ret) = int.parse(int.to_string(a) <> int.to_string(b))
  ret
}

pub fn part1()
{
  let ans = parse()
  |> list.filter(has_solution(_, False))
  |> list.map(fn (eqn) { eqn.0 })
  |> int.sum

  io.debug(ans)
}

pub fn part2()
{
  let ans = parse()
  |> list.filter(has_solution(_, True))
  |> list.map(fn (eqn) { eqn.0 })
  |> int.sum

  io.debug(ans)
}
