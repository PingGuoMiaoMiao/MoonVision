///|
test "gray image construction and pixel access" {
  let img = try! gray_from_array(2, 2, [b'\x01', b'\x02', b'\x03', b'\x04'])
  inspect(img.width(), content="2")
  inspect(img.height(), content="2")
  inspect(img.get(1, 0), content="b'\\x02'")
  inspect(img.get(0, 1), content="b'\\x03'")
}

///|
test "gray image rejects bad buffer length" {
  let err = try? gray_from_array(2, 2, [b'\x01'])
  inspect(
    err,
    content="Err(InvalidBufferLength(4, 1))",
  )
}

///|
test "rgb image stores and reads triples" {
  let img = try! rgb(2, 1, fill=rgb_pixel(b'\x00', b'\x00', b'\x00'))
  try! img.set(1, 0, rgb_pixel(b'\x10', b'\x20', b'\x30'))
  let pixel = try! img.get(1, 0)
  inspect(pixel.r(), content="b'\\x10'")
  inspect(pixel.g(), content="b'\\x20'")
  inspect(pixel.b(), content="b'\\x30'")
}
