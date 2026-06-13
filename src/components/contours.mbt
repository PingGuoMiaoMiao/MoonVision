struct Point {
  x : Int
  y : Int
} derive(Eq, Show)

struct Contour {
  points : Array[Point]
  area : Int
  perimeter : Int
  bbox : BoundingBox
} derive(Eq, Show)

fn contour_directions() -> Array[Point] {
  [
    { x: 0, y: -1 },
    { x: 1, y: -1 },
    { x: 1, y: 0 },
    { x: 1, y: 1 },
    { x: 0, y: 1 },
    { x: -1, y: 1 },
    { x: -1, y: 0 },
    { x: -1, y: -1 },
  ]
}

fn validate_connectivity(connectivity : Int) -> Unit raise @image.ImageError {
  if connectivity != 4 && connectivity != 8 {
    raise @image.InvalidDimensions("contour connectivity must be either 4 or 8")
  }
}

fn contour_index(width : Int, x : Int, y : Int) -> Int {
  y * width + x
}

fn contour_in_bounds(img : @image.GrayImage, x : Int, y : Int) -> Bool {
  x >= 0 && y >= 0 && x < img.width() && y < img.height()
}

fn contour_foreground(
  img : @image.GrayImage,
  x : Int,
  y : Int,
) -> Bool raise @image.ImageError {
  img.get(x, y) != b'\x00'
}

fn contour_mask_foreground(mask : Array[Bool], width : Int, x : Int, y : Int) -> Bool {
  mask[contour_index(width, x, y)]
}

fn component_boundary_pixel(
  component_mask : Array[Bool],
  width : Int,
  height : Int,
  x : Int,
  y : Int,
) -> Bool {
  let orthogonal = [
    { x: 0, y: -1 },
    { x: 1, y: 0 },
    { x: 0, y: 1 },
    { x: -1, y: 0 },
  ]
  for delta in orthogonal {
    let nx = x + delta.x
    let ny = y + delta.y
    if nx < 0 || ny < 0 || nx >= width || ny >= height {
      return true
    }
    if !contour_mask_foreground(component_mask, width, nx, ny) {
      return true
    }
  }
  false
}

fn contour_neighbors(connectivity : Int) -> Array[Point] {
  if connectivity == 4 {
    [{ x: 0, y: -1 }, { x: -1, y: 0 }, { x: 1, y: 0 }, { x: 0, y: 1 }]
  } else {
    [
      { x: -1, y: -1 },
      { x: 0, y: -1 },
      { x: 1, y: -1 },
      { x: -1, y: 0 },
      { x: 1, y: 0 },
      { x: -1, y: 1 },
      { x: 0, y: 1 },
      { x: 1, y: 1 },
    ]
  }
}

fn next_boundary_direction(
  boundary_mask : Array[Bool],
  width : Int,
  height : Int,
  current : Point,
  previous : Point?,
  start : Point,
  incoming_direction : Int,
) -> Int {
  let directions = contour_directions()
  for offset = 1; offset <= directions.length(); offset = offset + 1 {
    let direction = (incoming_direction + offset) % directions.length()
    let delta = directions[direction]
    let nx = current.x + delta.x
    let ny = current.y + delta.y
    if nx < 0 || ny < 0 || nx >= width || ny >= height {
      continue
    }
    if contour_mask_foreground(boundary_mask, width, nx, ny) {
      if nx == start.x && ny == start.y {
        return direction
      }
      match previous {
        Some(prev) => {
          if nx != prev.x || ny != prev.y {
            return direction
          }
        }
        None => return direction
      }
    }
  }
  -1
}

fn trace_boundary_points(
  boundary_mask : Array[Bool],
  width : Int,
  height : Int,
  start : Point,
  step_budget : Int,
) -> Array[Point] {
  let directions = contour_directions()
  let points = [start]
  let mut current = start
  let mut previous : Point? = None
  let mut incoming_direction = 6
  let mut steps = 0

  // Debug note: contour points are traced in boundary-walk order instead of
  // scan order so downstream consumers receive an actual ordered contour path.
  while steps < step_budget {
    let direction = next_boundary_direction(
      boundary_mask,
      width,
      height,
      current,
      previous,
      start,
      incoming_direction,
    )
    if direction == -1 {
      break
    }

    let delta = directions[direction]
    let next = { x: current.x + delta.x, y: current.y + delta.y }
    if next.x == start.x && next.y == start.y && points.length() > 1 {
      break
    }

    points.push(next)
    previous = Some(current)
    current = next
    incoming_direction = (direction + 4) % directions.length()
    steps = steps + 1
  }
  points
}

fn flood_contour(
  img : @image.GrayImage,
  visited : Array[Bool],
  start_x : Int,
  start_y : Int,
  connectivity : Int,
) -> Contour raise @image.ImageError {
  let stack_xs = [start_x]
  let stack_ys = [start_y]
  visited[contour_index(img.width(), start_x, start_y)] = true

  let traversal_neighbors = contour_neighbors(connectivity)
  let component_xs = []
  let component_ys = []
  let component_mask = Array::make(img.pixel_count(), false)
  let mut min_x = start_x
  let mut min_y = start_y
  let mut max_x = start_x
  let mut max_y = start_y
  let mut area = 0

  while stack_xs.length() > 0 {
    let last = stack_xs.length() - 1
    let x = stack_xs[last]
    let y = stack_ys[last]
    ignore(stack_xs.pop())
    ignore(stack_ys.pop())

    area = area + 1
    if x < min_x {
      min_x = x
    }
    if y < min_y {
      min_y = y
    }
    if x > max_x {
      max_x = x
    }
    if y > max_y {
      max_y = y
    }

    component_xs.push(x)
    component_ys.push(y)
    component_mask[contour_index(img.width(), x, y)] = true

    // Debug note: connectivity still controls component grouping, but the traced
    // contour is now derived from boundary pixels of the grouped region.
    for delta in traversal_neighbors {
      let nx = x + delta.x
      let ny = y + delta.y
      if !contour_in_bounds(img, nx, ny) {
        continue
      }
      if !contour_foreground(img, nx, ny) {
        continue
      }
      let idx = contour_index(img.width(), nx, ny)
      if !visited[idx] {
        visited[idx] = true
        stack_xs.push(nx)
        stack_ys.push(ny)
      }
    }
  }

  let boundary_mask = Array::make(img.pixel_count(), false)
  let mut perimeter = 0
  for i = 0; i < component_xs.length(); i = i + 1 {
    let x = component_xs[i]
    let y = component_ys[i]
    if component_boundary_pixel(component_mask, img.width(), img.height(), x, y) {
      boundary_mask[contour_index(img.width(), x, y)] = true
    }
    for delta in [
      { x: 0, y: -1 },
      { x: 1, y: 0 },
      { x: 0, y: 1 },
      { x: -1, y: 0 },
    ] {
      let nx = x + delta.x
      let ny = y + delta.y
      if !contour_in_bounds(img, nx, ny) {
        perimeter = perimeter + 1
      } else if !contour_mask_foreground(component_mask, img.width(), nx, ny) {
        perimeter = perimeter + 1
      }
    }
  }

  let boundary_points = trace_boundary_points(
    boundary_mask,
    img.width(),
    img.height(),
    { x: start_x, y: start_y },
    perimeter + area * 8 + 8,
  )
  {
    points: boundary_points,
    area,
    perimeter,
    bbox: {
      x: min_x,
      y: min_y,
      width: max_x - min_x + 1,
      height: max_y - min_y + 1,
    },
  }
}

///|
pub fn find_contours(
  img : @image.GrayImage,
  connectivity? : Int = 8,
) -> Array[Contour] raise @image.ImageError {
  validate_connectivity(connectivity)
  let visited = Array::make(img.pixel_count(), false)
  let contours = []
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      if !contour_foreground(img, x, y) {
        continue
      }
      let idx = contour_index(img.width(), x, y)
      if visited[idx] {
        continue
      }
      contours.push(flood_contour(img, visited, x, y, connectivity))
    }
  }
  contours
}

///|
pub fn contour_area(contour : Contour) -> Int {
  contour.area
}

///|
pub fn contour_perimeter(contour : Contour) -> Int {
  contour.perimeter
}

///|
pub fn contour_bbox(contour : Contour) -> BoundingBox {
  contour.bbox
}

///|
pub fn Contour::points(self : Contour) -> Array[Point] {
  self.points
}

///|
pub fn Point::x(self : Point) -> Int {
  self.x
}

///|
pub fn Point::y(self : Point) -> Int {
  self.y
}
