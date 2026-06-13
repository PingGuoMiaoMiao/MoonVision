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

struct RotatedRect {
  center_x : Double
  center_y : Double
  width : Double
  height : Double
  angle_deg : Double
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

fn copy_points(points : Array[Point]) -> Array[Point] {
  let copied = []
  for point in points {
    copied.push(point)
  }
  copied
}

fn point_equal(left : Point, right : Point) -> Bool {
  left.x == right.x && left.y == right.y
}

fn point_less(left : Point, right : Point) -> Bool {
  left.x < right.x || (left.x == right.x && left.y < right.y)
}

fn insertion_sort_points(points : Array[Point]) -> Unit {
  for i = 1; i < points.length(); i = i + 1 {
    let next = points[i]
    let mut j = i - 1
    while j >= 0 && point_less(next, points[j]) {
      points[j + 1] = points[j]
      j = j - 1
    }
    points[j + 1] = next
  }
}

fn unique_sorted_points(points : Array[Point]) -> Array[Point] {
  if points.length() == 0 {
    return []
  }
  let sorted = copy_points(points)
  insertion_sort_points(sorted)
  let unique = [sorted[0]]
  for i = 1; i < sorted.length(); i = i + 1 {
    if !point_equal(sorted[i], sorted[i - 1]) {
      unique.push(sorted[i])
    }
  }
  unique
}

fn contour_cross(origin : Point, left : Point, right : Point) -> Int {
  (left.x - origin.x) * (right.y - origin.y) - (left.y - origin.y) * (right.x - origin.x)
}

fn convex_hull_points(points : Array[Point]) -> Array[Point] {
  let unique = unique_sorted_points(points)
  if unique.length() <= 1 {
    return unique
  }

  let lower = []
  for point in unique {
    while lower.length() >= 2 &&
      contour_cross(lower[lower.length() - 2], lower[lower.length() - 1], point) <= 0 {
      ignore(lower.pop())
    }
    lower.push(point)
  }

  let upper = []
  let mut i = unique.length()
  while i > 0 {
    i = i - 1
    let point = unique[i]
    while upper.length() >= 2 &&
      contour_cross(upper[upper.length() - 2], upper[upper.length() - 1], point) <= 0 {
      ignore(upper.pop())
    }
    upper.push(point)
  }

  ignore(lower.pop())
  ignore(upper.pop())
  let hull = []
  for point in lower {
    hull.push(point)
  }
  for point in upper {
    hull.push(point)
  }
  if hull.length() == 0 {
    [unique[0]]
  } else {
    hull
  }
}

fn squared_distance_to_point(sample : Point, point : Point) -> Double {
  let dx = (sample.x - point.x).to_double()
  let dy = (sample.y - point.y).to_double()
  dx * dx + dy * dy
}

fn point_segment_distance_sq(sample : Point, start : Point, end_ : Point) -> Double {
  let dx = (end_.x - start.x).to_double()
  let dy = (end_.y - start.y).to_double()
  let len_sq = dx * dx + dy * dy
  if len_sq == 0.0 {
    return squared_distance_to_point(sample, start)
  }

  let px = (sample.x - start.x).to_double()
  let py = (sample.y - start.y).to_double()
  let projection = (px * dx + py * dy) / len_sq
  if projection <= 0.0 {
    return squared_distance_to_point(sample, start)
  }
  if projection >= 1.0 {
    return squared_distance_to_point(sample, end_)
  }

  let nearest_x = start.x.to_double() + projection * dx
  let nearest_y = start.y.to_double() + projection * dy
  let diff_x = sample.x.to_double() - nearest_x
  let diff_y = sample.y.to_double() - nearest_y
  diff_x * diff_x + diff_y * diff_y
}

fn approx_polyline(points : Array[Point], epsilon : Double) -> Array[Point] {
  if points.length() <= 2 {
    return copy_points(points)
  }

  let threshold = if epsilon <= 0.0 {
    0.0
  } else {
    epsilon * epsilon
  }
  let keep = Array::make(points.length(), false)
  keep[0] = true
  keep[points.length() - 1] = true
  let stack_starts = [0]
  let stack_ends = [points.length() - 1]

  while stack_starts.length() > 0 {
    let last = stack_starts.length() - 1
    let start = stack_starts[last]
    let end_ = stack_ends[last]
    ignore(stack_starts.pop())
    ignore(stack_ends.pop())
    if end_ <= start + 1 {
      continue
    }

    let mut best_index = -1
    let mut best_distance = -1.0
    for i = start + 1; i < end_; i = i + 1 {
      let distance = point_segment_distance_sq(points[i], points[start], points[end_])
      if distance > best_distance {
        best_distance = distance
        best_index = i
      }
    }

    if best_index != -1 && best_distance > threshold {
      keep[best_index] = true
      stack_starts.push(start)
      stack_ends.push(best_index)
      stack_starts.push(best_index)
      stack_ends.push(end_)
    }
  }

  let simplified = []
  for i = 0; i < points.length(); i = i + 1 {
    if keep[i] {
      simplified.push(points[i])
    }
  }
  simplified
}

fn point_on_segment(sample : Point, start : Point, end_ : Point) -> Bool {
  let cross = (sample.x - start.x) * (end_.y - start.y) -
    (sample.y - start.y) * (end_.x - start.x)
  if cross != 0 {
    return false
  }

  let min_x = if start.x < end_.x { start.x } else { end_.x }
  let max_x = if start.x > end_.x { start.x } else { end_.x }
  let min_y = if start.y < end_.y { start.y } else { end_.y }
  let max_y = if start.y > end_.y { start.y } else { end_.y }
  sample.x >= min_x && sample.x <= max_x && sample.y >= min_y && sample.y <= max_y
}

fn point_in_polygon_or_boundary(points : Array[Point], sample : Point) -> Bool {
  if points.length() == 0 {
    return false
  }
  if points.length() == 1 {
    return point_equal(points[0], sample)
  }

  let mut previous = points.length() - 1
  for i = 0; i < points.length(); i = i + 1 {
    if point_on_segment(sample, points[previous], points[i]) {
      return true
    }
    previous = i
  }

  let px = sample.x.to_double()
  let py = sample.y.to_double()
  let mut inside = false
  previous = points.length() - 1
  for i = 0; i < points.length(); i = i + 1 {
    let start = points[previous]
    let end_ = points[i]
    let start_y = start.y.to_double()
    let end_y = end_.y.to_double()
    let crosses = (start_y > py) != (end_y > py)
    if crosses {
      let start_x = start.x.to_double()
      let end_x = end_.x.to_double()
      let cross_x = (end_x - start_x) * (py - start_y) / (end_y - start_y) + start_x
      if px < cross_x {
        inside = !inside
      }
    }
    previous = i
  }
  inside
}

fn hull_fill_area(points : Array[Point]) -> Int {
  if points.length() == 0 {
    return 0
  }

  let mut min_x = points[0].x
  let mut max_x = points[0].x
  let mut min_y = points[0].y
  let mut max_y = points[0].y
  for point in points {
    if point.x < min_x {
      min_x = point.x
    }
    if point.x > max_x {
      max_x = point.x
    }
    if point.y < min_y {
      min_y = point.y
    }
    if point.y > max_y {
      max_y = point.y
    }
  }

  let mut count = 0
  for y = min_y; y <= max_y; y = y + 1 {
    for x = min_x; x <= max_x; x = x + 1 {
      if point_in_polygon_or_boundary(points, { x, y }) {
        count = count + 1
      }
    }
  }
  count
}

fn abs_double(value : Double) -> Double {
  if value < 0.0 {
    -value
  } else {
    value
  }
}

fn normalize_rect_angle(angle_deg : Double) -> Double {
  let mut angle = angle_deg
  while angle <= -90.0 {
    angle = angle + 180.0
  }
  while angle > 90.0 {
    angle = angle - 180.0
  }
  angle
}

fn atan2_approx_deg(y : Double, x : Double) -> Double {
  if x == 0.0 && y == 0.0 {
    return 0.0
  }

  let abs_y = abs_double(y) + 0.0000000001
  let (ratio, base) = if x < 0.0 {
    ((x + abs_y) / (abs_y - x), 2.356194490192345)
  } else {
    ((x - abs_y) / (x + abs_y), 0.7853981633974483)
  }
  let angle = base + (0.1963 * ratio * ratio - 0.9817) * ratio
  let signed = if y < 0.0 { -angle } else { angle }
  normalize_rect_angle(signed * 57.29577951308232)
}

fn zero_rotated_rect(point : Point) -> RotatedRect {
  {
    center_x: point.x.to_double(),
    center_y: point.y.to_double(),
    width: 1.0,
    height: 1.0,
    angle_deg: 0.0,
  }
}

fn min_area_rect_points(points : Array[Point]) -> RotatedRect {
  if points.length() == 0 {
    return {
      center_x: 0.0,
      center_y: 0.0,
      width: 0.0,
      height: 0.0,
      angle_deg: 0.0,
    }
  }

  let hull = convex_hull_points(points)
  if hull.length() == 1 {
    return zero_rotated_rect(hull[0])
  }
  if hull.length() == 2 {
    let start = hull[0]
    let end_ = hull[1]
    let dx = (end_.x - start.x).to_double()
    let dy = (end_.y - start.y).to_double()
    return {
      center_x: (start.x + end_.x).to_double() / 2.0,
      center_y: (start.y + end_.y).to_double() / 2.0,
      width: (dx * dx + dy * dy).sqrt() + 1.0,
      height: 1.0,
      angle_deg: atan2_approx_deg(dy, dx),
    }
  }

  let mut best = zero_rotated_rect(hull[0])
  let mut best_area = 0.0
  let mut found = false

  for i = 0; i < hull.length(); i = i + 1 {
    let start = hull[i]
    let end_ = hull[(i + 1) % hull.length()]
    let dx = (end_.x - start.x).to_double()
    let dy = (end_.y - start.y).to_double()
    let edge_sq = dx * dx + dy * dy
    if edge_sq == 0.0 {
      continue
    }
    let edge_len = edge_sq.sqrt()
    let ux = dx / edge_len
    let uy = dy / edge_len
    let vx = -uy
    let vy = ux

    let first_u = hull[0].x.to_double() * ux + hull[0].y.to_double() * uy
    let first_v = hull[0].x.to_double() * vx + hull[0].y.to_double() * vy
    let mut min_u = first_u
    let mut max_u = first_u
    let mut min_v = first_v
    let mut max_v = first_v
    for point in hull {
      let proj_u = point.x.to_double() * ux + point.y.to_double() * uy
      let proj_v = point.x.to_double() * vx + point.y.to_double() * vy
      if proj_u < min_u {
        min_u = proj_u
      }
      if proj_u > max_u {
        max_u = proj_u
      }
      if proj_v < min_v {
        min_v = proj_v
      }
      if proj_v > max_v {
        max_v = proj_v
      }
    }

    let mut width = max_u - min_u + 1.0
    let mut height = max_v - min_v + 1.0
    let center_u = (min_u + max_u) / 2.0
    let center_v = (min_v + max_v) / 2.0
    let center_x = center_u * ux + center_v * vx
    let center_y = center_u * uy + center_v * vy
    let mut angle_deg = atan2_approx_deg(dy, dx)

    if height > width {
      let swapped = width
      width = height
      height = swapped
      angle_deg = normalize_rect_angle(angle_deg + 90.0)
    }

    let area = width * height
    if !found || area < best_area {
      best = { center_x, center_y, width, height, angle_deg }
      best_area = area
      found = true
    }
  }
  best
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
pub fn approx_contour(contour : Contour, epsilon : Double) -> Array[Point] {
  let original = contour.points
  if original.length() <= 2 {
    return copy_points(original)
  }

  let closed = copy_points(original)
  if !point_equal(closed[0], closed[closed.length() - 1]) {
    closed.push(closed[0])
  }
  let simplified = approx_polyline(closed, epsilon)
  if simplified.length() > 1 &&
    point_equal(simplified[0], simplified[simplified.length() - 1]) {
    ignore(simplified.pop())
  }
  if simplified.length() == 0 {
    [original[0]]
  } else {
    simplified
  }
}

///|
pub fn convex_hull(contour : Contour) -> Array[Point] {
  convex_hull_points(contour.points)
}

///|
pub fn min_area_rect(contour : Contour) -> RotatedRect {
  min_area_rect_points(contour.points)
}

///|
pub fn contour_vertex_count(contour : Contour) -> Int {
  contour.points.length()
}

///|
pub fn contour_circularity(contour : Contour) -> Double {
  let perimeter = contour.perimeter.to_double()
  if perimeter == 0.0 {
    return 0.0
  }
  12.566370614359172 * contour.area.to_double() / (perimeter * perimeter)
}

///|
pub fn contour_solidity(contour : Contour) -> Double {
  let hull = convex_hull_points(contour.points)
  let hull_area = hull_fill_area(hull)
  if hull_area == 0 {
    return 0.0
  }
  contour.area.to_double() / hull_area.to_double()
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

///|
pub fn RotatedRect::center_x(self : RotatedRect) -> Double {
  self.center_x
}

///|
pub fn RotatedRect::center_y(self : RotatedRect) -> Double {
  self.center_y
}

///|
pub fn RotatedRect::width(self : RotatedRect) -> Double {
  self.width
}

///|
pub fn RotatedRect::height(self : RotatedRect) -> Double {
  self.height
}

///|
pub fn RotatedRect::angle_deg(self : RotatedRect) -> Double {
  self.angle_deg
}
