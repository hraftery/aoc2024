import gleam/io
import gleam/string
import gleam/int
import gleam/list
import gleam/result
import simplifile as file
import glearray.{type Array} as array


const day = "17"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"

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

pub fn part1()
{
  let input = parse()
  //io.debug(input)

  let out_str = run(input.1, input.0)
  |> array.to_list
  |> list.map(int.to_string)
  |> list.intersperse(",")
  |> string.concat

  io.println(out_str)
}

pub fn part2()
{
  io.println("Day " <> day <> ", part 2.")
}
