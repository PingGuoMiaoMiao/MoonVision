fn vertical_step() -> @image.GrayImage {
  try! @image.gray_from_array(
    5,
    5,
    [
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\xFF',
      b'\x00',
      b'\x00',
      b'\xFF',
      b'\xFF',
      b'\xFF',
    ],
  )
}

///|
test "sobel x detects vertical edge and sobel y stays flat" {
  let sx = try! sobel_x(vertical_step())
  let sy = try! sobel_y(vertical_step())
  inspect(sx.get(2, 2), content="b'\\xFF'")
  inspect(sx.get(0, 2), content="b'\\x00'")
  inspect(sy.get(2, 2), content="b'\\x00'")
}

///|
test "gradient magnitude and edge extract produce edge map" {
  let magnitude = try! gradient_magnitude(vertical_step())
  let edges = try! edge_extract(vertical_step(), threshold=200)
  inspect(
    magnitude.to_array(),
    content=(
      "[b'\\x00', b'\\xFF', b'\\xFF', b'\\x00', b'\\x00', b'\\x00', b'\\xFF', b'\\xFF', b'\\x00', b'\\x00', b'\\x00', b'\\xFF', b'\\xFF', b'\\x00', b'\\x00', b'\\x00', b'\\xFF', b'\\xFF', b'\\x00', b'\\x00', b'\\x00', b'\\xFF', b'\\xFF', b'\\x00', b'\\x00']"
    ),
  )
  inspect(
    edges.to_array(),
    content=(
      "[b'\\x00', b'\\xFF', b'\\xFF', b'\\x00', b'\\x00', b'\\x00', b'\\xFF', b'\\xFF', b'\\x00', b'\\x00', b'\\x00', b'\\xFF', b'\\xFF', b'\\x00', b'\\x00', b'\\x00', b'\\xFF', b'\\xFF', b'\\x00', b'\\x00', b'\\x00', b'\\xFF', b'\\xFF', b'\\x00', b'\\x00']"
    ),
  )
}
