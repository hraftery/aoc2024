import gleam/io
import gleam/string
import gleam/int
import gleam/list
//import gleam/result
import simplifile as file

const day = "01"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.split("\n")
  |> list.map(parse_line)
  |> list.unzip
}

fn parse_line(line)
{
  let assert [Ok(a), Ok(b)] = string.split(line, "   ")
                              |> list.map(int.parse)
  #(a,b)
}

pub fn part1()
{
  let #(a,b) = parse()

  let result =
    list.zip(list.sort(a, by: int.compare),
             list.sort(b, by: int.compare))
    |> list.map(fn(x) { int.absolute_value(x.0-x.1) } )
    |> int.sum
  
  io.println(int.to_string(result))
}

pub fn part2()
{
  let #(a,b) = parse()
  
  let result =
    list.map(a, fn(ai) { ai * list.count(b, fn(bi) { ai == bi } )})
    |> int.sum
  
  io.println(int.to_string(result))
}
