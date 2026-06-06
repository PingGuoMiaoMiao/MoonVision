///|
struct IntKernel {
  width : Int
  height : Int
  data : Array[Int]
  divisor : Int
  bias : Int
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

fn rounded_div(acc : Int, divisor : Int) -> Int {
  if divisor == 0 {
    acc
  } else if acc >= 0 {
    (acc + divisor / 2) / divisor
  } else {
    -((-acc + divisor / 2) / divisor)
  }
}

fn kernel_area(width : Int, height : Int) -> Int {
  width * height
}

fn validate_kernel_shape(
  width : Int,
  height : Int,
  actual_len : Int,
) -> Unit raise @image.ImageError {
  if width <= 0 || height <= 0 {
    raise @image.InvalidDimensions(
      "kernel width and height must both be greater than zero",
    )
  }
  if width % 2 == 0 || height % 2 == 0 {
    raise @image.InvalidDimensions("kernel width and height must both be odd")
  }
  let expected = kernel_area(width, height)
  if actual_len != expected {
    raise @image.InvalidBufferLength(expected, actual_len)
  }
}

///|
pub fn int_kernel(
  width : Int,
  height : Int,
  values : Array[Int],
  divisor? : Int = 1,
  bias? : Int = 0,
) -> IntKernel raise @image.ImageError {
  validate_kernel_shape(width, height, values.length())
  if divisor == 0 {
    raise @image.InvalidDimensions("kernel divisor must not be zero")
  }
  { width, height, data: values, divisor, bias }
}

fn sample_with_border_copy(
  img : @image.GrayImage,
  x : Int,
  y : Int,
) -> Byte raise @image.ImageError {
  img.get(clamp_coordinate(x, img.width()), clamp_coordinate(y, img.height()))
}

///|
pub fn convolve(
  img : @image.GrayImage,
  kernel : IntKernel,
) -> @image.GrayImage raise @image.ImageError {
  let out = @image.gray(img.width(), img.height())
  let half_w = kernel.width / 2
  let half_h = kernel.height / 2
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let mut acc = 0
      for ky = 0; ky < kernel.height; ky = ky + 1 {
        for kx = 0; kx < kernel.width; kx = kx + 1 {
          let pixel = sample_with_border_copy(img, x + kx - half_w, y + ky - half_h)
          let weight = kernel.data[ky * kernel.width + kx]
          acc = acc + pixel.to_int() * weight
        }
      }
      let normalized = rounded_div(acc, kernel.divisor) + kernel.bias
      out.set(x, y, @image.clamp_byte(normalized))
    }
  }
  out
}
