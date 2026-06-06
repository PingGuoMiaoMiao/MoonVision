priv struct SobelPair {
  gx : Int
  gy : Int
}

fn edge_clamp_coordinate(value : Int, upper_bound : Int) -> Int {
  if value < 0 {
    0
  } else if value >= upper_bound {
    upper_bound - 1
  } else {
    value
  }
}

fn edge_sample(
  img : @image.GrayImage,
  x : Int,
  y : Int,
) -> Byte raise @image.ImageError {
  img.get(
    edge_clamp_coordinate(x, img.width()),
    edge_clamp_coordinate(y, img.height()),
  )
}

fn sobel_pair_at(
  img : @image.GrayImage,
  x : Int,
  y : Int,
) -> SobelPair raise @image.ImageError {
  let p00 = edge_sample(img, x - 1, y - 1).to_int()
  let p01 = edge_sample(img, x, y - 1).to_int()
  let p02 = edge_sample(img, x + 1, y - 1).to_int()
  let p10 = edge_sample(img, x - 1, y).to_int()
  let p12 = edge_sample(img, x + 1, y).to_int()
  let p20 = edge_sample(img, x - 1, y + 1).to_int()
  let p21 = edge_sample(img, x, y + 1).to_int()
  let p22 = edge_sample(img, x + 1, y + 1).to_int()

  let gx = -p00 + p02 - 2 * p10 + 2 * p12 - p20 + p22
  let gy = p00 + 2 * p01 + p02 - p20 - 2 * p21 - p22
  { gx, gy }
}

fn validate_edge_threshold(threshold : Int) -> Unit raise @image.ImageError {
  if threshold < 0 || threshold > 255 {
    raise @image.InvalidDimensions("edge threshold must be in the range 0..255")
  }
}

///|
pub fn sobel_x(img : @image.GrayImage) -> @image.GrayImage raise @image.ImageError {
  let out = @image.gray(img.width(), img.height())
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let pair = sobel_pair_at(img, x, y)
      out.set(x, y, @image.clamp_byte(Int::abs(pair.gx)))
    }
  }
  out
}

///|
pub fn sobel_y(img : @image.GrayImage) -> @image.GrayImage raise @image.ImageError {
  let out = @image.gray(img.width(), img.height())
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let pair = sobel_pair_at(img, x, y)
      out.set(x, y, @image.clamp_byte(Int::abs(pair.gy)))
    }
  }
  out
}

///|
pub fn gradient_magnitude(
  img : @image.GrayImage,
) -> @image.GrayImage raise @image.ImageError {
  let out = @image.gray(img.width(), img.height())
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let pair = sobel_pair_at(img, x, y)
      let gx = pair.gx.to_double()
      let gy = pair.gy.to_double()
      let magnitude = (gx * gx + gy * gy).sqrt()
      out.set(x, y, @image.clamp_byte((magnitude + 0.5).to_int()))
    }
  }
  out
}

///|
pub fn edge_extract(
  img : @image.GrayImage,
  threshold? : Int = 128,
) -> @image.GrayImage raise @image.ImageError {
  validate_edge_threshold(threshold)
  let magnitude = gradient_magnitude(img)
  let out = @image.gray(img.width(), img.height())
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let value = if magnitude.get(x, y).to_int() >= threshold {
        b'\xff'
      } else {
        b'\x00'
      }
      out.set(x, y, value)
    }
  }
  out
}
