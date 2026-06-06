fn sample_gray() -> @image.GrayImage {
  try! @image.gray_from_array(
    3,
    3,
    [
      b'\x0A',
      b'\x14',
      b'\x1E',
      b'\x28',
      b'\x32',
      b'\x3C',
      b'\x46',
      b'\x50',
      b'\x5A',
    ],
  )
}

///|
test "convolve identity kernel keeps pixels unchanged" {
  let kernel = try! int_kernel(1, 1, [1])
  let out = try! convolve(sample_gray(), kernel)
  inspect(
    out.to_array(),
    content=(
      "[b'\\x0A', b'\\x14', b'\\x1E', b'\\x28', b'\\x32', b'\\x3C', b'\\x46', b'\\x50', b'\\x5A']"
    ),
  )
}

///|
test "box blur uses border copy and preserves size" {
  let out = try! box_blur(sample_gray(), radius=1)
  inspect(out.width(), content="3")
  inspect(out.height(), content="3")
  inspect(
    out.to_array(),
    content=(
      "[b'\\x17', b'\\x1E', b'\\x25', b'\\x2B', b'\\x32', b'\\x39', b'\\x3F', b'\\x46', b'\\x4D']"
    ),
  )
}

///|
test "gaussian blur and sharpen behave on simple inputs" {
  let gaussian = try! gaussian_blur(sample_gray(), radius=1)
  let sharpened = try! sharpen(gaussian)
  inspect(
    gaussian.to_array(),
    content=(
      "[b'\\x14', b'\\x1C', b'\\x23', b'\\x2B', b'\\x32', b'\\x3A', b'\\x41', b'\\x49', b'\\x50']"
    ),
  )
  inspect(
    sharpened.to_array(),
    content=(
      "[b'\\x00', b'\\x07', b'\\x13', b'\\x25', b'\\x30', b'\\x43', b'\\x4F', b'\\x61', b'\\x6D']"
    ),
  )
}
