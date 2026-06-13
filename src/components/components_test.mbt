fn component_fixture() -> @image.GrayImage {
  try! @image.gray_from_array(
    6,
    5,
    [
      b'\x00',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\x00',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\x00',
      b'\x00',
    ],
  )
}

///|
test "connected components merges diagonal foreground in 8-neighborhood" {
  let components = try! connected_components(component_fixture())
  inspect(components.length(), content="4")

  let first = components[0]
  let second = components[1]
  let third = components[2]
  let fourth = components[3]

  inspect(first.area(), content="2")
  inspect(first.bbox().x(), content="1")
  inspect(first.bbox().y(), content="0")
  inspect(first.bbox().width(), content="2")
  inspect(first.bbox().height(), content="2")

  inspect(second.area(), content="2")
  inspect(second.bbox().x(), content="4")
  inspect(second.bbox().y(), content="1")

  inspect(third.area(), content="2")
  inspect(third.bbox().x(), content="0")
  inspect(third.bbox().y(), content="3")

  inspect(fourth.area(), content="1")
  inspect(fourth.bbox().x(), content="3")
  inspect(fourth.bbox().y(), content="4")
}

///|
test "connected components applies minimum area filter" {
  let components = try! connected_components(component_fixture(), min_area=2)
  inspect(components.length(), content="3")
  inspect(components[0].area(), content="2")
  inspect(components[1].area(), content="2")
  inspect(components[2].area(), content="2")
}

fn contour_square_fixture() -> @image.GrayImage {
  try! @image.gray_from_array(
    4,
    4,
    [
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
    ],
  )
}

fn kind_is_outer(kind : ContourKind) -> Bool {
  match kind {
    Outer => true
    Hole => false
  }
}

fn parent_or_minus_one(parent : Int?) -> Int {
  match parent {
    Some(index) => index
    None => -1
  }
}

fn abs_double(value : Double) -> Double {
  if value < 0.0 {
    -value
  } else {
    value
  }
}

fn double_close(actual : Double, expected : Double, tolerance : Double) -> Bool {
  abs_double(actual - expected) <= tolerance
}

fn contour_rectangle_fixture() -> @image.GrayImage {
  try! @image.gray_from_array(
    6,
    5,
    [
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
    ],
  )
}

fn contour_notch_fixture() -> @image.GrayImage {
  try! @image.gray_from_array(
    5,
    5,
    [
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
    ],
  )
}

fn contour_diamond_fixture() -> @image.GrayImage {
  try! @image.gray_from_array(
    7,
    5,
    [
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
    ],
  )
}

///|
test "find contours extracts a single square contour" {
  let contours = try! find_contours(contour_square_fixture())
  inspect(contours.length(), content="1")
  inspect(contour_area(contours[0]), content="4")
  inspect(contour_perimeter(contours[0]), content="8")
  inspect(kind_is_outer(contour_kind(contours[0])), content="true")
  inspect(parent_or_minus_one(contour_parent_index(contours[0])), content="-1")
  inspect(contour_bbox(contours[0]).x(), content="1")
  inspect(contour_bbox(contours[0]).y(), content="1")
  inspect(contour_bbox(contours[0]).width(), content="2")
  inspect(contour_bbox(contours[0]).height(), content="2")
  inspect(contours[0].points().length(), content="4")
  inspect(contours[0].points()[0].x(), content="1")
  inspect(contours[0].points()[0].y(), content="1")
  inspect(contours[0].points()[1].x(), content="2")
  inspect(contours[0].points()[1].y(), content="1")
  inspect(contours[0].points()[2].x(), content="2")
  inspect(contours[0].points()[2].y(), content="2")
  inspect(contours[0].points()[3].x(), content="1")
  inspect(contours[0].points()[3].y(), content="2")
}

///|
test "find contours handles empty and multi-object binary images" {
  let empty = try! @image.gray(3, 3)
  let contours = try! find_contours(empty)
  inspect(contours.length(), content="0")

  let multi = try! @image.gray_from_array(
    5,
    4,
    [
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
    ],
  )
  let multi_contours = try! find_contours(multi, connectivity=4)
  inspect(multi_contours.length(), content="3")
  inspect(contour_area(multi_contours[0]), content="1")
  inspect(contour_bbox(multi_contours[1]).x(), content="3")
  inspect(contour_bbox(multi_contours[2]).x(), content="4")
}

///|
test "find contours supports edge-touching shapes" {
  let touching = try! @image.gray_from_array(
    3,
    3,
    [
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
    ],
  )
  let contours = try! find_contours(touching)
  inspect(contours.length(), content="1")
  inspect(contour_bbox(contours[0]).x(), content="0")
  inspect(contour_bbox(contours[0]).y(), content="0")
  inspect(contour_bbox(contours[0]).width(), content="2")
  inspect(contour_bbox(contours[0]).height(), content="2")
}

///|
test "find contours preserves boundary walk order on thin lines" {
  let line = try! @image.gray_from_array(
    5,
    3,
    [
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
    ],
  )
  let contours = try! find_contours(line)
  inspect(contours.length(), content="1")
  inspect(contours[0].points().length(), content="3")
  inspect(contours[0].points()[0].x(), content="1")
  inspect(contours[0].points()[0].y(), content="1")
  inspect(contours[0].points()[1].x(), content="2")
  inspect(contours[0].points()[1].y(), content="1")
  inspect(contours[0].points()[2].x(), content="3")
  inspect(contours[0].points()[2].y(), content="1")
}

///|
test "find contours splits hollow foreground into outer and hole contours" {
  let hollow = try! @image.gray_from_array(
    4,
    4,
    [
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
    ],
  )
  let contours = try! find_contours(hollow)
  inspect(contours.length(), content="2")
  inspect(contour_area(contours[0]), content="12")
  inspect(contour_perimeter(contours[0]), content="16")
  inspect(kind_is_outer(contour_kind(contours[0])), content="true")
  inspect(parent_or_minus_one(contour_parent_index(contours[0])), content="-1")
  inspect(contour_bbox(contours[0]).x(), content="0")
  inspect(contour_bbox(contours[0]).y(), content="0")
  inspect(contour_bbox(contours[0]).width(), content="4")
  inspect(contour_bbox(contours[0]).height(), content="4")
  inspect(contour_area(contours[1]), content="4")
  inspect(contour_perimeter(contours[1]), content="8")
  inspect(kind_is_outer(contour_kind(contours[1])), content="false")
  inspect(parent_or_minus_one(contour_parent_index(contours[1])), content="0")
  inspect(contour_bbox(contours[1]).x(), content="1")
  inspect(contour_bbox(contours[1]).y(), content="1")
  inspect(contour_bbox(contours[1]).width(), content="2")
  inspect(contour_bbox(contours[1]).height(), content="2")
}

///|
test "find contours assigns parent hierarchy on nested foreground islands" {
  let nested = try! @image.gray_from_array(
    7,
    7,
    [
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\xFF',
    ],
  )
  let contours = try! find_contours(nested)
  inspect(contours.length(), content="3")
  inspect(kind_is_outer(contour_kind(contours[0])), content="true")
  inspect(parent_or_minus_one(contour_parent_index(contours[0])), content="-1")
  inspect(kind_is_outer(contour_kind(contours[1])), content="false")
  inspect(parent_or_minus_one(contour_parent_index(contours[1])), content="0")
  inspect(kind_is_outer(contour_kind(contours[2])), content="true")
  inspect(parent_or_minus_one(contour_parent_index(contours[2])), content="1")
  inspect(contour_area(contours[2]), content="1")
  inspect(contour_perimeter(contours[2]), content="4")
}

///|
test "approx contour reduces a filled rectangle to four corners" {
  let contours = try! find_contours(contour_rectangle_fixture())
  inspect(contours.length(), content="1")
  let simplified = approx_contour(contours[0], 1.0)
  inspect(simplified.length(), content="4")
  inspect(simplified[0].x(), content="1")
  inspect(simplified[0].y(), content="1")
  inspect(simplified[1].x(), content="4")
  inspect(simplified[1].y(), content="1")
  inspect(simplified[2].x(), content="4")
  inspect(simplified[2].y(), content="3")
  inspect(simplified[3].x(), content="1")
  inspect(simplified[3].y(), content="3")
}

///|
test "convex hull removes the concave notch from a simple region" {
  let contours = try! find_contours(contour_notch_fixture())
  inspect(contours.length(), content="1")
  let hull = convex_hull(contours[0])
  inspect(hull.length(), content="4")
  inspect(hull[0].x(), content="1")
  inspect(hull[0].y(), content="1")
  inspect(hull[1].x(), content="3")
  inspect(hull[1].y(), content="1")
  inspect(hull[2].x(), content="3")
  inspect(hull[2].y(), content="3")
  inspect(hull[3].x(), content="1")
  inspect(hull[3].y(), content="3")
}

///|
test "min area rect matches axis-aligned rectangle geometry" {
  let contours = try! find_contours(contour_rectangle_fixture())
  let rect = min_area_rect(contours[0])
  inspect(double_close(rect.center_x(), 2.5, 0.0001), content="true")
  inspect(double_close(rect.center_y(), 2.0, 0.0001), content="true")
  inspect(double_close(rect.width(), 4.0, 0.0001), content="true")
  inspect(double_close(rect.height(), 3.0, 0.0001), content="true")
  inspect(double_close(rect.angle_deg(), 0.0, 0.5), content="true")
}

///|
test "min area rect keeps a stable non-zero angle on a diamond-like region" {
  let contours = try! find_contours(contour_diamond_fixture())
  let rect = min_area_rect(contours[0])
  inspect(abs_double(rect.angle_deg()) > 20.0, content="true")
  inspect(abs_double(rect.angle_deg()) < 70.0, content="true")
  inspect(rect.width() > 0.0, content="true")
  inspect(rect.height() > 0.0, content="true")
}

///|
test "contour descriptors stay finite on fixed fixtures" {
  let rectangle = (try! find_contours(contour_rectangle_fixture()))[0]
  inspect(contour_vertex_count(rectangle) == rectangle.points().length(), content="true")
  inspect(double_close(contour_circularity(rectangle), 0.7693696294505615, 0.001), content="true")

  let notch = (try! find_contours(contour_notch_fixture()))[0]
  inspect(double_close(contour_solidity(notch), 0.8888888888888888, 0.001), content="true")
}
