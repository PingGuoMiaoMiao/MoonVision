///|
pub fn adjust_brightness(
  img : @image.GrayImage,
  delta : Int,
) -> @image.GrayImage raise @image.ImageError {
  let out = img.copy()
  adjust_brightness_in_place(out, delta)
  out
}

///|
pub fn adjust_brightness_in_place(
  img : @image.GrayImage,
  delta : Int,
) -> Unit raise @image.ImageError {
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let next = img.get(x, y).to_int() + delta
      img.set(x, y, clamp_int_to_byte(next))
    }
  }
}
