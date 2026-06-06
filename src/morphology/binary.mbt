fn morph_clamp_coordinate(value : Int, upper_bound : Int) -> Int {
  if value < 0 {
    0
  } else if value >= upper_bound {
    upper_bound - 1
  } else {
    value
  }
}

fn morph_sample(
  img : @image.GrayImage,
  x : Int,
  y : Int,
) -> Byte raise @image.ImageError {
  img.get(
    morph_clamp_coordinate(x, img.width()),
    morph_clamp_coordinate(y, img.height()),
  )
}

fn validate_radius(radius : Int) -> Unit raise @image.ImageError {
  if radius < 0 {
    raise @image.InvalidDimensions("morphology radius must not be negative")
  }
}

fn eroded_value(
  img : @image.GrayImage,
  x : Int,
  y : Int,
  radius : Int,
) -> Byte raise @image.ImageError {
  for ky = y - radius; ky <= y + radius; ky = ky + 1 {
    for kx = x - radius; kx <= x + radius; kx = kx + 1 {
      if morph_sample(img, kx, ky) == b'\x00' {
        return b'\x00'
      }
    }
  }
  b'\xff'
}

fn dilated_value(
  img : @image.GrayImage,
  x : Int,
  y : Int,
  radius : Int,
) -> Byte raise @image.ImageError {
  for ky = y - radius; ky <= y + radius; ky = ky + 1 {
    for kx = x - radius; kx <= x + radius; kx = kx + 1 {
      if morph_sample(img, kx, ky) != b'\x00' {
        return b'\xff'
      }
    }
  }
  b'\x00'
}

///|
pub fn erode(
  img : @image.GrayImage,
  radius? : Int = 1,
) -> @image.GrayImage raise @image.ImageError {
  let out = img.copy()
  erode_in_place(out, radius=radius)
  out
}

///|
pub fn erode_in_place(
  img : @image.GrayImage,
  radius? : Int = 1,
) -> Unit raise @image.ImageError {
  validate_radius(radius)
  let source = img.copy()
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      img.set(x, y, eroded_value(source, x, y, radius))
    }
  }
}

///|
pub fn dilate(
  img : @image.GrayImage,
  radius? : Int = 1,
) -> @image.GrayImage raise @image.ImageError {
  let out = img.copy()
  dilate_in_place(out, radius=radius)
  out
}

///|
pub fn dilate_in_place(
  img : @image.GrayImage,
  radius? : Int = 1,
) -> Unit raise @image.ImageError {
  validate_radius(radius)
  let source = img.copy()
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      img.set(x, y, dilated_value(source, x, y, radius))
    }
  }
}

///|
pub fn open_binary(
  img : @image.GrayImage,
  radius? : Int = 1,
) -> @image.GrayImage raise @image.ImageError {
  dilate(erode(img, radius=radius), radius=radius)
}

///|
pub fn close_binary(
  img : @image.GrayImage,
  radius? : Int = 1,
) -> @image.GrayImage raise @image.ImageError {
  erode(dilate(img, radius=radius), radius=radius)
}
