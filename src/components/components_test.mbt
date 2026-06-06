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
