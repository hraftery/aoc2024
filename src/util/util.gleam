import gleam/int
import gleam/list
import gleam/option.{Some, None}
import gleam/string
import gleam/dict.{type Dict}

//Seems a significant oversight from the standard library?
pub fn id(x : a) -> a
{
  x
}
pub fn id2(x : a, y : b) -> #(a, b)
{
  #(x,y)
}

//For brevity
pub fn abs(i : Int) -> Int
{
  int.absolute_value(i)
}

pub fn drop_elem(from list: List(a), at_index n: Int) -> List(a)
{
  list.flatten([list.take(list, n),
                list.drop(list, n + 1)])
}

//Like string.crop except substring is not included in the return string.
//And if substring cannot be found the empty string is returned.
pub fn crop_until(from string: String, until substring: String) -> String
{
  case string.split_once(string, substring)
  {
    Ok(#(_before, after)) -> after
    Error(Nil) -> ""
  }
}

//Like list.split_while except it splits a list in two before the first
//element that a given function returns True for.
pub fn split_until(list list: List(a), satisfying predicate: fn(a) -> Bool) -> #(List(a), List(a))
{
  list.split_while(list, fn(a) { ! predicate(a) })
}

pub fn invert(the_dict: Dict(a,b)) -> Dict(b,List(a))
{
  dict.fold(the_dict, dict.new(), fn(acc, k, v) {
    dict.upsert(acc, v, fn(x) { case x {
      Some(i) -> [k, ..i]
      None    -> [k]
    }})})
}

pub fn first_rest(the_list: List(a)) -> Result(#(a, List(a)), Nil)
{
  case the_list {
    [first]         -> Ok(#(first, []))
    [first, ..rest] -> Ok(#(first, rest))
    _               -> Error(Nil)
  }
}

pub fn init_last(the_list: List(a)) -> Result(#(List(a), a), Nil)
{
  case first_rest(the_list) {
    Error(_)           -> Error(Nil)
    Ok(#(first, rest)) -> Ok(
      list.fold(rest, #([], first), fn(acc, x) {
        #(list.append(acc.0, [acc.1]), x) // holy expensive Batman
      }))
  }
}

//Like list.split_while except it splits a list in two *after* the first
//element that a given function returns False for.
pub fn split_after(list list: List(a), satisfying predicate: fn(a) -> Bool) -> #(List(a), List(a))
{
  split_after_loop(list, predicate, [])
}

fn split_after_loop(list: List(a), f: fn(a) -> Bool, acc: List(a)) -> #(List(a), List(a))
{
  case list {
    []              -> #(list.reverse(acc), [])
    [first, ..rest] -> case f(first) {
        False -> #(list.reverse([first, ..acc]), rest)
        _     -> split_after_loop(rest, f, [first, ..acc])
      }
  }
}
