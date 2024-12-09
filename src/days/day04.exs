defmodule Day04 do
  #@type letter :: :X | :M | :A | :S
  @type char_matrix :: %{{integer,integer} => char}
  @type direction :: :N | :NE | :E | :SE | :S | :SW | :W | :NW

  @spec from_string_list([String.t()]) :: char_matrix
  def from_string_list(lines) do
    lines
    |> Enum.with_index()
    |> Enum.flat_map(fn {line, y} ->
        String.graphemes(line)
        |> Enum.with_index()
        |> Enum.map(fn {c, x} -> {{x,y}, c} end)
      end)
    |> Map.new
  end
  
  @spec get_string(char_matrix, integer, integer, integer, direction) :: String.t()
  def get_string(m, x, y, len, dir) do
    mod = len - 1 #modulus excludes starting point
    pts = for i <- 0..mod do
      case dir do
        :N  -> { x    , y - i}
        :NE -> { x + i, y - i}
        :E  -> { x + i, y    }
        :SE -> { x + i, y + i}
        :S  -> { x    , y + i}
        :SW -> { x - i, y + i}
        :W  -> { x - i, y    }
        :NW -> { x - i, y - i}
      end
    end
    char_list = for pt <- pts, do: m[pt]
    if nil in char_list do
      raise ArgumentError, message: "out of bounds"
    end
    List.to_string(char_list)
  end
end

#IO.inspect Day04.from_string_list(["XMAS", "SXMA", "ASXM", "MASX"])
IO.inspect Day04.get_string(Day04.from_string_list(["XMAS", "SXMA", "ASXM", "MASX"]),
                            0, 0, 4, :SE)
