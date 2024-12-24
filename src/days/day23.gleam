import gleam/int
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

fn get_triangles(edges, by_node) -> List(Set(String))
{
  list.flat_map(edges, fn(edge) {
    let #(n1, n2) = edge
    let assert Ok(n1_neighbours) = dict.get(by_node, n1)
    let assert Ok(n2_neighbours) = dict.get(by_node, n2)
    let common_nodes = util.common_elements(n1_neighbours, n2_neighbours)
    list.map(common_nodes, fn(n) { set.from_list([n1, n2, n]) })
  })
  |> list.unique
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

fn nodes_to_str(nodes: Set(String))
{
  nodes
  |> set.to_list
  |> list.intersperse(",")
  |> string.concat
}

fn nodes_to_alpha_str(nodes: Set(String))
{
  nodes
  |> set.to_list
  |> list.sort(string.compare) //Funnily enough, makes no difference. Sets are stored alphabetically, or coincidence?
  |> list.intersperse(",")
  |> string.concat
}


fn expand_sets(sets, triangles, by_node)
{
  let new_sets = list.flat_map(sets, fn(src) {
    list.filter_map(triangles, fn(dst) {
      case !set.is_subset(dst, src) && fully_connected(src, dst, by_node)
      {
        False -> Error(Nil)
        True  -> Ok(set.union(src, dst))
      }
    })
  })
  |> list.unique

  io.debug(list.map(new_sets, nodes_to_str))

  case list.is_empty(new_sets) {
    True  -> sets
    False -> expand_sets(new_sets, triangles, by_node)
  }
}

fn fully_connected(src, dst, by_node) -> Bool
{
  fully_connected_one_way(src, dst, by_node) &&
  fully_connected_one_way(dst, src, by_node)
}

fn fully_connected_one_way(src, dst, by_node) -> Bool
{
  list.all(set.to_list(src), fn(src_n) {
    case set.contains(dst, src_n) {
      True  -> True
      False -> {
        let assert Ok(src_n_neighbours) = dict.get(by_node, src_n)
        list.all(set.to_list(dst), fn(dst_n) { 
          list.contains(src_n_neighbours, dst_n)
        })
      }
    }
  })
}


type Vertex   = String
type Vertices = Set(Vertex)
type Edge     = #(Vertex, Vertex)

//much the same as group_edges_by_node except produces sets instead of lists
fn group_edges_by_node_as_set(edges: List(Edge)) -> Dict(Vertex, Vertices)
{
  list.fold(edges, dict.new(), fn(acc, edge) {
    let f = fn(old_vals_opt, new_val) {
      case old_vals_opt {
        Some(old_vals)  -> set.insert(old_vals, new_val)
        None            -> set.from_list([new_val])
      }
    }
    
    let #(n1, n2) = edge
    acc
    |> dict.upsert(n1, f(_, n2))
    |> dict.upsert(n2, f(_, n1))
  })
}

fn bron_kerbosch(edges: List(Edge)) -> List(Vertices)
{
  let edges_by_node = group_edges_by_node_as_set(edges)
  
  let r = set.new()
  let p = set.from_list(dict.keys(edges_by_node))
  let x = set.new()

  do_bron_kerbosch(r, p, x, edges_by_node, [])
}

//Without pivoting: https://en.wikipedia.org/wiki/Bron%E2%80%93Kerbosch_algorithm#Without_pivoting
fn do_bron_kerbosch(r: Vertices, p: Vertices, x: Vertices,
                    edges_by_node: Dict(Vertex, Vertices),
                    out: List(Vertices)) -> List(Vertices)
{
  //io.debug(#(set.to_list(r), set.to_list(p), set.to_list(x)))
  case set.is_empty(p) && set.is_empty(x) {
    True  -> [r, ..out]
    False -> {
      let #(_p, _x, new_out) = set.fold(p, #(p, x, out), fn(acc, v) {
        let #(p, x, out) = acc
        let assert Ok(v_neighbours) = dict.get(edges_by_node, v)
        let new_out = do_bron_kerbosch(set.insert(r, v),
                                       set.intersection(p, v_neighbours),
                                       set.intersection(x, v_neighbours),
                                       edges_by_node, out)
        let v_set = set.from_list([v])
        #(set.difference(p, v_set),
          set.union     (x, v_set),
          new_out)
      })
      new_out
    }
  }
}

fn test_bron_kerbosch()
{
  let edges = [
    #("6", "4"),
    #("4", "5"),
    #("4", "3"),
    #("5", "1"),
    #("5", "2"),
    #("3", "2"),
    #("1", "2")
  ]
  io.println("")

  let ans = edges
  |> bron_kerbosch
  |> list.map(nodes_to_str)

  io.debug(ans)
}

pub fn part1()
{
  let edges = parse()
  let by_node = group_edges_by_node(edges)
  let triangles = get_triangles(edges, by_node)

  //print_triangles(triangles)

  let t_triangles = list.filter(triangles, fn(triangle) {
    triangle
    |> set.to_list
    |> list.any(string.starts_with(_, "t"))
  })

  //print_triangles(t_triangles)

  let ans = list.length(t_triangles)
  io.debug(ans)
}

pub fn part2()
{
  //test_bron_kerbosch()

  let edges = parse()
  //let by_node = group_edges_by_node(edges)
  // let triangles = get_triangles(edges, by_node)
  // print_triangles(triangles)
  // io.println("")
  
  // let ans = expand_sets(triangles, triangles, by_node)
  // |> list.map(nodes_to_str)

  let ans = bron_kerbosch(edges)
  |> util.max_elem(fn(a, b) { int.compare(set.size(a), set.size(b)) })
  |> result.lazy_unwrap(fn() { panic as "bug" })
  |> nodes_to_alpha_str
  

  io.debug(ans)
}

pub fn suppress_warnings()
{
  print_triangles([])
  nodes_to_str(set.new())
  test_bron_kerbosch()
}
