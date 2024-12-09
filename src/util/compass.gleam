pub type Direction {
  N
  NE
  E
  SE
  S
  SW
  W
  NW
}

//Oh how I miss integer enums. The next ~100 lines is just hand made
//functionality normally implicitly provided by integer enums.
pub fn list_clockwise() -> List(Direction)
{
  [N, NE, E, SE, S, SW, W, NW]
}

pub fn list_anticlockwise() -> List(Direction)
{
  [N, NW, W, SW, S, SE, E, NE]
}

pub fn to_degrees(dir: Direction) -> Int
{
  case dir {
    N  -> 0
    NE -> 45
    E  -> 90
    SE -> 135
    S  -> 180
    SW -> 225
    W  -> 270
    NW -> 315
  }
}

pub fn from_degrees(deg: Int) -> Direction
{
  case deg % 360 {
    0   -> N
    45  -> NE
    90  -> E
    135 -> SE
    180 -> S
    225 -> SW
    270 -> W
    315 -> NW
    _   -> panic
  }
}

pub fn turn_clockwise(dir: Direction) -> Direction
{
  case dir {
    N  -> NE
    NE -> E
    E  -> SW
    SE -> S
    S  -> SW
    SW -> W
    W  -> NW
    NW -> N
  }
}

pub fn turn_anticlockwise(dir: Direction) -> Direction
{
  case dir {
    N  -> NW
    NE -> N
    E  -> NE
    SE -> E
    S  -> SE
    SW -> S
    W  -> SW
    NW -> W
  }
}

pub fn turn_right_90(dir: Direction) -> Direction
{
  from_degrees(to_degrees(dir) + 90)
}

pub fn turn_left_90(dir: Direction) -> Direction
{
  from_degrees(to_degrees(dir) - 90)
}

pub fn opposite(dir: Direction) -> Direction
{
  case dir {
    N  -> S
    NE -> SW
    E  -> W
    SE -> NW
    S  -> N
    SW -> NE
    W  -> E
    NW -> SE
  }
}
