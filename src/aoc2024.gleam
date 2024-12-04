import gleam/io
import argv

import days/day01
import days/day02
import days/day03
import days/day04
// import days/day05
// import days/day06
// import days/day07
// import days/day08
// import days/day09
// import days/day10
// import days/day11
// import days/day12
// import days/day13
// import days/day14
// import days/day15
// import days/day16
// import days/day17
// import days/day18
// import days/day19
// import days/day20
// import days/day21
// import days/day22
// import days/day23
// import days/day24
// import days/day25


type Parts {
  One
  Two
}

pub fn main()
{
  case argv.load().arguments
  {
    [day, part] -> case part {
                              "1" -> run(day, One)
                              "2" -> run(day, Two)
                              _   -> io.println("Invalid part. Must be '1' or '2'.")
                            }
    [day]       -> { run(day, One) run(day, Two) }
    _ -> io.println("Usage: gleam run day [part]")
  }
}

fn run_helper(part, part1, part2)
{
  case part { One -> {part1() Nil} Two -> {part2() Nil} }
  Nil //Ensure each day returns the same type, regardless of what the days do.
}

fn run(day, part)
{
  io.println("Running day " <> day <>
             ", part " <> case part { One -> "1" Two -> "2"} <> ".")
  case day {
    "1" -> run_helper(part, day01.part1, day01.part2)
    "2" -> run_helper(part, day02.part1, day02.part2)
    "3" -> run_helper(part, day03.part1, day03.part2)
    "4" -> run_helper(part, day04.part1, day04.part2)
    _   -> io.println("Invalid day.")
  }
}
