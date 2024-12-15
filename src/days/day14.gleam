import gleam/io
import gleam/string
import gleam/int
import gleam/list
import simplifile as file
import gleam/regexp
import gleam/result
import util/util
import gleam/erlang/process
import gleam/set.{type Set}


const day = "14"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"

pub type Coord = #(Int, Int)
pub type Vec2 = #(Int, Int)
pub type Robot {
  Robot(p: Coord, v: Vec2)
}

fn space_size() -> #(Int, Int) {
  case string.contains(input_file, "example") {
    True -> #(11, 7)
    False -> #(101, 103)
  }
}

fn parse() -> List(Robot)
{
  let num = "([-+]?[0-9]+)"
  let regex_str = string.concat(["p=",num,",",num," v=",num,",",num])
  let assert Ok(re) = regexp.from_string(regex_str)
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.split("\n")
  |> list.map(fn(line) {
    let assert [px, py, vx, vy] = regexp.scan(re, line)
    |> util.extract_and_flatten_matches
    |> list.map(int.parse)
    |> result.values
    Robot(#(px, py), #(vx, vy))
  })
}

fn step(robots: List(Robot))
{
  step_multiple(1, robots)
}

fn step_multiple(num_steps: Int, robots: List(Robot))
{
  let #(width, height) = space_size()

  robots
  |> list.map(fn(robot) {
    let x = util.positive_modulo(robot.p.0 + robot.v.0 * num_steps, width)
    let y = util.positive_modulo(robot.p.1 + robot.v.1 * num_steps, height)
    Robot(..robot, p:#(x,y))
  })
}

fn draw(robots: List(Robot))
{
  let #(width, height) = space_size()

  let xs = list.range(0, width - 1)
  let ys = list.range(0, height - 1)

  list.each(ys, fn (y) {
    list.each(xs, fn (x) {
      case list.count(robots, fn(r) { r.p == #(x,y) }) {
        0 -> io.print(".")
        c -> io.print(int.to_string(c))
      }
    })
    io.println("")
  })
}

type Quadrant { TL TR BR BL }
fn count_in_quadrant(robots: List(Robot), quadrant: Quadrant)
{
  let #(width, height) = space_size()
  let #(mid_w, mid_h) = #(width/2, height/2)
  let #(xs, ys) = case quadrant {
    TL -> #(#(0,         mid_w - 1), #(0,         mid_h - 1))
    TR -> #(#(mid_w + 1, width - 1), #(0,         mid_h - 1))
    BR -> #(#(mid_w + 1, width - 1), #(mid_h + 1, height - 1))
    BL -> #(#(0,         mid_w - 1), #(mid_h + 1, height - 1))
  }
  
  list.count(robots, fn(r) {
    let #(px, py) = r.p
    px == int.clamp(px, xs.0, xs.1) &&
    py == int.clamp(py, ys.0, ys.1)
  })
}

fn is_horizontally_symmetrical(robots: List(Robot))
{
  let #(width, _height) = space_size()
  let mid_w = width/2
  
  let symmetry = list.count(robots, fn(r) {
    let #(px, py) = r.p
    px > mid_w && result.is_ok(list.find(robots, fn(r2) {
      r2.p.1 == py && r2.p.0 == width-1-px }))
  })

  symmetry > 40
}

fn is_horizontally_symmetrical_fast(robots: Set(Coord))
{
  let #(width, _height) = space_size()
  let mid_w = width/2
  
  let symmetry = list.count(set.to_list(robots), fn(r) {
    let #(px, py) = r
    px > mid_w && set.contains(robots, #(py, width-1-px))
  })

  symmetry > 20
}

fn is_quadrantally_symmetrical(robots: List(Robot))
{
  let assert [tl, tr, br, bl] = [TL, TR, BR, BL]
  |> list.map(count_in_quadrant(robots, _))
  
  util.abs(tl-tr) < 5 && util.abs(bl-br) < 10
}

fn is_continuous(robots: List(Robot))
{
  list.all(list.range(5, 50), fn(row) {
    list.count(robots, fn(r) {
      r.p.1 == row
    }) >= 2
  })
}

fn has_horizontal_line(robots: List(Robot))
{
  list.any(list.range(30, 100), fn(row) {
    list.count(robots, fn(r) {
      r.p.1 == row
    }) >= 40
  })
}

pub fn part1()
{
  let input = parse()
  let robots = step_multiple(100, input)
  let ans = [TL, TR, BR, BL]
  |> list.map(count_in_quadrant(robots, _))
  |> int.product
  io.debug(ans)
}

fn part2_loop(i: Int, state: List(Robot))
{
  let _ = case i % 10000 == 0 {
    True -> io.debug(i)
    False -> 0
  }

  //let pt_set = set.from_list(list.map(state, fn(r) { r.p }))
  case {i - 46} % 101 == 0 || {i - 104} % 103 == 0 { 
    True -> {
      io.debug(i)
      draw(state)
      io.println("")
      process.sleep(250)
    } 
    False -> Nil
  }

  part2_loop(i+1, step(state))
  Nil
}

pub fn part2()
{
  let input = parse()

  part2_loop(0, input)
}
