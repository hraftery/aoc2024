import gleam/function
import gleam/io
import gleam/string
import gleam/int
import gleam/bool
import gleam/list.{Continue, Stop}
import gleam/dict.{type Dict}
import gleam/pair
import gleam/result
import simplifile as file
import util/util


const day = "24"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"
//const input_file = "input/" <> day <> "_example2.txt"

const bit_width: Int = 45

pub type Wire  = String
pub type Wires = List(Wire)
pub type GateOperation { AND OR XOR }
fn op_str(op: GateOperation) { case op { AND -> "·" OR  -> "+" XOR -> "⊕" } }
pub type Gate {
  Gate(in1: Wire, in2: Wire, op: GateOperation, out: Wire)
}
pub type Gates = Dict(Wire, Gate) //keyed by out Wire


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  let assert #(input_wire_vals, [_empty_str, ..input_gate_connections]) = raw_input
  |> string.trim
  |> string.split("\n")
  |> util.split_until(string.is_empty)
  
  #(parse_initial_wire_values(input_wire_vals), parse_gate_connections(input_gate_connections))
}

fn parse_initial_wire_values(input: List(String)) -> List(#(Wire, Bool))
{
  input
  |> list.map(string.split_once(_, ": "))
  |> result.values
  |> list.map(pair.map_second(_, fn(i_str) {
    case i_str {
      "1" -> True
      "0" -> False
      _   -> panic as "Unexpected wire initial value."
    }
  }))
}

fn parse_gate_connections(input: List(String)) -> Gates
{
  input
  |> list.map(fn(x) {
    let assert [i1, op_str, i2, _arrow, o] = string.split(x, " ")
    let op = case op_str {
      "AND" -> AND
      "OR"  -> OR
      "XOR" -> XOR
      _     -> panic as "unsupported gate operation"
    }
    #(o, Gate(i1, i2, op, o))
  })
  |> dict.from_list
}

fn execute(wire_state: Dict(Wire, Bool), gates: Gates) -> Dict(Wire, Bool)
{
  //io.debug(#(wire_state, gates))

  let #(new_wire_state, remaining_gates) = gates
  |> dict.fold(#(wire_state, dict.new()), fn(acc, out, gate) {
    let #(wire_state, remaining_gates) = acc
    case dict.get(wire_state, gate.in1), dict.get(wire_state, gate.in2) {
      Ok(i1), Ok(i2) ->
        #(dict.insert(wire_state, gate.out, apply_op(gate.op, i1, i2)), remaining_gates)
      _     , _      ->
        #(wire_state, dict.insert(remaining_gates, out, gate))
    }
  })

  case dict.is_empty(remaining_gates) {
    True  -> new_wire_state
    False -> execute(new_wire_state, remaining_gates)
  }
}

fn apply_op(op: GateOperation, i1: Bool, i2: Bool) -> Bool
{
  case op {
    AND -> i1 && i2
    OR  -> i1 || i2
    XOR -> bool.exclusive_or(i1, i2)
  }
}

fn z_to_int(wire_state: Dict(Wire, Bool)) -> Int
{
  wire_state
  |> dict.filter(fn(k,_v) { string.starts_with(k, "z") })
  |> dict.to_list
  |> list.sort(fn(a, b) {
    let a_z_num = string.drop_start(a.0, 1)
    let b_z_num = string.drop_start(b.0, 1)
    string.compare(a_z_num, b_z_num)
  })
  |> list.map(fn(x) { x.1 })
  |> list.reverse
  |> list.fold(0, fn(acc, x) {
    case x {
      True  -> int.bitwise_shift_left(acc, 1) + 1
      False -> int.bitwise_shift_left(acc, 1) + 0
    }
  })
}

fn make_input(x: Int, y: Int) -> Dict(Wire, Bool)
{
  list.range(0, bit_width - 1)
  |> list.flat_map(fn(i) {
    let wire_number = case i < 10 {
      True  -> "0" <> int.to_string(i)
      False -> int.to_string(i)
    }
    [#("x" <> wire_number, util.is_bit_set(x, i)),
     #("y" <> wire_number, util.is_bit_set(y, i))]
  })
  |> dict.from_list
}

// fn gates_with_input_wire(w: Wire, gates: Gates) -> Gates
// {
//   list.filter(gates, fn(g) { g.in1 == w || g.in2 == w })
// }

// fn gates_with_input_wires(ws: Wires, gates: Gates) -> List(Gates)
// {
//   list.map(ws, fn(w) {
//     list.filter(gates, fn(g) { g.in1 == w || g.in2 == w })
//   })
// }

// fn find_bad_gate(good_wires: Wires, bad_wires: Wires, gates: Gates) -> Gate
// {
//   let good_gates_list = gates_with_input_wires(good_wires, gates)
//   let  bad_gates_list = gates_with_input_wires( bad_wires, gates)

//   let bad_gate = list.zip(good_gates_list, bad_gates_list)
//   |> list.find(fn(gates_pair) {
//     let #(good_gates, bad_gates) = gates_pair
//     list.zip(good_gates, bad_gates)
//     |> list.find(fn(gate_pair) {
//       let #(good_gate, bad_gate) = gate_pair
//       good_gate 
//     })
//   } )
// }

// fn do_find_bad_gate(prev_good_gate: Gate, prev_bad_gate: Gate) -> Gate
// {
//   let good_gates = gates_with_input_wire(prev_good_gate.out)
//   let bad_gates  = gates_with_input_wire(prev_bad_gate.out)
//   let gate_pairs_res = list.strict_zip(good_gates, bad_gates)

//   case gate_pairs_res {
//     Error(Nil)     -> prev_bad_gate
//     Ok(gate_pairs) -> case list.all(gate_pairs, fn(gb) { gb.0.op == gb.1.op }) {
//       False -> prev_bad_gate
//       True  -> list
//   }
// }

fn get_num_errors(gates) -> Result(Int, Nil)
{
  case execute2(make_input(0, 0), gates) {
    Error(_) -> Error(Nil)
    _        -> {
      list.range(0, bit_width - 1)
      |> list.fold(0, fn(acc, i) {
        let val = int.bitwise_shift_left(1, i)
        let vmo = val - 1
        let x   = z_to_int(execute(make_input(val, 0  ), gates))
        let y   = z_to_int(execute(make_input(0  , val), gates))
        let xmo = z_to_int(execute(make_input(vmo, 1  ), gates))
        let ymo = z_to_int(execute(make_input(1  , vmo), gates))
        let sum = z_to_int(execute(make_input(val, val), gates))
        
        let new_acc = [x != val, xmo != vmo + 1, 
                       y != val, ymo != vmo + 1,
                       sum != val + val]
        |> list.count(function.identity)

        acc + new_acc
      })
      |> Ok
    }
  }
}

fn brute(gates: Gates) -> List(Wires)
{
  let assert Ok(num_errors) = get_num_errors(gates)
  
  let #(_gates, _num_errors, corrections) = gates
  |> dict.keys
  |> list.combination_pairs
  |> function.tap(fn(pairs) { io.debug(list.length(pairs)) })
  |> list.index_map(fn(x, i) { #(i, x) })
  |> list.fold_until(#(gates, num_errors, [[]]), fn(acc, i_pair) {
    let #(_, pair) = i_pair

    let #(gates, num_errors, corrections) = acc
    io.debug(#(i_pair, num_errors))
    
    let assert Ok(gate0) = dict.get(gates, pair.0)
    let assert Ok(gate1) = dict.get(gates, pair.1)
    //io.debug(#(gate0, gate1))

    let new_gates = gates
    |> dict.insert(pair.0, Gate(..gate1, out: gate0.out))
    |> dict.insert(pair.1, Gate(..gate0, out: gate1.out))
    //io.debug(#(dict.get(new_gates, pair.0), dict.get(new_gates, pair.1)))

    case get_num_errors(new_gates)
    {
      Error(_)            -> Continue(acc)
      Ok(new_num_errors)  -> {
        //io.debug(new_num_errors)
        let new_corrections = [[gate0.out, gate1.out], ..corrections]
        case new_num_errors == 0, new_num_errors < num_errors - 4 {
          True,  _     -> Stop(#(new_gates, new_num_errors, new_corrections))
          False, False -> Continue(acc)
          False, True  -> {
            io.debug(#(pair, new_num_errors, new_corrections))
            Continue(#(new_gates, new_num_errors, new_corrections))
          }
        }
      }
    }
  })

  corrections
}

//add error detection
fn execute2(wire_state: Dict(Wire, Bool), gates: Gates) -> Result(Dict(Wire, Bool), Nil)
{
  //io.debug(#(wire_state, gates))

  let #(new_wire_state, remaining_gates) = gates
  |> dict.fold(#(wire_state, dict.new()), fn(acc, out, gate) {
    let #(wire_state, remaining_gates) = acc
    case dict.get(wire_state, gate.in1), dict.get(wire_state, gate.in2) {
      Ok(i1), Ok(i2) ->
        #(dict.insert(wire_state, gate.out, apply_op(gate.op, i1, i2)), remaining_gates)
      _     , _      ->
        #(wire_state, dict.insert(remaining_gates, out, gate))
    }
  })

  let num_remaining_gates = dict.size(remaining_gates)
  case num_remaining_gates == 0, num_remaining_gates == dict.size(gates) {
    True,  _     -> Ok(new_wire_state)
    False, True  -> Error(Nil)
    False, False -> execute2(new_wire_state, remaining_gates)
  }
}

fn print_bit_correctness(gates: Gates)
{
  list.range(0, bit_width - 1)
  |> list.each(fn(i) {
    let val = int.bitwise_shift_left(1, i)
    let vmo = val - 1
    let x   = z_to_int(execute(make_input(val, 0  ), gates))
    let y   = z_to_int(execute(make_input(0  , val), gates))
    let xmo = z_to_int(execute(make_input(vmo, 1  ), gates))
    let ymo = z_to_int(execute(make_input(1  , vmo), gates))
    let sum = z_to_int(execute(make_input(val, val), gates))
    
    io.debug(#(i, x == val, y == val, xmo == vmo + 1, ymo == vmo + 1, sum == val + val))
  })
}

fn formula_for_wire(wire: Wire, gates: Gates) -> String
{
  wire <> "=" <> do_formula_for_wire(wire, gates)
}

fn do_formula_for_wire(wire: Wire, gates: Gates) -> String
{  
  case string.starts_with(wire, "x") || string.starts_with(wire, "y")
  {
    True  -> wire
    False -> {
      let assert Ok(g) = dict.get(gates, wire)
      "(" <> do_formula_for_wire(g.in1, gates)
          <> op_str(g.op)
          <> do_formula_for_wire(g.in2, gates)
          <> ")"
    }
  }
}

fn to_graphviz(gates: Gates)
{
  let op_shape = fn(op) { case op { AND -> "box" OR  -> "circle" XOR -> "doublecircle" } }
  io.println("digraph {")
  dict.each(gates, fn(_out, gate) {
    io.println(gate.in1 <> " -> _" <> gate.out <> " -> " <> gate.out)
    io.println(gate.in2 <> " -> _" <> gate.out)
  })
  dict.each(gates, fn(_out, gate) {
    io.println("_" <> gate.out <> " [shape=" <> op_shape(gate.op) <> "]")
  })
  io.println("}")
}

pub fn part1()
{
  let input = parse()
  //io.debug(input)

  let wire_state = dict.from_list(input.0)
  let ans = execute(wire_state, input.1)
  |> z_to_int

  io.debug(ans)
}

pub fn part2()
{
  let #(_, gates) = parse()
  //io.debug(input)

  //print_bit_correctness(gates)
  let ans = brute(gates)
  io.debug(ans)
}

pub fn suppress_warnings()
{
  brute(dict.new())
  print_bit_correctness(dict.new())
  formula_for_wire("", dict.new())
  to_graphviz(dict.new())
}
