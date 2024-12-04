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

pub fn list_clockwise() -> List(Direction)
{
  [N, NE, E, SE, S, SW, W, NW]
}

pub fn list_anticlockwise() -> List(Direction)
{
  [N, NW, W, SW, S, SE, E, NE]
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
