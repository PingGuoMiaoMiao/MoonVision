///|
fn sample_gray() -> @image.GrayImage {
  try! @image.gray_from_array(3, 3, [
    b'\x0A', b'\x14', b'\x1E', b'\x28', b'\x32', b'\x3C', b'\x46', b'\x50', b'\x5A',
  ])
}

///|
test "convolve identity kernel keeps pixels unchanged" {
  let kernel = try! int_kernel(1, 1, [1])
  let out = try! convolve(sample_gray(), kernel)
  @debug.inspect(
    out.to_array(),
    content=(
      #|[
      #|  0x0a,
      #|  0x14,
      #|  0x1e,
      #|  0x28,
      #|  0x32,
      #|  0x3c,
      #|  0x46,
      #|  0x50,
      #|  0x5a,
      #|]
    ),
  )
}

///|
test "box blur uses border copy and preserves size" {
  let out = try! box_blur(sample_gray(), radius=1)
  inspect(out.width(), content="3")
  inspect(out.height(), content="3")
  @debug.inspect(
    out.to_array(),
    content=(
      #|[
      #|  0x17,
      #|  0x1e,
      #|  0x25,
      #|  0x2b,
      #|  0x32,
      #|  0x39,
      #|  0x3f,
      #|  0x46,
      #|  0x4d,
      #|]
    ),
  )
}

///|
test "gaussian blur and sharpen behave on simple inputs" {
  let gaussian = try! gaussian_blur(sample_gray(), radius=1)
  let sharpened = try! sharpen(gaussian)
  @debug.inspect(
    gaussian.to_array(),
    content=(
      #|[
      #|  0x14,
      #|  0x1c,
      #|  0x23,
      #|  0x2b,
      #|  0x32,
      #|  0x3a,
      #|  0x41,
      #|  0x49,
      #|  0x50,
      #|]
    ),
  )
  @debug.inspect(
    sharpened.to_array(),
    content=(
      #|[
      #|  0x00,
      #|  0x07,
      #|  0x13,
      #|  0x25,
      #|  0x30,
      #|  0x43,
      #|  0x4f,
      #|  0x61,
      #|  0x6d,
      #|]
    ),
  )
}

///|
test "median blur removes isolated salt noise" {
  let noisy = try! @image.gray_from_array(3, 3, [
    b'\x32', b'\x32', b'\x32', b'\x32', b'\xff', b'\x32', b'\x32', b'\x32', b'\x32',
  ])
  let out = try! median_blur(noisy, radius=1)
  @debug.inspect(
    out.to_array(),
    content=(
      #|[
      #|  0x32,
      #|  0x32,
      #|  0x32,
      #|  0x32,
      #|  0x32,
      #|  0x32,
      #|  0x32,
      #|  0x32,
      #|  0x32,
      #|]
    ),
  )
}
