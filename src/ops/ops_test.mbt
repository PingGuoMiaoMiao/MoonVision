///|
test "grayscale converts rgb image" {
  let rgb = try! @image.rgb_from_array(
    2,
    1,
    [b'\xff', b'\x00', b'\x00', b'\x00', b'\xff', b'\x00'],
  )
  let gray = try! grayscale(rgb)
  inspect(gray.to_array(), content="[b'\\x4C', b'\\x96']")
}

///|
test "threshold creates binary image" {
  let img = try! @image.gray_from_array(4, 1, [b'\x20', b'\x7f', b'\x80', b'\xff'])
  let out = try! threshold(img, 128)
  inspect(out.to_array(), content="[b'\\x00', b'\\x00', b'\\xFF', b'\\xFF']")
}

///|
test "otsu threshold splits bimodal grayscale image" {
  let img = try! @image.gray_from_array(
    6,
    1,
    [b'\x0a', b'\x0b', b'\x0c', b'\xc8', b'\xc9', b'\xca'],
  )
  let out = try! otsu_threshold(img)
  inspect(out.to_array(), content="[b'\\x00', b'\\x00', b'\\x00', b'\\xFF', b'\\xFF', b'\\xFF']")
}

///|
test "invert and brightness are composable" {
  let img = try! @image.gray_from_array(3, 1, [b'\x00', b'\x40', b'\xff'])
  let inverted = try! invert(img)
  let brighter = try! adjust_brightness(inverted, 10)
  inspect(
    brighter.to_array(),
    content="[b'\\xFF', b'\\xC9', b'\\x0A']",
  )
}
