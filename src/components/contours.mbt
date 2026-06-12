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

fn sort_points(points : Array[Point]) -> Unit {
  for i = 1; i < points.length(); i = i + 1 {
    let next = points[i]
    let mut j = i - 1
    while j >= 0 &&
      (points[j].y > next.y || (points[j].y == next.y && points[j].x > next.x)) {
      points[j + 1] = points[j]
      j = j - 1
    }
    points[j + 1] = next
  }
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
  let boundary_points = []
  let mut min_x = start_x
  let mut min_y = start_y
  let mut max_x = start_x
  let mut max_y = start_y
  let mut area = 0
  let mut perimeter = 0

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

    let mut is_boundary = false
    let orthogonal = contour_neighbors(4)
    // Debug note: perimeter is accumulated from exposed 4-neighbor sides so the
    // contour stats remain stable even though boundary points are stored as pixels.
    for delta in orthogonal {
      let nx = x + delta.x
      let ny = y + delta.y
      if !contour_in_bounds(img, nx, ny) {
        perimeter = perimeter + 1
        is_boundary = true
      } else if !contour_foreground(img, nx, ny) {
        perimeter = perimeter + 1
        is_boundary = true
      }
    }

    if !is_boundary {
      for delta in contour_neighbors(8) {
        let nx = x + delta.x
        let ny = y + delta.y
        if !contour_in_bounds(img, nx, ny) {
          is_boundary = true
        } else if !contour_foreground(img, nx, ny) {
          is_boundary = true
        }
      }
    }

    if is_boundary {
      boundary_points.push({ x, y })
    }

    // Debug note: traversal connectivity is configurable, but contour points are
    // still recorded from the discovered binary component in deterministic scan order.
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

  sort_points(boundary_points)
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
