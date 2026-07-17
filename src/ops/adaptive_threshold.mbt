///|
fn validate_block_size(block_size : Int) -> Unit raise @image.ImageError {
  if block_size <= 1 {
    raise InvalidDimensions(
      "adaptive threshold block size must be greater than one",
    )
  }
  if block_size % 2 == 0 {
    raise InvalidDimensions("adaptive threshold block size must be odd")
  }
}

///|
fn clamp_coordinate(value : Int, upper_bound : Int) -> Int {
  if value < 0 {
    0
  } else if value >= upper_bound {
    upper_bound - 1
  } else {
    value
  }
}

///|
fn integral_index(stride : Int, x : Int, y : Int) -> Int {
  y * stride + x
}

///|
fn replicated_integral_image(
  img : @image.GrayImage,
  radius : Int,
) -> FixedArray[Int] {
  let padded_width = img.width() + radius * 2
  let padded_height = img.height() + radius * 2
  let stride = padded_width + 1
  let integral = FixedArray::make(stride * (padded_height + 1), 0)
  for py = 0; py < padded_height; py = py + 1 {
    for px = 0; px < padded_width; px = px + 1 {
      let source_x = clamp_coordinate(px - radius, img.width())
      let source_y = clamp_coordinate(py - radius, img.height())
      let value = (try! img.get(source_x, source_y)).to_int()
      let out_x = px + 1
      let out_y = py + 1
      let current = integral_index(stride, out_x, out_y)
      let left = integral_index(stride, out_x - 1, out_y)
      let up = integral_index(stride, out_x, out_y - 1)
      let diagonal = integral_index(stride, out_x - 1, out_y - 1)
      integral[current] = value +
        integral[left] +
        integral[up] -
        integral[diagonal]
    }
  }
  integral
}

///|
fn integral_sum(
  integral : FixedArray[Int],
  stride : Int,
  left : Int,
  top : Int,
  right : Int,
  bottom : Int,
) -> Int {
  integral[integral_index(stride, right, bottom)] -
  integral[integral_index(stride, left, bottom)] -
  integral[integral_index(stride, right, top)] +
  integral[integral_index(stride, left, top)]
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
  let padded_width = img.width() + radius * 2
  let stride = padded_width + 1
  let integral = replicated_integral_image(img, radius)
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let local_sum = integral_sum(
        integral,
        stride,
        x,
        y,
        x + block_size,
        y + block_size,
      )
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
