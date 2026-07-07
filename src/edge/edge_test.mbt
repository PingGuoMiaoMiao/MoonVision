///|
fn vertical_step() -> @image.GrayImage {
  try! @image.gray_from_array(5, 5, [
    b'\x00', b'\x00', b'\xFF', b'\xFF', b'\xFF', b'\x00', b'\x00', b'\xFF', b'\xFF',
    b'\xFF', b'\x00', b'\x00', b'\xFF', b'\xFF', b'\xFF', b'\x00', b'\x00', b'\xFF',
    b'\xFF', b'\xFF', b'\x00', b'\x00', b'\xFF', b'\xFF', b'\xFF',
  ])
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
#warnings("-deprecated")
test "gradient magnitude and edge extract produce edge map" {
  let magnitude = try! gradient_magnitude(vertical_step())
  let edges = try! edge_extract(vertical_step(), threshold=200)
  @debug.inspect(
    magnitude.to_array(),
    content=(
      #|[
      #|  0x00,
      #|  0xff,
      #|  0xff,
      #|  0x00,
      #|  0x00,
      #|  0x00,
      #|  0xff,
      #|  0xff,
      #|  0x00,
      #|  0x00,
      #|  0x00,
      #|  0xff,
      #|  0xff,
      #|  0x00,
      #|  0x00,
      #|  0x00,
      #|  0xff,
      #|  0xff,
      #|  0x00,
      #|  0x00,
      #|  0x00,
      #|  0xff,
      #|  0xff,
      #|  0x00,
      #|  0x00,
      #|]
    ),
  )
  @debug.inspect(
    edges.to_array(),
    content=(
      #|[
      #|  0x00,
      #|  0xff,
      #|  0xff,
      #|  0x00,
      #|  0x00,
      #|  0x00,
      #|  0xff,
      #|  0xff,
      #|  0x00,
      #|  0x00,
      #|  0x00,
      #|  0xff,
      #|  0xff,
      #|  0x00,
      #|  0x00,
      #|  0x00,
      #|  0xff,
      #|  0xff,
      #|  0x00,
      #|  0x00,
      #|  0x00,
      #|  0xff,
      #|  0xff,
      #|  0x00,
      #|  0x00,
      #|]
    ),
  )
}

///|
#warnings("-deprecated")
test "canny edges extract a thin binary edge map" {
  let edges = try! canny_edges(vertical_step(), 64, 128)
  @debug.inspect(
    edges.to_array(),
    content=(
      #|[
      #|  0x00,
      #|  0xff,
      #|  0x00,
      #|  0x00,
      #|  0x00,
      #|  0x00,
      #|  0xff,
      #|  0x00,
      #|  0x00,
      #|  0x00,
      #|  0x00,
      #|  0xff,
      #|  0x00,
      #|  0x00,
      #|  0x00,
      #|  0x00,
      #|  0xff,
      #|  0x00,
      #|  0x00,
      #|  0x00,
      #|  0x00,
      #|  0xff,
      #|  0x00,
      #|  0x00,
      #|  0x00,
      #|]
    ),
  )
}

///|
test "canny edges rejects inverted thresholds" {
  try canny_edges(vertical_step(), 128, 128) catch {
    err =>
      inspect(
        match err {
          @image.InvalidDimensions(message) =>
            message == "canny low_threshold must be less than high_threshold"
          _ => false
        },
        content="true",
      )
  } noraise {
    _ => fail("expected canny_edges to raise")
  }
}

///|
test "hough lines detect vertical and horizontal edge maps" {
  let vertical = try! @image.gray_from_array(5, 5, [
    b'\x00', b'\x00', b'\xff', b'\x00', b'\x00', b'\x00', b'\x00', b'\xff', b'\x00',
    b'\x00', b'\x00', b'\x00', b'\xff', b'\x00', b'\x00', b'\x00', b'\x00', b'\xff',
    b'\x00', b'\x00', b'\x00', b'\x00', b'\xff', b'\x00', b'\x00',
  ])
  let vertical_lines = try! hough_lines(vertical, vote_threshold=5, max_lines=1)
  inspect(vertical_lines.length(), content="1")
  inspect(vertical_lines[0].theta_bucket(), content="0")
  inspect(vertical_lines[0].rho(), content="2")
  inspect(vertical_lines[0].votes(), content="5")
  let horizontal = try! @image.gray_from_array(5, 5, [
    b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
    b'\x00', b'\xff', b'\xff', b'\xff', b'\xff', b'\xff', b'\x00', b'\x00', b'\x00',
    b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
  ])
  let horizontal_lines = try! hough_lines(
    horizontal,
    vote_threshold=5,
    max_lines=1,
  )
  inspect(horizontal_lines.length(), content="1")
  inspect(horizontal_lines[0].theta_bucket(), content="90")
  inspect(horizontal_lines[0].rho(), content="2")
  inspect(horizontal_lines[0].votes(), content="5")
}

///|
test "hough lines handle empty maps and deterministic ordering" {
  let empty = try! @image.gray(4, 4)
  let none = try! hough_lines(empty, vote_threshold=1)
  inspect(none.length(), content="0")
  let cross = try! @image.gray_from_array(3, 3, [
    b'\x00', b'\xff', b'\x00', b'\xff', b'\xff', b'\xff', b'\x00', b'\xff', b'\x00',
  ])
  let lines = try! hough_lines(cross, vote_threshold=3, max_lines=2)
  inspect(lines.length(), content="2")
  inspect(lines[0].theta_bucket(), content="0")
  inspect(lines[0].rho(), content="1")
  inspect(lines[1].theta_bucket(), content="90")
  inspect(lines[1].rho(), content="1")
}
