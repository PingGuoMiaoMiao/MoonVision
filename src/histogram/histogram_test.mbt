///|
test "gray histogram counts exact byte values" {
  let img = try! @image.gray_from_array(4, 1, [
    b'\x00', b'\x02', b'\x02', b'\xff',
  ])
  let hist = try! gray_histogram(img)
  inspect(hist[0], content="1")
  inspect(hist[1], content="0")
  inspect(hist[2], content="2")
  inspect(hist[255], content="1")
}

///|
test "cumulative histogram is monotonic" {
  let hist = Array::make(256, 0)
  hist[0] = 1
  hist[2] = 2
  hist[255] = 1
  let cumulative = try! cumulative_histogram(hist)
  inspect(cumulative[0], content="1")
  inspect(cumulative[1], content="1")
  inspect(cumulative[2], content="3")
  inspect(cumulative[255], content="4")
}

///|
test "normalize histogram scales by maximum count" {
  let hist = Array::make(256, 0)
  hist[10] = 2
  hist[20] = 4
  let normalized = try! normalize_histogram(hist, 100)
  inspect(normalized[10], content="50")
  inspect(normalized[20], content="100")
}

///|
#warnings("-deprecated")
test "equalize histogram expands low contrast fixture" {
  let img = try! @image.gray_from_array(4, 1, [
    b'\x32', b'\x32', b'\x64', b'\x96',
  ])
  let out = try! equalize_histogram(img)
  @debug.inspect(out.to_array(), content="[0x00, 0x00, 0x80, 0xff]")
}

///|
#warnings("-deprecated")
test "equalize histogram maps constant image safely" {
  let img = try! @image.gray_from_array(3, 1, [b'\x2a', b'\x2a', b'\x2a'])
  let out = try! equalize_histogram(img)
  @debug.inspect(out.to_array(), content="[0x00, 0x00, 0x00]")
}
