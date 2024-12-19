import gleam/io
import gleam/string
import gleam/int
import gleam/list
import gleam/pair
import gleam/dict.{type Dict}
import simplifile as file
import util/dijkstra.{type SuccessorNodes}


const day = "19"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  let assert [patterns_str, _blank_line, ..design_list]
    = string.split(string.trim(raw_input), "\n")
  
  #(string.split(patterns_str, ", "), design_list)
}

type NodeId = String 

fn make_graph_fn(patterns: List(String)) -> SuccessorNodes(NodeId)
{
  fn(remaining_design: NodeId) -> Dict(NodeId, Int) {
    list.filter_map(patterns, fn (pattern) {
      case string.starts_with(remaining_design, pattern) {
        False -> Error(Nil)
        True  -> Ok(#(string.drop_start(remaining_design, string.length(pattern)), 1))
      }
    })
    |> dict.from_list
  }
}

fn bfs(patterns, cache, remaining_design)
{
  //io.println("Design: " <> remaining_design)

  case string.is_empty(remaining_design) {
    True  -> #(1, cache)
    False -> {
      case dict.get(cache, remaining_design) {
        Ok(i)    -> #(i, cache) //Cache hit
        Error(_) -> {
          let #(i, new_cache) = patterns
          |> list.filter(string.starts_with(remaining_design, _))
          |> list.fold(#(0, cache), fn (acc, pattern) {
            let #(sub_i, sub_cache) = remaining_design
            |> string.drop_start(string.length(pattern))
            |> bfs(patterns, acc.1, _)
            #(acc.0 + sub_i, dict.merge(acc.1, sub_cache))
          })
          #(i, dict.insert(new_cache, remaining_design, i))
        }
      }
    }
  }
}

pub fn part1()
{
  let #(patterns, designs) = parse()
  
  let ans = list.count(designs, fn(design) {
    make_graph_fn(patterns)
    |> dijkstra.dijkstra(design)
    |> dijkstra.has_path_to("")
  })
  
  io.debug(ans)
}

pub fn part2()
{
  let #(patterns, designs) = parse()
  
  let ans = designs
  |> list.map(bfs(patterns, dict.new(), _))
  |> list.map(pair.first)
  |> int.sum

  io.debug(ans)
}
