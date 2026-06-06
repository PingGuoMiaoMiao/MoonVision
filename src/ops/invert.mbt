///|
pub fn invert(img : @image.GrayImage) -> @image.GrayImage raise @image.ImageError {
  let out = img.copy()
  invert_in_place(out)
  out
}

///|
pub fn invert_in_place(img : @image.GrayImage) -> Unit raise @image.ImageError {
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      img.set(x, y, (255 - img.get(x, y).to_int()).to_byte())
    }
  }
}
