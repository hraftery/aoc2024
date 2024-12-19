import gleam/int
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{Some}
import gleamy/priority_queue.{type Queue} as pq

pub type SuccessorNodes(node_id) = fn(node_id) -> Dict(node_id, Int)
pub type Distances(node_id) = Dict(node_id, Int)
pub type Predecessors(node_id) = Dict(node_id, node_id)
pub type ShortestPaths(node_id) {
  ShortestPaths(distances: Distances(node_id),
                predecessors: Predecessors(node_id))
}

pub fn dijkstra(edges_from: SuccessorNodes(node_id),
                start: node_id) -> ShortestPaths(node_id)
{
  let dist = dict.from_list([#(start, 0)])
  let q = pq.from_list([#(start, 0)], fn(a, b) { int.compare(a.1, b.1) })

  do_dijkstra(edges_from, dist, dict.new(), q)
}

fn do_dijkstra(edges_from: SuccessorNodes(node_id),
               dist: Distances(node_id), pred: Predecessors(node_id),
               q: Queue(#(node_id, Int))) -> ShortestPaths(node_id)
{
  case pq.is_empty(q) {
    True  -> ShortestPaths(dist, pred)
    False -> {
      let assert Ok(#(#(u, _), q)) = pq.pop(q)
      let #(dist, pred, q) = dict.fold(edges_from(u), #(dist, pred, q), fn(acc, v, uv_dist) {
        let #(dist, pred, q) = acc
        let assert Ok(u_dist) = dict.get(dist, u)
        let alt = u_dist + uv_dist
        case dict.get(dist, v) {
          Ok(v_dist) if alt >= v_dist -> acc //If already have a shorter route, then no changes.
          _ -> #(dict.insert(dist, v, alt),  //Otherwise update dist,
                 dict.insert(pred, v, u),    //pred,
                 pq.push(q, #(v, alt)))      //and q.
        }
      })
      do_dijkstra(edges_from, dist, pred, q)
    }
  }
}

type NodeId = Int
pub fn test_dijkstra() -> Bool
{
  //use example from https://www.geeksforgeeks.org/dijkstras-shortest-path-algorithm-greedy-algo-7/
  let f = fn(node_id: NodeId) -> Dict(NodeId, Int) {
    case node_id {
      0 -> dict.from_list([#(1,4),#(7,8)])
      1 -> dict.from_list([#(0,4),#(7,11),#(2,8)])
      7 -> dict.from_list([#(0,8),#(1,11),#(8,8),#(6,1)])
      2 -> dict.from_list([#(1,8),#(8,2),#(3,7),#(5,4)])
      8 -> dict.from_list([#(7,7),#(2,2),#(6,6)])
      6 -> dict.from_list([#(7,1),#(8,6),#(5,2)])
      3 -> dict.from_list([#(2,7),#(5,14),#(4,9)])
      5 -> dict.from_list([#(6,2),#(2,4),#(3,14),#(4,10)])
      4 -> dict.from_list([#(3,9),#(5,10)])
      _ -> panic as "huh"
    }
  }
  let paths = dijkstra(f, 0)
  paths.distances == dict.from_list([
    #(0, 0),
    #(1, 4),
    #(2, 12),
    #(3, 19),
    #(4, 21),
    #(5, 11),
    #(6, 9),
    #(7, 8),
    #(8, 14)])
}

pub fn has_path_to(paths: ShortestPaths(node_id), dest: node_id)
{
  dict.has_key(paths.distances, dest)
}

pub fn shortest_path(paths: ShortestPaths(node_id), dest: node_id) -> #(List(node_id), Int)
{
  let path = do_shortest_path(paths.predecessors, dest)
  let assert Ok(dist) = dict.get(paths.distances, dest)
  #(list.reverse(path), dist)
}

fn do_shortest_path(predecessors, curr) -> List(node_id)
{
  case dict.get(predecessors, curr) {
    Error(_) -> [curr]
    Ok(pred) -> [curr, ..do_shortest_path(predecessors, pred)]
  }
}

pub type AllPredecessors(node_id) = Dict(node_id, List(node_id))
pub type AllShortestPaths(node_id) {
  AllShortestPaths(distances: Distances(node_id),
                    predecessors: AllPredecessors(node_id))
}

//Same as dijkstra, except each node predecessor is a list instead of a single node.
//If there are multiple shortest paths, junction nodes will have more than one predecessor.
pub fn dijkstra_all(edges_from: SuccessorNodes(node_id),
                    start: node_id) -> AllShortestPaths(node_id)
{
  let dist = dict.from_list([#(start, 0)])
  let q = pq.from_list([#(start, 0)], fn(a, b) { int.compare(a.1, b.1) })

  do_dijkstra_all(edges_from, dist, dict.new(), q)
}

fn do_dijkstra_all(edges_from: SuccessorNodes(node_id),
                   dist: Distances(node_id), pred: AllPredecessors(node_id),
                   q: Queue(#(node_id, Int))) -> AllShortestPaths(node_id)
{
  case pq.is_empty(q) {
    True  -> AllShortestPaths(dist, pred)
    False -> {
      let assert Ok(#(#(u, _), q)) = pq.pop(q)
      let #(dist, pred, q) = dict.fold(edges_from(u), #(dist, pred, q), fn(acc, v, uv_dist) {
        let #(dist, pred, q) = acc
        let assert Ok(u_dist) = dict.get(dist, u)
        let alt = u_dist + uv_dist
        case dict.get(dist, v) {
          Ok(v_dist) if alt >  v_dist -> acc  //If already have a shorter route, then no changes.
          Ok(v_dist) if alt == v_dist -> {    //If already have a same dist route, then
            #(dist,                           //  leave dist alone,
              dict.upsert(pred, v, fn(x) {    
                case x { Some(i) -> [u, ..i]  //  prepend to pred,
                         _ -> panic as "BUG" }}),
              q)}                             //  and leave q alone.
          _ -> #(dict.insert(dist, v, alt),   //Otherwise this is the shortest route, so update dist,
                 dict.insert(pred, v, [u]),   //  pred,
                 pq.push(q, #(v, alt)))       //  and q.
        }
      })
      do_dijkstra_all(edges_from, dist, pred, q)
    }
  }
}

pub fn shortest_paths(all_paths: AllShortestPaths(node_id), dest: node_id) -> #(List(List(node_id)), Int)
{
  let paths = do_shortest_paths(all_paths.predecessors, [], dest)
  let assert Ok(dist) = dict.get(all_paths.distances, dest)
  #(paths, dist)
}

fn do_shortest_paths(predecessors: AllPredecessors(node_id), path: List(node_id),
                     curr: node_id) -> List(List(node_id))
{
  let new_path = [curr, ..path]
  case dict.get(predecessors, curr) {
    Error(_)  -> [new_path]
    Ok(preds) -> list.flat_map(preds, do_shortest_paths(predecessors, new_path, _))
  }
}

pub fn test_dijkstra_all() -> Bool
{
  let f = fn(node_id: NodeId) -> Dict(NodeId, Int) {
    case node_id {
      0 -> dict.from_list([#(1,4),#(7,8)])
      1 -> dict.from_list([#(0,4),#(7,11),#(2,8)])
      //7 -> dict.from_list([#(0,8),#(1,11),#(#(8,8),#(#(6,1)])
      2 -> dict.from_list([#(1,8),#(8,2),#(3,7),#(5,4)])
      8 -> dict.from_list([#(7,7),#(2,2),#(6,6)])
      6 -> dict.from_list([#(7,1),#(8,6),#(5,2)])
      3 -> dict.from_list([#(2,7),#(5,14),#(4,9)])
      //5 -> dict.from_list([#(6,2),#(2,4),#(#(3,14),#(#(4,10)])
      4 -> dict.from_list([#(3,9),#(5,10)])

      //Add alternate route 7-9-5, with same distance as 7-6-5
      7 -> dict.from_list([#(0,8),#(1,11),#(8,8),#(6,1),#(9,2)])
      9 -> dict.from_list([#(7,2),#(5,1)])
      5 -> dict.from_list([#(6,2),#(2,4),#(3,14),#(4,10),#(9,1)])

      _ -> panic as "huh"
    }
  }
  let paths = dijkstra(f, 0)
  let shortest_path = shortest_path(paths, 4)
  let all_paths = dijkstra_all(f, 0)
  let shortest_paths = shortest_paths(all_paths, 4)

  shortest_path.1 == shortest_paths.1              && //Shortest path length is the same.
  list.contains(shortest_paths.0, shortest_path.0) && //One of shortest_paths is shortest_path.
  list.length(shortest_paths.0) == 2                  //There are two shortest_paths.
}
