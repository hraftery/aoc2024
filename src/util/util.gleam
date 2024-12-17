import gleam/int
import gleam/list
import gleam/option.{Some, None}
import gleam/string
import gleam/dict.{type Dict}
import gleam/regexp.{type Match}


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

//Opposite of list.contains
pub fn missing(list: List(a), elem: a) -> Bool
{
  !list.contains(list, elem)
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

pub fn list_split_at(list list: List(a), at n: Int) -> List(List(a))
{
  [list.take(list, n), list.drop(list, n)]
}

pub fn string_split_at(str str: String, at n: Int) -> List(String)
{
  [string.drop_end(str, n), string.drop_start(str, n)]
}

pub type DateTime
// An external function that creates an instance of the type
@external(erlang, "os", "timestamp")
pub fn now() -> DateTime

pub fn extract_and_flatten_matches(matches: List(Match)) -> List(String)
{
  list.flat_map(matches, fn(match) {
    list.map(match.submatches, fn(submatch) {
      case submatch {
        Some(x) -> x
        None    -> ""
      }
    })
  })
}

pub type TwoByTwoSolution {
  UniqueTwoByTwoSolution(#(Float,Float))    // 1 solution:  #(x, y) where the solution is x=x, y=y
  InfiniteTwoByTwoSolutions(#(Float,Float)) // ∞ solutions: #(a, b) where solutions are x=t, y=a+bt for any t
  NoTwoByTwoSolution                        // 0 solutions
}

// Solve two simultaneous equations in two unknowns, where:
//   a1*x + b1*y = c1 (equation 1)
//   a2*x + b2*y = c2 (equation 2)
// All coefficients need to be non-zero!
// For example:
//   solve_two_by_two_equations(3., 2., 36., 5., 4., 64.)) == UniqueTwoByTwoSolution(#(8.0, 6.0))
//   solve_two_by_two_equations(1., 3., 5., 2., 6., 7.))   == NoTwoByTwoSolution
//   solve_two_by_two_equations(1., 2., 10., 2., 4., 20.)) == InfiniteTwoByTwoSolutions(#(5.0, -0.5))
pub fn solve_two_by_two_equations(a1: Float, b1: Float, c1: Float,
                                  a2: Float, b2: Float, c2: Float) -> TwoByTwoSolution
{
  //Possible floating point imprecision here. But acceptable tolerance only depends on
  //floating point precision of the x calculation below, which I'm not sure of.
  let parallel   = a1/.a2 == b1/.b2
  let coincident = parallel && b1/.b2 == c1/.c2

  case parallel, coincident {
    False, _      -> {
      // (1) * b2  => a1*x*b2 + b1*y*b2 = c1*b2  ... (3)
      // (2) * b1  => a2*x*b1 + b2*y*b1 = c2*b1  ... (4)
      // (3) - (4) => a1*x*b2 - a2*x*b1 = c1*b2 - c2*b1
      //           => x*(a1*b2 - a2*b1) = c1*b2 - c2*b1
      //           => x = (c1*b2 - c2*b1) / (a1*b2 - a2*b1)
      let x = {c1*.b2 -. c2*.b1} /. {a1*.b2 -. a2*.b1}
      // (1)       => b1*y = c1 - a1*x
      //           =>    y = (c1 - a1*x) / b1
      UniqueTwoByTwoSolution(#(x, {c1 -. a1*.x} /. b1))
    }
    True,  False  -> {
      NoTwoByTwoSolution
    }
    True,  True   -> {
      // (1),x=t  => y = (c1 - a1*t) / b1
      //           = c1/b1 + (-a1/b1)*t
      InfiniteTwoByTwoSolutions(#(c1/.b1, -1.*.a1/.b1))
    }
  }
}

pub fn positive_modulo(i: Int, n: Int) -> Int
{
  {i % n + n} % n
}
