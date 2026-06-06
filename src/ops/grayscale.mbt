fn clamp_int_to_byte(value : Int) -> Byte {
  if value < 0 {
    b'\x00'
  } else if value > 255 {
    b'\xff'
  } else {
    value.to_byte()
  }
}

///|
pub fn grayscale(rgb : @image.RgbImage) -> @image.GrayImage raise @image.ImageError {
  let out = @image.gray(rgb.width(), rgb.height())
  for y = 0; y < rgb.height(); y = y + 1 {
    for x = 0; x < rgb.width(); x = x + 1 {
      let pixel = rgb.get(x, y)
      let value = (299 * pixel.r().to_int() + 587 * pixel.g().to_int() +
        114 * pixel.b().to_int() + 500) /
        1000
      out.set(x, y, clamp_int_to_byte(value))
    }
  }
  out
}
