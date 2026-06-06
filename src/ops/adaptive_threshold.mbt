fn validate_block_size(block_size : Int) -> Unit raise @image.ImageError {
  if block_size <= 1 {
    raise @image.InvalidDimensions(
      "adaptive threshold block size must be greater than one",
    )
  }
  if block_size % 2 == 0 {
    raise @image.InvalidDimensions("adaptive threshold block size must be odd")
  }
}

fn clamp_coordinate(value : Int, upper_bound : Int) -> Int {
  if value < 0 {
    0
  } else if value >= upper_bound {
    upper_bound - 1
  } else {
    value
  }
}

fn adaptive_sample(
  img : @image.GrayImage,
  x : Int,
  y : Int,
) -> Byte raise @image.ImageError {
  img.get(clamp_coordinate(x, img.width()), clamp_coordinate(y, img.height()))
}

///|
pub fn adaptive_threshold_mean(
  img : @image.GrayImage,
  block_size : Int,
  c : Int,
) -> @image.GrayImage raise @image.ImageError {
  validate_block_size(block_size)
  let out = @image.gray(img.width(), img.height())
  let radius = block_size / 2

  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let mut local_sum = 0
      for ky = y - radius; ky <= y + radius; ky = ky + 1 {
        for kx = x - radius; kx <= x + radius; kx = kx + 1 {
          local_sum = local_sum + adaptive_sample(img, kx, ky).to_int()
        }
      }

      let local_mean = local_sum / (block_size * block_size)
      let next = if img.get(x, y).to_int() > local_mean - c {
        b'\xff'
      } else {
        b'\x00'
      }
      out.set(x, y, next)
    }
  }

  out
}
