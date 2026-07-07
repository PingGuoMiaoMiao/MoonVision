///|
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
fn bilinear_source_position(
  index : Int,
  source_size : Int,
  target_size : Int,
) -> Int {
  if target_size == 1 {
    0
  } else {
    index * (source_size - 1)
  }
}

///|
pub fn resize_bilinear(
  img : GrayImage,
  new_width : Int,
  new_height : Int,
) -> GrayImage raise ImageError {
  validate_resize_dimensions(new_width, new_height)
  let out = gray(new_width, new_height)
  let denom_x = if new_width == 1 { 1 } else { new_width - 1 }
  let denom_y = if new_height == 1 { 1 } else { new_height - 1 }
  let denom = denom_x * denom_y
  for y = 0; y < new_height; y = y + 1 {
    let src_y_scaled = bilinear_source_position(y, img.height(), new_height)
    let y0 = src_y_scaled / denom_y
    let y1 = Int::min(y0 + 1, img.height() - 1)
    let wy = src_y_scaled % denom_y
    for x = 0; x < new_width; x = x + 1 {
      let src_x_scaled = bilinear_source_position(x, img.width(), new_width)
      let x0 = src_x_scaled / denom_x
      let x1 = Int::min(x0 + 1, img.width() - 1)
      let wx = src_x_scaled % denom_x
      let top_left = img.get(x0, y0).to_int()
      let top_right = img.get(x1, y0).to_int()
      let bottom_left = img.get(x0, y1).to_int()
      let bottom_right = img.get(x1, y1).to_int()
      let top = top_left * (denom_x - wx) + top_right * wx
      let bottom = bottom_left * (denom_x - wx) + bottom_right * wx
      let value = (top * (denom_y - wy) + bottom * wy + denom / 2) / denom
      out.set(x, y, clamp_byte(value))
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
