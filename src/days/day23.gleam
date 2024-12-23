import gleam/io
import gleam/string
import gleam/list
import gleam/dict.{type Dict}
import gleam/set.{type Set}
import gleam/result
import gleam/option.{Some, None}
import simplifile as file
import util/util


const day = "23"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.split("\n")
  |> list.map(string.split_once(_, "-"))
  |> result.values
}

fn group_edges_by_node(edges: List(#(String, String))) -> Dict(String, List(String))
{
  list.fold(edges, dict.new(), fn(acc, edge) {
    let f = fn(old_vals_opt, new_val) {
      case old_vals_opt {
        Some(old_vals)  -> [new_val, ..old_vals]
        None            -> [new_val]
      }
    }
    
    let #(n1, n2) = edge
    acc
    |> dict.upsert(n1, f(_, n2))
    |> dict.upsert(n2, f(_, n1))
  })
}

fn print_triangles(triangles: List(Set(String)))
{
  let ans = triangles
  |> list.map(set.to_list)
  |> list.map(list.intersperse(_, ","))
  |> list.intersperse(["\n"])
  |> list.flatten
  |> string.concat

  io.println(ans)
}

pub fn part1()
{
  let edges = parse()
  let by_node = group_edges_by_node(edges)
  
  let triangles = list.flat_map(edges, fn(edge) {
    let #(n1, n2) = edge
    let assert Ok(n1_neighbours) = dict.get(by_node, n1)
    let assert Ok(n2_neighbours) = dict.get(by_node, n2)
    let common_nodes = util.common_elements(n1_neighbours, n2_neighbours)
    list.map(common_nodes, fn(n) { set.from_list([n1, n2, n]) })
  })
  |> list.unique

  //print_triangles(triangles)

  let triangles = list.filter(triangles, fn(triangle) {
    triangle
    |> set.to_list
    |> list.any(string.starts_with(_, "t"))
  })

  //print_triangles(triangles)

  let ans = list.length(triangles)
  io.debug(ans)
}

pub fn part2()
{
  io.println("Day " <> day <> ", part 2.")
}

pub fn suppress_warnings()
{
  print_triangles([])
}
