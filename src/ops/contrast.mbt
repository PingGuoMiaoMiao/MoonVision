///|
pub fn adjust_contrast(
  img : @image.GrayImage,
  factor : Double,
) -> @image.GrayImage raise @image.ImageError {
  let out = img.copy()
  adjust_contrast_in_place(out, factor)
  out
}

///|
pub fn adjust_contrast_in_place(
  img : @image.GrayImage,
  factor : Double,
) -> Unit raise @image.ImageError {
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let shifted = img.get(x, y).to_int().to_double() - 128.0
      let next = shifted * factor + 128.0
      img.set(x, y, clamp_int_to_byte(next.to_int()))
    }
  }
}
