fn uniform_kernel_values(size : Int) -> Array[Int] {
  Array::make(size * size, 1)
}

///|
pub fn box_blur(
  img : @image.GrayImage,
  radius? : Int = 1,
) -> @image.GrayImage raise @image.ImageError {
  if radius < 0 {
    raise @image.InvalidDimensions("box blur radius must not be negative")
  }
  let size = radius * 2 + 1
  let kernel = int_kernel(
    size,
    size,
    uniform_kernel_values(size),
    divisor=size * size,
  )
  convolve(img, kernel)
}
