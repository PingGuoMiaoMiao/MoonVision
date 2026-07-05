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

///|
test "morphological gradient highlights binary boundary" {
  let gradient = try! morphological_gradient(binary_hole(), radius=1)
  inspect(try! gradient.get(2, 2), content="b'\\xFF'")
  inspect(try! gradient.get(3, 3), content="b'\\xFF'")
  inspect(try! gradient.get(0, 0), content="b'\\x00'")
}

///|
test "top hat and black hat extract removed foreground and filled holes" {
  let bright = try! top_hat(binary_noise(), radius=1)
  let dark = try! black_hat(binary_hole(), radius=1)
  inspect(try! bright.get(1, 1), content="b'\\xFF'")
  inspect(try! bright.get(2, 2), content="b'\\xFF'")
  inspect(try! dark.get(3, 3), content="b'\\xFF'")
  inspect(try! dark.get(0, 0), content="b'\\x00'")
}

///|
test "iterations match repeated dilation" {
  let once = try! dilate(binary_noise(), radius=1)
  let twice_manual = try! dilate(once, radius=1)
  let twice_option = try! dilate(binary_noise(), radius=1, iterations=2)
  inspect(twice_option == twice_manual, content="true")
}

///|
test "cross and square structuring elements differ on diagonal fixture" {
  let img = try! @image.gray_from_array(
    3,
    3,
    [
      b'\xff',
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
  let square = try! dilate(img, radius=1, element=Square)
  let cross = try! dilate(img, radius=1, element=Cross)
  inspect(try! square.get(1, 1), content="b'\\xFF'")
  inspect(try! cross.get(1, 1), content="b'\\x00'")
}
