import gleam/io
import gleam/string
import gleam/list
import gleam/set.{type Set}
import simplifile as file
import util/array2d.{type Array2D, type Char, type Coord, type Coords}
import util/compass


const day = "12"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"
//const input_file = "input/" <> day <> "_example2.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.split("\n")
  |> array2d.from_list_of_strings
}

pub type Region {
  Region(plant: Char, coords: Coords, perimeter_length: Int)
}

fn find_all_regions(map: Array2D(Char)) -> List(Region)
{
  map
  |> array2d.coords
  |> set.from_list
  |> do_find_all_regions(map, _)
}

fn do_find_all_regions(map: Array2D(Char), remaining_coords: Set(Coord)) -> List(Region)
{
  case set.is_empty(remaining_coords) {
    True  -> [] //done
    False -> {
      let assert Ok(next_region_start_pt) = list.first(set.to_list(remaining_coords))
      let new_region = find_region(map, next_region_start_pt)
      let new_remaining_coords = set.difference(remaining_coords,
                                                set.from_list(new_region.coords))
      [new_region, ..do_find_all_regions(map, new_remaining_coords)]
    }
  }
}

type RegionAcc {
  RegionAcc(plant: Char, region: Coords, perimeter: Int, front_line: Coords)
}

fn find_region(map: Array2D(Char), start_pt: Coord) -> Region
{
  let assert Ok(plant) = array2d.get(map, start_pt)
  expand_region(map, RegionAcc(plant, [start_pt], 0, [start_pt]))
}

fn expand_region(map: Array2D(Char), region_acc: RegionAcc) -> Region
{
  //io.debug(region_acc)
  let in = RegionAcc(..region_acc, front_line: [])
  let out = list.fold(region_acc.front_line, in, fn(outer_acc, pt) {
    [compass.N, compass.E, compass.S, compass.W]
    |> list.map(array2d.get_neighbour(map, pt, _))
    |> list.fold(outer_acc, fn(acc, neighbour) {
      case neighbour {
        #(new_pt, Ok(p)) if p == acc.plant
          -> {  case list.contains(acc.region, new_pt) || list.contains(acc.front_line, new_pt) {
                  True  -> acc //going backwards or already counted, so no change
                  False -> RegionAcc(..acc, front_line: [new_pt, ..acc.front_line]) // expand
                }
             }
        _ -> RegionAcc(..acc, perimeter: acc.perimeter + 1) // off map or wrong plant
      }
    })
  })

  case list.is_empty(out.front_line) {
    True -> Region(out.plant, coords:out.region, perimeter_length:out.perimeter) //we're done
    False -> expand_region(map, //otherwise, go again after expanding the region to the new front_line
                           RegionAcc(..out, region: list.flatten([out.region, out.front_line])))
  }
}

pub fn part1()
{
  let input = parse()
  //let coords = set.from_list(array2d.coords(input))
  //let region = find_region(input, #(0,0))
  let regions = find_all_regions(input)

  let ans = regions
  |> list.map(fn(r) {
    #(list.length(r.coords), r.perimeter_length)
  })
  |> list.fold(0, fn(acc, area_len) {
    acc + area_len.0 * area_len.1
  })

  io.debug(ans)
}

pub fn part2()
{
  io.println("Day " <> day <> ", part 2.")
}
