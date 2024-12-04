import gleam/io
import gleam/string
//import gleam/int
//import gleam/list
import simplifile as file


const day = "01"
//const input_file = "input/" <> day <> ".txt"
const input_file = "input/" <> day <> "_example.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.split("\n")
}

pub fn part1()
{
  let _input = parse()
  io.println("Day " <> day <> ", part 1.")
}

pub fn part2()
{
  io.println("Day " <> day <> ", part 2.")
}
