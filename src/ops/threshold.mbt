fn ensure_threshold_in_range(threshold : Int) -> Unit raise @image.ImageError {
  if threshold < 0 || threshold > 255 {
    raise @image.InvalidDimensions("threshold must be in the range 0..255")
  }
}

///|
pub fn threshold(
  img : @image.GrayImage,
  threshold : Int,
  high? : Byte = b'\xff',
  low? : Byte = b'\x00',
) -> @image.GrayImage raise @image.ImageError {
  let out = img.copy()
  threshold_in_place(out, threshold, high=high, low=low)
  out
}

///|
pub fn threshold_in_place(
  img : @image.GrayImage,
  threshold : Int,
  high? : Byte = b'\xff',
  low? : Byte = b'\x00',
) -> Unit raise @image.ImageError {
  ensure_threshold_in_range(threshold)
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let next = if img.get(x, y).to_int() >= threshold { high } else { low }
      img.set(x, y, next)
    }
  }
}
