///|
fn morph_clamp_coordinate(value : Int, upper_bound : Int) -> Int {
  if value < 0 {
    0
  } else if value >= upper_bound {
    upper_bound - 1
  } else {
    value
  }
}

///|
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

///|
pub(all) enum StructuringElement {
  Square
  Cross
} derive(Eq, Show)

///|
fn validate_radius(radius : Int) -> Unit raise @image.ImageError {
  if radius < 0 {
    raise @image.InvalidDimensions("morphology radius must not be negative")
  }
}

///|
fn validate_iterations(iterations : Int) -> Unit raise @image.ImageError {
  if iterations < 0 {
    raise @image.InvalidDimensions("morphology iterations must not be negative")
  }
}

///|
fn in_structuring_element(
  dx : Int,
  dy : Int,
  element : StructuringElement,
) -> Bool {
  match element {
    Square => true
    Cross => dx == 0 || dy == 0
  }
}

///|
fn eroded_value(
  img : @image.GrayImage,
  x : Int,
  y : Int,
  radius : Int,
  element : StructuringElement,
) -> Byte raise @image.ImageError {
  for ky = y - radius; ky <= y + radius; ky = ky + 1 {
    for kx = x - radius; kx <= x + radius; kx = kx + 1 {
      if in_structuring_element(kx - x, ky - y, element) &&
        morph_sample(img, kx, ky) == b'\x00' {
        return b'\x00'
      }
    }
  }
  b'\xff'
}

///|
fn dilated_value(
  img : @image.GrayImage,
  x : Int,
  y : Int,
  radius : Int,
  element : StructuringElement,
) -> Byte raise @image.ImageError {
  for ky = y - radius; ky <= y + radius; ky = ky + 1 {
    for kx = x - radius; kx <= x + radius; kx = kx + 1 {
      if in_structuring_element(kx - x, ky - y, element) &&
        morph_sample(img, kx, ky) != b'\x00' {
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
  iterations? : Int = 1,
  element? : StructuringElement = Square,
) -> @image.GrayImage raise @image.ImageError {
  let out = img.copy()
  erode_in_place(out, radius~, iterations~, element~)
  out
}

///|
pub fn erode_in_place(
  img : @image.GrayImage,
  radius? : Int = 1,
  iterations? : Int = 1,
  element? : StructuringElement = Square,
) -> Unit raise @image.ImageError {
  validate_radius(radius)
  validate_iterations(iterations)
  for iter = 0; iter < iterations; iter = iter + 1 {
    let source = img.copy()
    for y = 0; y < img.height(); y = y + 1 {
      for x = 0; x < img.width(); x = x + 1 {
        img.set(x, y, eroded_value(source, x, y, radius, element))
      }
    }
  }
}

///|
pub fn dilate(
  img : @image.GrayImage,
  radius? : Int = 1,
  iterations? : Int = 1,
  element? : StructuringElement = Square,
) -> @image.GrayImage raise @image.ImageError {
  let out = img.copy()
  dilate_in_place(out, radius~, iterations~, element~)
  out
}

///|
pub fn dilate_in_place(
  img : @image.GrayImage,
  radius? : Int = 1,
  iterations? : Int = 1,
  element? : StructuringElement = Square,
) -> Unit raise @image.ImageError {
  validate_radius(radius)
  validate_iterations(iterations)
  for iter = 0; iter < iterations; iter = iter + 1 {
    let source = img.copy()
    for y = 0; y < img.height(); y = y + 1 {
      for x = 0; x < img.width(); x = x + 1 {
        img.set(x, y, dilated_value(source, x, y, radius, element))
      }
    }
  }
}

///|
pub fn open_binary(
  img : @image.GrayImage,
  radius? : Int = 1,
  iterations? : Int = 1,
  element? : StructuringElement = Square,
) -> @image.GrayImage raise @image.ImageError {
  dilate(
    erode(img, radius~, iterations~, element~),
    radius~,
    iterations~,
    element~,
  )
}

///|
pub fn close_binary(
  img : @image.GrayImage,
  radius? : Int = 1,
  iterations? : Int = 1,
  element? : StructuringElement = Square,
) -> @image.GrayImage raise @image.ImageError {
  erode(
    dilate(img, radius~, iterations~, element~),
    radius~,
    iterations~,
    element~,
  )
}

///|
pub fn morphological_gradient(
  img : @image.GrayImage,
  radius? : Int = 1,
  element? : StructuringElement = Square,
) -> @image.GrayImage raise @image.ImageError {
  let dilated = dilate(img, radius~, element~)
  let eroded = erode(img, radius~, element~)
  let out = @image.gray(img.width(), img.height())
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let value = if dilated.get(x, y) != eroded.get(x, y) {
        b'\xff'
      } else {
        b'\x00'
      }
      out.set(x, y, value)
    }
  }
  out
}

///|
pub fn top_hat(
  img : @image.GrayImage,
  radius? : Int = 1,
  element? : StructuringElement = Square,
) -> @image.GrayImage raise @image.ImageError {
  let opened = open_binary(img, radius~, element~)
  let out = @image.gray(img.width(), img.height())
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let value = if img.get(x, y) != b'\x00' && opened.get(x, y) == b'\x00' {
        b'\xff'
      } else {
        b'\x00'
      }
      out.set(x, y, value)
    }
  }
  out
}

///|
pub fn black_hat(
  img : @image.GrayImage,
  radius? : Int = 1,
  element? : StructuringElement = Square,
) -> @image.GrayImage raise @image.ImageError {
  let closed = close_binary(img, radius~, element~)
  let out = @image.gray(img.width(), img.height())
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let value = if closed.get(x, y) != b'\x00' && img.get(x, y) == b'\x00' {
        b'\xff'
      } else {
        b'\x00'
      }
      out.set(x, y, value)
    }
  }
  out
}
