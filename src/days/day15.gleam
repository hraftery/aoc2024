import gleam/io
import gleam/string
import gleam/list
import gleam/int
import gleam/dict
import simplifile as file
import util/util
import util/matrix.{Matrix, type Matrix, type Char}
import util/compass.{type Direction, type Coord, type Coords}


const day = "15"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"
//const input_file = "input/" <> day <> "_example2.txt"
//const input_file = "input/" <> day <> "_example3.txt"

fn parse() -> #(Matrix(Char), List(Direction))
{
  let assert Ok(raw_input) = file.read(input_file)
  let assert [map, movements] = raw_input
  |> string.trim
  |> string.split("\n\n")

  #(matrix.from_list_of_strings(string.split(map, "\n"), "."),
    list.filter_map(string.to_graphemes(movements), fn(m) {
      case m {
        "^" -> Ok(compass.N)
        ">" -> Ok(compass.E)
        "v" -> Ok(compass.S)
        "<" -> Ok(compass.W)
        _   -> Error(Nil)
      }
    }))
}

fn draw(mat: Matrix(Char))
{
  let xs = list.range(0, mat.num_cols - 1)
  let ys = list.range(0, mat.num_rows - 1)

  list.each(ys, fn (y) {
    list.each(xs, fn (x) {
      case dict.get(mat.data, #(x,y)) {
        Ok(c)    -> io.print(c)
        Error(_) -> io.print(".")
      }
    })
    io.println("")
  })
}

fn move(map: Matrix(Char), dir: Direction) -> Matrix(Char)
{
  let assert Ok(curr_pt) = matrix.find(map, fn(v) { v == "@" })
  case next_dot(map, dir, curr_pt) {
    Error(_)   -> map //can't move
    Ok(end_pt) -> shift(map, curr_pt, dir, end_pt)
  }
}

fn next_dot(map: Matrix(Char), dir: Direction, curr_pt: Coord) -> Result(Coord, Nil)
{
  let next_pt = compass.get_neighbour(curr_pt, dir)
  case dict.get(map.data, next_pt) {
    Error(_) -> Ok(next_pt) //Found the next dot
    Ok("#")  -> Error(Nil)  //Blocked. Look no further.
    Ok("O")  -> next_dot(map, dir, next_pt) //Keep looking past runs of "O"
    _ -> panic as "Unexpected map value"
  }
}

fn shift(map: Matrix(Char), start_pt: Coord, dir: Direction, end_pt: Coord) -> Matrix(Char)
{
  //work backwards from end_pt
  let prev_pt = compass.get_neighbour(end_pt, compass.opposite(dir))
  case start_pt == prev_pt {
    True  -> //Last move: shift the robot
      Matrix(..map, data:{ map.data |> dict.insert(end_pt, "@")
                                    |> dict.delete(start_pt) })
    False -> //Recursive move: shift a box (possibly redundantly)
      shift(Matrix(..map, data:dict.insert(map.data, end_pt, "O")),
            start_pt, dir, prev_pt) //and go again with new end_pt
  }
}

fn widen(map: Matrix(Char)) -> Matrix(Char)
{
  let data = dict.fold(map.data, dict.new(), fn(acc, k, v) {
    let #(x,y) = k
    case v {
      "#" -> { acc |> dict.insert(#(x*2,y), "#") |> dict.insert(#(x*2+1,y), "#") }
      "@" -> { acc |> dict.insert(#(x*2,y), "@")                                 }
      "O" -> { acc |> dict.insert(#(x*2,y), "[") |> dict.insert(#(x*2+1,y), "]") }
      _   -> panic as "Unexpected map value."
    }
  })
  Matrix(data:data, num_rows:map.num_rows, num_cols:map.num_cols*2)
}

fn move2(map: Matrix(Char), dir: Direction) -> Matrix(Char)
{
  let assert Ok(curr_pt) = matrix.find(map, fn(v) { v == "@" })
  //let _ = io.debug(get_mass(map, dir, [curr_pt]))
  case get_mass(map, dir, [curr_pt]) {
    Error(_) -> map //can't move
    Ok(mass) -> shift_mass(map, mass, dir)
  }
}

fn get_mass(map: Matrix(Char), dir: Direction, mass: Coords) -> Result(Coords, Nil)
{
  let new_pts = mass
  |> list.map(compass.get_neighbour(_, dir))
  |> list.filter(util.missing(mass, _))

  let new_vals = list.map(new_pts, dict.get(map.data, _))
  let is_blocked = list.any(new_vals, fn(v) { v == Ok("#") })
  let is_growing = list.any(new_vals, fn(v) { v == Ok("[") || v == Ok("]") })
  
  case is_blocked, is_growing {
    True,  _     -> Error(Nil)  //Blocked. Look no further.
    False, False -> Ok(mass)    //new_pts are empty, so free to move!
    False, True  -> {           //Otherwise we need to grow and keeping looking past the mass
      let new_mass = new_pts
      |> list.flat_map(fn(pt) {
        let #(x,y) = pt
        case dict.get(map.data, pt) {
          Ok("]")  -> [#(x-1,y), pt]
          Ok("[")  -> [pt, #(x+1,y)]
          Error(_) -> [] //don't include empty cells in mass
          _        -> panic as "Unexpected map value"
        }
      })
      |> list.unique
      |> list.append(mass)
      get_mass(map, dir, new_mass)
    }
  }
}

fn shift_mass(map: Matrix(Char), mass: Coords, dir: Direction) -> Matrix(Char)
{
  let data = map.data
  |> dict.fold(dict.new(), fn(d, k, v) {
    case list.contains(mass, k) {
      False -> dict.insert(d, k, v) //add with no change
      True  -> dict.insert(d, compass.get_neighbour(k, dir), v) //shift
    }
  })
  
  Matrix(..map, data:data)
}

pub fn part1()
{
  let #(map, dirs) = parse()

  // io.println("Initiial state:")
  // draw(map)

  let map = list.fold(dirs, map, fn(map, dir) {
    // let map = move(map, dir)
    // io.println("")
    // io.print("Move ")
    // io.debug(dir)
    // draw(map)
    // map
    move(map, dir)
  })
  
  let ans = map.data
  |> dict.filter(fn(_k, v) { v == "O" })
  |> dict.keys
  |> list.map(fn(coord) { coord.0 + 100 * coord.1 })
  |> int.sum

  io.debug(ans)
}

pub fn part2()
{
  let #(map, dirs) = parse()

  let map = widen(map)

  // io.println("Initial state:")
  // draw(map)

  let map = list.fold(dirs, map, fn(map, dir) {
    // let map = move2(map, dir)
    // io.println("")
    // io.print("Move ")
    // io.debug(dir)
    // draw(map)
    // map
    move2(map, dir)
  })

  let ans = map.data
  |> dict.filter(fn(_k, v) { v == "[" })
  |> dict.keys
  |> list.map(fn(coord) { coord.0 + 100 * coord.1 })
  |> int.sum

  io.debug(ans)
}


pub fn suppress_unused_warnings()
{
  let #(map, _dirs) = parse()

  io.println("Initiial state:")
  draw(map)
}
