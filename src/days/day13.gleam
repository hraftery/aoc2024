import gleam/float
import gleam/io
import gleam/string
import gleam/int
import gleam/list
import simplifile as file
import gleam/regexp.{type Regexp}
import gleam/result
import util/util.{UniqueTwoByTwoSolution, InfiniteTwoByTwoSolutions, NoTwoByTwoSolution}


const day = "13"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.split("\n\n")
  |> list.map(parse_machine)
}

pub type Vec2 = #(Int, Int)
pub type Machine {
  Machine(a: Vec2, b: Vec2, p: Vec2)
}
pub type Play = #(Int, Int) //number of A presses, number of B presses

fn parse_machine_vector(re: Regexp, input: String) -> Vec2
{
  let assert [x, y] = regexp.scan(re, input)
  |> util.extract_and_flatten_matches
  |> list.map(int.parse)
  |> result.values

  #(x, y)
}

fn parse_machine(input: String) -> Machine
{
  let assert Ok(re1) = regexp.from_string("Button A: X\\+([0-9]+), Y\\+([0-9]+)")
  let assert Ok(re2) = regexp.from_string("Button B: X\\+([0-9]+), Y\\+([0-9]+)")
  let assert Ok(re3) = regexp.from_string("Prize: X=([0-9]+), Y=([0-9]+)")
  
  Machine(parse_machine_vector(re1, input),
          parse_machine_vector(re2, input),
          parse_machine_vector(re3, input))
}

fn solve_machine(m: Machine) -> Result(Play, Nil)
{
  //Simultaneously solve:
  //  prize.x = a_presses * a.x + b_presses * b.x
  //  prize.y = a_presses * a.y + b_presses * b.y
  //for unknowns a_presses and b_presses.
  let f = fn(i) { int.to_float(i) }
  let i = fn(f) { float.round(f) }
  let sol = case util.solve_two_by_two_equations(f(m.a.0), f(m.b.0), f(m.p.0),
                                                 f(m.a.1), f(m.b.1), f(m.p.1)) {
    UniqueTwoByTwoSolution(#(x,y))    -> #(i(x), i(y))
    InfiniteTwoByTwoSolutions(#(a,b)) -> { io.println("inf") #(1, i(a+.b)) } //pick any for now
    NoTwoByTwoSolution                -> #(0, 0)       //arbitrary wrong sol
  }

  //Check integer (rounded) solution works, and satisfies button press limit
  case m.p.0 == sol.0 * m.a.0 + sol.1 * m.b.0 &&
       m.p.1 == sol.0 * m.a.1 + sol.1 * m.b.1 {
    True ->  Ok(sol)
    False -> Error(Nil)
  }
}

pub fn part1()
{
  let machines = parse()
  let ans = machines
  |> list.map(solve_machine)
  |> result.values
  |> list.filter(fn (sol) {
    sol.0 == int.clamp(sol.0, 0, 100) &&
    sol.1 == int.clamp(sol.1, 0, 100)
  })
  |> list.map(fn(x) { 3 * x.0 + 1 * x.1 }) //to tokens
  |> int.sum

  io.debug(ans)
}

pub fn part2()
{
  let machines = parse()
  let ans = machines
  |> list.map(fn (m) { Machine(m.a, m.b, #(10000000000000 + m.p.0,
                                           10000000000000 + m.p.1))})
  |> list.map(solve_machine)
  |> result.values
  |> list.map(fn(x) { 3 * x.0 + 1 * x.1 }) //to tokens
  |> int.sum

  io.debug(ans)
}
