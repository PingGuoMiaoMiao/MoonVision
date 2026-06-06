fn validate_resize_dimensions(
  new_width : Int,
  new_height : Int,
) -> Unit raise ImageError {
  if new_width <= 0 || new_height <= 0 {
    raise InvalidDimensions(
      "resize width and height must both be greater than zero",
    )
  }
}

///|
pub fn resize_nearest(
  img : GrayImage,
  new_width : Int,
  new_height : Int,
) -> GrayImage raise ImageError {
  validate_resize_dimensions(new_width, new_height)
  let out = gray(new_width, new_height)
  for y = 0; y < new_height; y = y + 1 {
    let src_y = y * img.height() / new_height
    for x = 0; x < new_width; x = x + 1 {
      let src_x = x * img.width() / new_width
      out.set(x, y, img.get(src_x, src_y))
    }
  }
  out
}

///|
pub fn flip_horizontal(img : GrayImage) -> GrayImage raise ImageError {
  let out = gray(img.width(), img.height())
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      out.set(img.width() - 1 - x, y, img.get(x, y))
    }
  }
  out
}

///|
pub fn flip_vertical(img : GrayImage) -> GrayImage raise ImageError {
  let out = gray(img.width(), img.height())
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      out.set(x, img.height() - 1 - y, img.get(x, y))
    }
  }
  out
}

///|
pub fn rotate90_cw(img : GrayImage) -> GrayImage raise ImageError {
  let out = gray(img.height(), img.width())
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      out.set(img.height() - 1 - y, x, img.get(x, y))
    }
  }
  out
}

///|
pub fn rotate90_ccw(img : GrayImage) -> GrayImage raise ImageError {
  let out = gray(img.height(), img.width())
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      out.set(y, img.width() - 1 - x, img.get(x, y))
    }
  }
  out
}
