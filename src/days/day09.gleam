import util/util
import gleam/result
import gleam/int
import gleam/list.{Continue, Stop}
import gleam/io
import gleam/string
//import gleam/int
//import gleam/list
import simplifile as file
import gleam/deque.{type Deque}


const day = "09"
const input_file = "input/" <> day <> ".txt"
//const input_file = "input/" <> day <> "_example.txt"


fn parse()
{
  let assert Ok(raw_input) = file.read(input_file)
  raw_input
  |> string.trim
  |> string.to_graphemes
  |> list.map(int.parse)
  |> result.values
}

fn make_blocks(input: List(Int)) -> Deque(Int)
{
  input
  |> list.sized_chunk(2)
  |> list.index_map(fn(x, i) {
      let assert Ok(repeat_count) = list.first(x)
      list.repeat(i, repeat_count)
    })
  |> list.flatten
  |> deque.from_list
}

pub type Entry {
  Entry(file_id: Int, length: Int, spaces: Int)
}

fn make_entries(input: List(Int)) -> List(Entry)
{
  input
  |> list.sized_chunk(2)
  |> list.index_map(fn(x, i) {
      let #(file_length, space_length) = case x {
        [a]    -> #(a, 0)
        [a, b] -> #(a, b)
        _      -> panic as "sized_chunk(2) produced something other than 1 or 2"
      }
      Entry(i, file_length, space_length)
    })
}

fn do_move_files(entries: List(Entry), file_id: Int)
{
  //io.println(to_string(entries))
  io.debug(file_id)
  case file_id == 0 {
    True  -> entries // done
    False -> {
      let #(pre_src_entries, from_src_entries) = list.split_while(entries, fn(x) { x.file_id != file_id })
      let assert Ok(#(_init_src_entries, before_src_entry)) = util.init_last(pre_src_entries)
      let assert Ok(#(the_src_entry, rest_src_entries))     = util.first_rest(from_src_entries)
      
      let entries_ = case list.split_while(pre_src_entries, fn(x) { x.spaces < the_src_entry.length} ) {
        #(_, [])                             -> entries // no space for the_src_entry, so move on
        #(pre_dst_entries, [the_dst_entry])  -> { //special case - the dst is the src, just shuffled over
          let the_dst_entry_    = Entry(..the_dst_entry,    spaces: 0)
          let the_src_entry_    = Entry(..the_src_entry,    spaces: the_dst_entry.spaces +
                                                                    the_src_entry.spaces)
          
          list.flatten([pre_dst_entries,
                       [the_dst_entry_, the_src_entry_, ..rest_src_entries]])
        }
        #(pre_dst_entries, from_dst_entries) -> { //normal case
          let assert Ok(#(the_dst_entry, dst_to_src_entries)) = util.first_rest(from_dst_entries)
          let dst_to_before_src_entries = case util.init_last(dst_to_src_entries) {
            Ok(#(dst_to_before_src_entries, _)) -> dst_to_before_src_entries
            Error(_)                            -> [] //TODO what does this scenario actually mean?
          }
          
          
          let the_dst_entry_    = Entry(..the_dst_entry,    spaces: 0)
          let the_src_entry_    = Entry(..the_src_entry,    spaces: the_dst_entry.spaces -
                                                                    the_src_entry.length)
          let before_src_entry_ = Entry(..before_src_entry, spaces: before_src_entry.spaces +
                                                                    the_src_entry.length +
                                                                    the_src_entry.spaces)
          
          list.flatten([pre_dst_entries,
                       [the_dst_entry_, the_src_entry_, ..dst_to_before_src_entries],
                       [before_src_entry_, ..rest_src_entries]])
        }
      }
      do_move_files(entries_, file_id - 1)
    }
  }
}

// fn to_string(entries: List(Entry))
// {
//   list.fold(entries, "", fn(acc, entry) {
//     acc <> string.repeat(int.to_string(entry.file_id), entry.length)
//         <> string.repeat(".", entry.spaces)
//   })
// }

pub fn part1()
{
  let input = parse()
  let orig_blocks = make_blocks(input)

  let ans = list.fold_until(input, #(0, 0, False, orig_blocks), fn(outer_acc, length) {
    let inner_acc = case length > 0 {
      False -> outer_acc
      True  -> list.fold_until(list.range(1, length), outer_acc, fn(acc, _i) {
        let #(tot, idx, is_space, blocks) = acc
        //io.debug(acc)//#(tot, idx, is_space, deque.length(blocks)))
        let pop_result = case is_space {
          False -> deque.pop_front(blocks)
          True  -> deque.pop_back(blocks)
        }
        case pop_result {
          Ok(#(block, new_blocks)) -> Continue(#(tot + idx * block, idx + 1, is_space, new_blocks))
          Error(Nil)               -> Stop(#(tot, idx, is_space, blocks))
        }
      })
    }
    case deque.is_empty(inner_acc.3) {
      False -> Continue(#(inner_acc.0, inner_acc.1, !inner_acc.2, inner_acc.3))
      True  -> Stop(#(inner_acc.0, inner_acc.1, !inner_acc.2, inner_acc.3))
    }
  })

  io.debug(ans.0)
  //io.debug(list.take(deque.to_list(orig_blocks), 20))
}

pub fn part2()
{
  let input = parse()
  let entries = make_entries(input)
  let max_file_id = list.length(entries) - 1 // why do I need to calculate this again?

  let ans = list.fold(do_move_files(entries, max_file_id), #(0, 0), fn(acc, entry) {
    //io.debug(acc)
    let #(tot, idx) = acc
    #(tot + entry.file_id * int.sum(list.range(idx, idx + entry.length - 1)),
      idx + entry.length + entry.spaces)
  })

  io.debug(ans.0)
}
