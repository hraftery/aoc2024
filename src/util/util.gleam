import gleam/list

pub fn drop_elem(from list: List(a), at_index n: Int) -> List(a)
{
  list.flatten([list.take(list, n),
                list.drop(list, n + 1)])
}
