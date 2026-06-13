///|
pub enum ContourKind {
  Outer
  Hole
} derive(Eq, Show)

struct Point {
  x : Int
  y : Int
} derive(Eq, Show)

struct Contour {
  points : Array[Point]
  area : Int
  perimeter : Int
  bbox : BoundingBox
  kind : ContourKind
  parent_index : Int?
} derive(Eq, Show)

priv struct RegionData {
  mask : Array[Bool]
  seed : Point
  area : Int
  bbox : BoundingBox
}

priv struct LocalRegionData {
  mask : Array[Bool]
  seed : Point
  area : Int
  bbox : BoundingBox
}

priv struct ContourDraft {
  points : Array[Point]
  area : Int
  perimeter : Int
  bbox : BoundingBox
  kind : ContourKind
  seed : Point
}

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

fn orthogonal_directions() -> Array[Point] {
  [
    { x: 0, y: -1 },
    { x: 1, y: 0 },
    { x: 0, y: 1 },
    { x: -1, y: 0 },
  ]
}

fn validate_connectivity(connectivity : Int) -> Unit raise @image.ImageError {
  if connectivity != 4 && connectivity != 8 {
    raise @image.InvalidDimensions("contour connectivity must be either 4 or 8")
  }
}

fn dual_connectivity(connectivity : Int) -> Int {
  if connectivity == 4 {
    8
  } else {
    4
  }
}

fn contour_index(width : Int, x : Int, y : Int) -> Int {
  y * width + x
}

fn contour_in_bounds(img : @image.GrayImage, x : Int, y : Int) -> Bool {
  x >= 0 && y >= 0 && x < img.width() && y < img.height()
}

fn bbox_contains_point(bbox : BoundingBox, point : Point) -> Bool {
  point.x >= bbox.x &&
  point.y >= bbox.y &&
  point.x < bbox.x + bbox.width &&
  point.y < bbox.y + bbox.height
}

fn bbox_area(bbox : BoundingBox) -> Int {
  bbox.width * bbox.height
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

  // Debug note: contour points remain deterministic scan-origin walks, but
  // `v1.3` now traces one boundary at a time so hierarchy can be reconstructed.
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

fn first_true(mask : Array[Bool], width : Int, height : Int) -> Point? {
  for y = 0; y < height; y = y + 1 {
    for x = 0; x < width; x = x + 1 {
      if contour_mask_foreground(mask, width, x, y) {
        return Some({ x, y })
      }
    }
  }
  None
}

fn build_contour_draft(
  boundary_mask : Array[Bool],
  width : Int,
  height : Int,
  area : Int,
  perimeter : Int,
  bbox : BoundingBox,
  kind : ContourKind,
  seed : Point,
) -> ContourDraft {
  let points = match first_true(boundary_mask, width, height) {
    Some(start) => trace_boundary_points(boundary_mask, width, height, start, perimeter + area * 8 + 8)
    None => [seed]
  }
  { points, area, perimeter, bbox, kind, seed }
}

fn collect_foreground_region(
  img : @image.GrayImage,
  visited : Array[Bool],
  start_x : Int,
  start_y : Int,
  connectivity : Int,
) -> RegionData raise @image.ImageError {
  let stack_xs = [start_x]
  let stack_ys = [start_y]
  let region_mask = Array::make(img.pixel_count(), false)
  visited[contour_index(img.width(), start_x, start_y)] = true
  region_mask[contour_index(img.width(), start_x, start_y)] = true

  let traversal_neighbors = contour_neighbors(connectivity)
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
        region_mask[idx] = true
        stack_xs.push(nx)
        stack_ys.push(ny)
      }
    }
  }

  {
    mask: region_mask,
    seed: { x: start_x, y: start_y },
    area,
    bbox: {
      x: min_x,
      y: min_y,
      width: max_x - min_x + 1,
      height: max_y - min_y + 1,
    },
  }
}

fn local_component_mask(
  region : RegionData,
  image_width : Int,
) -> Array[Bool] {
  let local_mask = Array::make(region.bbox.width * region.bbox.height, false)
  for y = 0; y < region.bbox.height; y = y + 1 {
    for x = 0; x < region.bbox.width; x = x + 1 {
      let gx = region.bbox.x + x
      let gy = region.bbox.y + y
      local_mask[contour_index(region.bbox.width, x, y)] = contour_mask_foreground(
        region.mask,
        image_width,
        gx,
        gy,
      )
    }
  }
  local_mask
}

fn flood_local_background_region(
  blocked_mask : Array[Bool],
  visited : Array[Bool],
  width : Int,
  height : Int,
  start_x : Int,
  start_y : Int,
  connectivity : Int,
) -> LocalRegionData {
  let stack_xs = [start_x]
  let stack_ys = [start_y]
  let region_mask = Array::make(width * height, false)
  visited[contour_index(width, start_x, start_y)] = true
  region_mask[contour_index(width, start_x, start_y)] = true

  let neighbors = contour_neighbors(connectivity)
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

    for delta in neighbors {
      let nx = x + delta.x
      let ny = y + delta.y
      if nx < 0 || ny < 0 || nx >= width || ny >= height {
        continue
      }
      let idx = contour_index(width, nx, ny)
      if blocked_mask[idx] || visited[idx] {
        continue
      }
      visited[idx] = true
      region_mask[idx] = true
      stack_xs.push(nx)
      stack_ys.push(ny)
    }
  }

  {
    mask: region_mask,
    seed: { x: start_x, y: start_y },
    area,
    bbox: {
      x: min_x,
      y: min_y,
      width: max_x - min_x + 1,
      height: max_y - min_y + 1,
    },
  }
}

fn mark_external_background(
  local_mask : Array[Bool],
  width : Int,
  height : Int,
  connectivity : Int,
) -> Array[Bool] {
  let visited = Array::make(width * height, false)
  for x = 0; x < width; x = x + 1 {
    if !local_mask[contour_index(width, x, 0)] && !visited[contour_index(width, x, 0)] {
      ignore(flood_local_background_region(local_mask, visited, width, height, x, 0, connectivity))
    }
    let bottom = height - 1
    if !local_mask[contour_index(width, x, bottom)] &&
      !visited[contour_index(width, x, bottom)] {
      ignore(
        flood_local_background_region(
          local_mask,
          visited,
          width,
          height,
          x,
          bottom,
          connectivity,
        ),
      )
    }
  }
  for y = 0; y < height; y = y + 1 {
    if !local_mask[contour_index(width, 0, y)] && !visited[contour_index(width, 0, y)] {
      ignore(flood_local_background_region(local_mask, visited, width, height, 0, y, connectivity))
    }
    let right = width - 1
    if !local_mask[contour_index(width, right, y)] &&
      !visited[contour_index(width, right, y)] {
      ignore(
        flood_local_background_region(
          local_mask,
          visited,
          width,
          height,
          right,
          y,
          connectivity,
        ),
      )
    }
  }
  visited
}

fn build_outer_contour(
  img : @image.GrayImage,
  region : RegionData,
  external_background : Array[Bool],
) -> ContourDraft {
  let boundary_mask = Array::make(img.pixel_count(), false)
  let local_mask = local_component_mask(region, img.width())
  let mut perimeter = 0
  for y = 0; y < region.bbox.height; y = y + 1 {
    for x = 0; x < region.bbox.width; x = x + 1 {
      if !local_mask[contour_index(region.bbox.width, x, y)] {
        continue
      }
      let gx = region.bbox.x + x
      let gy = region.bbox.y + y
      let mut is_boundary = false
      for delta in orthogonal_directions() {
        let nx = gx + delta.x
        let ny = gy + delta.y
        if !contour_in_bounds(img, nx, ny) {
          perimeter = perimeter + 1
          is_boundary = true
          continue
        }
        if contour_mask_foreground(region.mask, img.width(), nx, ny) {
          continue
        }

        let lx = nx - region.bbox.x
        let ly = ny - region.bbox.y
        if lx < 0 || ly < 0 || lx >= region.bbox.width || ly >= region.bbox.height ||
          external_background[contour_index(region.bbox.width, lx, ly)] {
          perimeter = perimeter + 1
          is_boundary = true
        }
      }
      if is_boundary {
        boundary_mask[contour_index(img.width(), gx, gy)] = true
      }
    }
  }

  build_contour_draft(
    boundary_mask,
    img.width(),
    img.height(),
    region.area,
    perimeter,
    region.bbox,
    Outer,
    region.seed,
  )
}

fn build_hole_contour(
  img : @image.GrayImage,
  region : RegionData,
  hole_region : LocalRegionData,
) -> ContourDraft {
  let boundary_mask = Array::make(img.pixel_count(), false)
  let mut perimeter = 0
  for y = hole_region.bbox.y; y < hole_region.bbox.y + hole_region.bbox.height; y = y + 1 {
    for x = hole_region.bbox.x; x < hole_region.bbox.x + hole_region.bbox.width; x = x + 1 {
      if !contour_mask_foreground(hole_region.mask, region.bbox.width, x, y) {
        continue
      }
      let gx = region.bbox.x + x
      let gy = region.bbox.y + y
      for delta in orthogonal_directions() {
        let nx = gx + delta.x
        let ny = gy + delta.y
        if contour_in_bounds(img, nx, ny) &&
          contour_mask_foreground(region.mask, img.width(), nx, ny) {
          perimeter = perimeter + 1
          boundary_mask[contour_index(img.width(), nx, ny)] = true
        }
      }
    }
  }

  build_contour_draft(
    boundary_mask,
    img.width(),
    img.height(),
    hole_region.area,
    perimeter,
    {
      x: region.bbox.x + hole_region.bbox.x,
      y: region.bbox.y + hole_region.bbox.y,
      width: hole_region.bbox.width,
      height: hole_region.bbox.height,
    },
    Hole,
    {
      x: region.bbox.x + hole_region.seed.x,
      y: region.bbox.y + hole_region.seed.y,
    },
  )
}

fn collect_region_contours(
  img : @image.GrayImage,
  region : RegionData,
  connectivity : Int,
) -> Array[ContourDraft] {
  let drafts = []
  let local_mask = local_component_mask(region, img.width())
  let background_connectivity = dual_connectivity(connectivity)
  let visited_background = mark_external_background(
    local_mask,
    region.bbox.width,
    region.bbox.height,
    background_connectivity,
  )

  drafts.push(build_outer_contour(img, region, visited_background))

  for y = 0; y < region.bbox.height; y = y + 1 {
    for x = 0; x < region.bbox.width; x = x + 1 {
      let idx = contour_index(region.bbox.width, x, y)
      if local_mask[idx] || visited_background[idx] {
        continue
      }
      let hole_region = flood_local_background_region(
        local_mask,
        visited_background,
        region.bbox.width,
        region.bbox.height,
        x,
        y,
        background_connectivity,
      )
      drafts.push(build_hole_contour(img, region, hole_region))
    }
  }
  drafts
}

fn point_in_contour(points : Array[Point], sample : Point) -> Bool {
  if points.length() < 3 {
    return false
  }

  let px = sample.x.to_double() + 0.5
  let py = sample.y.to_double() + 0.5
  let mut inside = false
  let mut previous = points.length() - 1
  for i = 0; i < points.length(); i = i + 1 {
    let a = points[previous]
    let b = points[i]
    let ax = a.x.to_double() + 0.5
    let ay = a.y.to_double() + 0.5
    let bx = b.x.to_double() + 0.5
    let by = b.y.to_double() + 0.5
    let crosses = (ay > py) != (by > py)
    if crosses {
      let cross_x = (bx - ax) * (py - ay) / (by - ay) + ax
      if px < cross_x {
        inside = !inside
      }
    }
    previous = i
  }
  inside
}

fn assign_contour_hierarchy(drafts : Array[ContourDraft]) -> Array[Contour] {
  let contours = []
  for i = 0; i < drafts.length(); i = i + 1 {
    let draft = drafts[i]
    let mut parent : Int? = None
    let mut parent_box_area = 0
    for j = 0; j < drafts.length(); j = j + 1 {
      if i == j {
        continue
      }
      let candidate = drafts[j]
      if candidate.kind == draft.kind {
        continue
      }
      if !bbox_contains_point(candidate.bbox, draft.seed) {
        continue
      }
      if !point_in_contour(candidate.points, draft.seed) {
        continue
      }

      let candidate_area = bbox_area(candidate.bbox)
      match parent {
        Some(_) => {
          if candidate_area < parent_box_area {
            parent = Some(j)
            parent_box_area = candidate_area
          }
        }
        None => {
          parent = Some(j)
          parent_box_area = candidate_area
        }
      }
    }

    contours.push({
      points: draft.points,
      area: draft.area,
      perimeter: draft.perimeter,
      bbox: draft.bbox,
      kind: draft.kind,
      parent_index: parent,
    })
  }
  contours
}

///|
pub fn find_contours(
  img : @image.GrayImage,
  connectivity? : Int = 8,
) -> Array[Contour] raise @image.ImageError {
  validate_connectivity(connectivity)
  let visited = Array::make(img.pixel_count(), false)
  let drafts = []
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      if !contour_foreground(img, x, y) {
        continue
      }
      let idx = contour_index(img.width(), x, y)
      if visited[idx] {
        continue
      }
      let region = collect_foreground_region(img, visited, x, y, connectivity)
      for contour in collect_region_contours(img, region, connectivity) {
        drafts.push(contour)
      }
    }
  }
  assign_contour_hierarchy(drafts)
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
pub fn contour_kind(contour : Contour) -> ContourKind {
  contour.kind
}

///|
pub fn contour_parent_index(contour : Contour) -> Int? {
  contour.parent_index
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
