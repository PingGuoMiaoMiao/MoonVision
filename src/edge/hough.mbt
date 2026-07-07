///|
struct HoughLine {
  rho : Int
  theta_bucket : Int
  votes : Int
} derive(Eq)

///|
fn hough_line(rho : Int, theta_bucket : Int, votes : Int) -> HoughLine {
  { rho, theta_bucket, votes }
}

///|
fn hough_better(left : HoughLine, right : HoughLine) -> Bool {
  left.votes > right.votes ||
  (left.votes == right.votes && left.theta_bucket < right.theta_bucket) ||
  (
    left.votes == right.votes &&
    left.theta_bucket == right.theta_bucket &&
    left.rho < right.rho
  )
}

///|
fn push_sorted_hough_line(lines : Array[HoughLine], line : HoughLine) -> Unit {
  lines.push(line)
  let mut i = lines.length() - 1
  while i > 0 && hough_better(lines[i], lines[i - 1]) {
    let tmp = lines[i - 1]
    lines[i - 1] = lines[i]
    lines[i] = tmp
    i = i - 1
  }
}

///|
fn add_hough_bucket(
  lines : Array[HoughLine],
  accumulator : Array[Int],
  theta_bucket : Int,
  rho_offset : Int,
  vote_threshold : Int,
) -> Unit {
  for i = 0; i < accumulator.length(); i = i + 1 {
    let votes = accumulator[i]
    if votes >= vote_threshold {
      push_sorted_hough_line(
        lines,
        hough_line(i - rho_offset, theta_bucket, votes),
      )
    }
  }
}

///|
pub fn hough_lines(
  edges : @image.GrayImage,
  vote_threshold? : Int = 1,
  max_lines? : Int = 16,
) -> Array[HoughLine] raise @image.ImageError {
  if vote_threshold < 0 {
    raise @image.InvalidDimensions("hough vote_threshold must not be negative")
  }
  if max_lines < 0 {
    raise @image.InvalidDimensions("hough max_lines must not be negative")
  }
  if max_lines == 0 {
    return []
  }
  let width = edges.width()
  let height = edges.height()
  let vertical = Array::make(width, 0)
  let horizontal = Array::make(height, 0)
  let diag_down = Array::make(width + height - 1, 0)
  let diag_up = Array::make(width + height - 1, 0)
  let diag_up_offset = height - 1
  for y = 0; y < height; y = y + 1 {
    for x = 0; x < width; x = x + 1 {
      if edges.get(x, y) == b'\x00' {
        continue
      }
      vertical[x] = vertical[x] + 1
      horizontal[y] = horizontal[y] + 1
      diag_down[x + y] = diag_down[x + y] + 1
      diag_up[x - y + diag_up_offset] = diag_up[x - y + diag_up_offset] + 1
    }
  }
  let lines = []
  add_hough_bucket(lines, vertical, 0, 0, vote_threshold)
  add_hough_bucket(lines, diag_down, 45, 0, vote_threshold)
  add_hough_bucket(lines, horizontal, 90, 0, vote_threshold)
  add_hough_bucket(lines, diag_up, 135, diag_up_offset, vote_threshold)
  if lines.length() <= max_lines {
    return lines
  }
  let out = []
  for i = 0; i < max_lines; i = i + 1 {
    out.push(lines[i])
  }
  out
}

///|
pub fn HoughLine::rho(self : HoughLine) -> Int {
  self.rho
}

///|
pub fn HoughLine::theta_bucket(self : HoughLine) -> Int {
  self.theta_bucket
}

///|
pub fn HoughLine::votes(self : HoughLine) -> Int {
  self.votes
}
