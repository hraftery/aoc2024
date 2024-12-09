import gleam/result
import gleam/io
import gleam/string
import gleam/int
import gleam/list
import gleam/order.{Gt, Lt}
import simplifile as file
import util/util


const day = "05"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  let assert #(input_rules, [_empty_str, ..input_updates]) = raw_input
  |> string.trim
  |> string.split("\n")
  |> util.split_until(string.is_empty)
  
  #(parse_rules(input_rules), parse_updates(input_updates))
}

fn parse_rules(input)
{
  list.map(input, fn(rule) {
    let assert [Ok(a), Ok(b)] = string.split(rule, "|")
                                |> list.map(int.parse)
    #(a,b)
  })
}

fn parse_updates(input)
{
  list.map(input, fn(update) {
    string.split(update, ",")
    |> list.map(int.parse)
    |> list.map(result.unwrap(_, 0))
  })
}

fn is_correctly_ordered(update, rules)
{
  list.combination_pairs(update)
  |> list.all(fn (pair) { list.contains(rules, pair) })
}

fn get_middle_page(update)
{
  let assert Ok(page) = update
                        |> list.drop(list.length(update) / 2)
                        |> list.first
  page
}

fn sort(update, rules)
{
  list.sort(update, fn (a, b) {
    case list.contains(rules, #(a,b)) {
      True  -> Lt
      False -> Gt //ignore Eq case because it doesn't matter
    }
  })
}

pub fn part1()
{
  let #(rules, updates) = parse()
  
  let sum = updates
            |> list.filter(is_correctly_ordered(_, rules))
            |> list.map(get_middle_page)
            |> int.sum
  
  io.debug(sum)
}

pub fn part2()
{
  let #(rules, updates) = parse()
  
  let sum = updates
            |> list.filter(fn (update) { !is_correctly_ordered(update, rules) })
            |> list.map(sort(_, rules))
            |> list.map(get_middle_page)
            |> int.sum
  
  io.debug(sum)
}
