import gleam/option.{Some}
import gleam/regexp
import gleam/io
import gleam/string
import gleam/int
import gleam/list
import simplifile as file
import util/util

const day = "03"

const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
}

fn extract_muls(input)
{
  let assert Ok(re) = regexp.from_string("mul\\(([0-9]{1,3},[0-9]{1,3})\\)")
  list.map(regexp.scan(re, input),
           fn (match) { let assert Ok(Some(capture)) = list.first(match.submatches)
                        capture })
}

fn apply_mul(mul : String)
{
  let assert [Ok(a),Ok(b)] = list.map(string.split(mul, ","), int.parse)
  a * b
}

fn remove_donts(input)
{
  let assert [first, ..rest] = string.split(input, "don't()")
  string.concat([first, ..list.map(rest, util.crop_until(_, "do()"))])
}

pub fn part1()
{
  let result = parse()
  |> extract_muls
  |> list.map(apply_mul)
  |> int.sum

  io.debug(result)
}

pub fn part2()
{
  let result = parse()
  |> remove_donts
  |> extract_muls
  |> list.map(apply_mul)
  |> int.sum

  io.debug(result)
}
