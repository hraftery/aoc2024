import gleam/io
import gleam/string
import gleam/int
import gleam/list.{Continue, Stop}
import gleam/result
import simplifile as file
import glearray.{type Array} as array

const day = "17"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"
//const input_file = "input/" <> day <> "_example2.txt"

type Program = Array(Int)
type State {
  State(a: Int, b: Int, c: Int, pc: Int, out: Array(Int))
}
type OpCode { ADV BXL BST JNZ BXC OUT BDV CDV }
fn from_int(i: Int) -> OpCode { case i {
  0 -> ADV
  1 -> BXL
  2 -> BST
  3 -> JNZ
  4 -> BXC
  5 -> OUT
  6 -> BDV
  7 -> CDV
  _ -> panic as "invalid opcode" }}


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  let assert [a_line, b_line, c_line, _blank, p_line] = raw_input
  |> string.trim
  |> string.split("\n")
  let assert Ok(#(_, a_str)) = string.split_once(a_line, "A: ")
  let assert Ok(#(_, b_str)) = string.split_once(b_line, "B: ")
  let assert Ok(#(_, c_str)) = string.split_once(c_line, "C: ")
  let assert Ok(#(_, p_str)) = string.split_once(p_line, "m: ")
  let assert Ok(a) = int.parse(a_str)
  let assert Ok(b) = int.parse(b_str)
  let assert Ok(c) = int.parse(c_str)
  let p = result.values(list.map(string.split(p_str, ","), int.parse))
  #(State(a, b, c, 0, array.new()), array.from_list(p))
}

fn run(prog: Program, state: State) -> Array(Int)
{
  case step(prog, state) {
    Error(_)  -> state.out
    Ok(state) -> run(prog, state)
  }
}

fn step(prog: Program, st: State) -> Result(State, Nil)
{
  case array.get(prog, st.pc) {
    Error(_)   -> Error(Nil) //halt
    Ok(opcode) -> {
      let assert Ok(operand) = array.get(prog, st.pc + 1)
      let op_mod_8 = combo(st, operand) % 8
      let st = case from_int(opcode) {
        ADV -> State(..st, a:int.bitwise_shift_right(st.a, combo(st, operand)))
        BXL -> State(..st, b:int.bitwise_exclusive_or(st.b, operand))
        BST -> State(..st, b:op_mod_8)
        JNZ if st.a == 0 -> st
        JNZ -> State(..st, pc:operand - 2)
        BXC -> State(..st, b:int.bitwise_exclusive_or(st.b, st.c))
        OUT -> State(..st, out:array.copy_push(st.out, op_mod_8))
        BDV -> State(..st, b:int.bitwise_shift_right(st.a, combo(st, operand)))
        CDV -> State(..st, c:int.bitwise_shift_right(st.a, combo(st, operand)))
      }
      Ok(State(..st, pc:st.pc + 2))
    }
  }
}

fn combo(state: State, operand: Int) -> Int
{
  case operand {
    0 -> 0
    1 -> 1
    2 -> 2
    3 -> 3
    4 -> state.a
    5 -> state.b
    6 -> state.c
    _ -> panic as "invalid operand"
  }
}

fn run_bf(prog: Program, initial_a: Int) -> Int
{
  let state = State(a:initial_a, b: 0, c: 0, pc:0, out: array.new())
  case do_run_bf(prog, state, 0, initial_a) {
    True  -> state.a
    False -> run_bf(prog, state.a + 1)
  }
}

fn do_run_bf(prog: Program, state: State, num_correct: Int, initial_a: Int) -> Bool
{
  case step(prog, state) {
    Error(_)  -> False //halted before success
    Ok(state) -> {
      let out_len = array.length(state.out)
      let new_out = out_len > num_correct
      let new_out_correct = case new_out {
        False -> False //ignore
        True  -> array.get(prog, out_len - 1) == array.get(state.out, out_len - 1)
      }
      let num_correct = case new_out_correct {
        True  -> num_correct + 1
        False -> num_correct
      }
      let out_len_is_prog_len = out_len == array.length(prog)

      case new_out && !new_out_correct && num_correct > 7 {
        True -> io.println(int.to_string(initial_a) <> "," <> int.to_string(num_correct))
        False -> Nil
      }

      case new_out, new_out_correct, out_len_is_prog_len {
        True, True,  True -> True //we're done
        True, False, _    -> False  //out has strayed from prog, give up
        _   , _,     _    -> do_run_bf(prog, state, num_correct, initial_a) //keep going
      }
    }
  }
}

fn out_to_str(out: Array(Int)) -> String
{
  out
  |> array.to_list
  |> list.map(int.to_string)
  |> list.intersperse(",")
  |> string.concat
}

fn shift_left_by_octet(i: Int) -> Int
{
  int.bitwise_shift_left(i, 3)
}

fn find_a(prog: Array(Int), a_so_far: Int, octets_found: Int) -> Result(Int, Nil)
{
  // let assert Ok(a_str) = int.to_base_string(a_so_far, 8)
  // io.println("0o" <> a_str)
  // let st = State(a_so_far, 0, 0, 0, array.new())
  // io.println(out_to_str(run(prog, st)))

  let num_octets = array.length(prog)

  case octets_found == num_octets {
    True  -> Ok(a_so_far) //Done
    False -> {
      let assert Ok(goal_out) = array.get(prog, num_octets - 1 - octets_found)
      list.range(0o0,0o7)                                       //new octets
      |> list.map(fn(i) { shift_left_by_octet(a_so_far) + i })  //all new a's
      |> list.filter(fn(a) {                                    //a's that work
        let out = run(prog, State(a, 0, 0, 0, array.new()))
        let assert Ok(out_new) = array.get(out, 0)
        out_new == goal_out
      })
      |> list.fold_until(Error(Nil), fn(_acc, new_a) {          //DFS each a
        case find_a(prog, new_a, octets_found + 1) {
          Error(_) -> Continue(Error(Nil))  //no go, keep looking
          Ok(a)    -> Stop(Ok(a))           //winner, look no further
        }
      })
    }
  }
}

pub fn part1()
{
  let input = parse()
  //io.debug(input)

  let out = run(input.1, input.0)
  
  io.println(out_to_str(out))
}

pub fn part2()
{
  let input = parse()
  let prog = input.1
  // let a = run_bf(prog, 0)
  // io.debug(a)

  let assert Ok(ans) = find_a(prog, 0, 0)
  io.debug(ans)
}
