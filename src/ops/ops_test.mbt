///|
#warnings("-deprecated")
test "grayscale converts rgb image" {
  let rgb = try! @image.rgb_from_array(2, 1, [
    b'\xff', b'\x00', b'\x00', b'\x00', b'\xff', b'\x00',
  ])
  let gray = try! grayscale(rgb)
  @debug.inspect(gray.to_array(), content="[0x4c, 0x96]")
}

///|
#warnings("-deprecated")
test "threshold creates binary image" {
  let img = try! @image.gray_from_array(4, 1, [
    b'\x20', b'\x7f', b'\x80', b'\xff',
  ])
  let out = try! threshold(img, 128)
  @debug.inspect(out.to_array(), content="[0x00, 0x00, 0xff, 0xff]")
}

///|
#warnings("-deprecated")
test "otsu threshold splits bimodal grayscale image" {
  let img = try! @image.gray_from_array(6, 1, [
    b'\x0a', b'\x0b', b'\x0c', b'\xc8', b'\xc9', b'\xca',
  ])
  let out = try! otsu_threshold(img)
  @debug.inspect(
    out.to_array(),
    content=(
      #|[
      #|  0x00,
      #|  0x00,
      #|  0x00,
      #|  0xff,
      #|  0xff,
      #|  0xff,
      #|]
    ),
  )
}

///|
#warnings("-deprecated")
test "adaptive threshold handles local shading around dark pixels" {
  let img = try! @image.gray_from_array(3, 3, [
    b'\x64', b'\x78', b'\x8c', b'\x64', b'\x3c', b'\x8c', b'\x64', b'\x78', b'\x8c',
  ])
  let out = try! adaptive_threshold_mean(img, 3, 20)
  @debug.inspect(
    out.to_array(),
    content=(
      #|[
      #|  0xff,
      #|  0xff,
      #|  0xff,
      #|  0xff,
      #|  0x00,
      #|  0xff,
      #|  0xff,
      #|  0xff,
      #|  0xff,
      #|]
    ),
  )
}

///|
#warnings("-deprecated")
test "invert and brightness are composable" {
  let img = try! @image.gray_from_array(3, 1, [b'\x00', b'\x40', b'\xff'])
  let inverted = try! invert(img)
  let brighter = try! adjust_brightness(inverted, 10)
  @debug.inspect(brighter.to_array(), content="[0xff, 0xc9, 0x0a]")
}
