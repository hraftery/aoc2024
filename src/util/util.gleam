import gleam/int
import gleam/list
import gleam/string

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
