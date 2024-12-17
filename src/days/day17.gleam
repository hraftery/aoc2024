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
type Registers {
  Registers(a: Int, b: Int, c: Int, pc: Int)
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
  #(Registers(a, b, c, 0), array.from_list(p))
}

fn run(prog: Program, reg: Registers)
{
  case step(prog, reg) {
    Error(_) -> Nil
    Ok(reg)  -> run(prog, reg)
  }
}

fn step(prog: Program, reg: Registers) -> Result(Registers, Nil)
{
  case array.get(prog, reg.pc) {
    Error(_)   -> Error(Nil) //halt
    Ok(opcode) -> {
      let assert Ok(operand) = array.get(prog, reg.pc + 1)
      let op_mod_8 = combo(reg, operand) % 8
      let reg = case from_int(opcode) {
        ADV -> Registers(..reg, a:int.bitwise_shift_right(reg.a, combo(reg, operand)))
        BXL -> Registers(..reg, b:int.bitwise_exclusive_or(reg.b, operand))
        BST -> Registers(..reg, b:op_mod_8)
        JNZ if reg.a == 0 -> reg
        JNZ -> Registers(..reg, pc:operand - 2)
        BXC -> Registers(..reg, b:int.bitwise_exclusive_or(reg.b, reg.c))
        OUT -> { io.print(int.to_string(op_mod_8) <> ",") reg }
        BDV -> Registers(..reg, b:int.bitwise_shift_right(reg.a, combo(reg, operand)))
        CDV -> Registers(..reg, c:int.bitwise_shift_right(reg.a, combo(reg, operand)))
      }
      Ok(Registers(..reg, pc:reg.pc + 2))
    }
  }
}

fn combo(reg: Registers, operand: Int) -> Int
{
  case operand {
    0 -> 0
    1 -> 1
    2 -> 2
    3 -> 3
    4 -> reg.a
    5 -> reg.b
    6 -> reg.c
    _ -> panic as "invalid operand"
  }
}

pub fn part1()
{
  let input = parse()
  //io.debug(input)
  run(input.1, input.0)
  io.println("")
}

pub fn part2()
{
  io.println("Day " <> day <> ", part 2.")
}
