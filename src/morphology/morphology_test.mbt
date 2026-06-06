fn binary_noise() -> @image.GrayImage {
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
      b'\x00',
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

fn binary_hole() -> @image.GrayImage {
  try! @image.gray_from_array(
    7,
    7,
    [
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
      b'\x00',
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
      b'\x00',
      b'\x00',
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

///|
test "erode and dilate transform binary regions" {
  let eroded = try! erode(binary_hole(), radius=1)
  let dilated = try! dilate(binary_noise(), radius=1)
  inspect(try! eroded.get(3, 3), content="b'\\x00'")
  inspect(try! eroded.get(2, 2), content="b'\\x00'")
  inspect(try! dilated.get(1, 1), content="b'\\xFF'")
  inspect(try! dilated.get(3, 3), content="b'\\xFF'")
  inspect(try! dilated.get(4, 4), content="b'\\x00'")
}

///|
test "opening removes isolated noise and closing fills hole" {
  let opened = try! open_binary(binary_noise(), radius=1)
  let closed = try! close_binary(binary_hole(), radius=1)
  inspect(try! opened.get(1, 1), content="b'\\x00'")
  inspect(try! opened.get(2, 2), content="b'\\x00'")
  inspect(try! closed.get(3, 3), content="b'\\xFF'")
  inspect(try! closed.get(2, 2), content="b'\\xFF'")
  inspect(try! closed.get(0, 0), content="b'\\x00'")
}
