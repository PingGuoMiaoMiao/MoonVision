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
