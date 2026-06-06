fn binomial_row(order : Int) -> Array[Int] {
  let row = Array::make(order + 1, 1)
  for i = 1; i < order; i = i + 1 {
    row[i] = row[i - 1] * (order - i + 1) / i
  }
  row
}

fn gaussian_kernel_for_radius(radius : Int) -> IntKernel raise @image.ImageError {
  if radius < 0 {
    raise @image.InvalidDimensions("gaussian blur radius must not be negative")
  }
  let order = radius * 2
  let row = binomial_row(order)
  let size = radius * 2 + 1
  let values = []
  let mut divisor = 0
  for y = 0; y < size; y = y + 1 {
    for x = 0; x < size; x = x + 1 {
      let weight = row[y] * row[x]
      values.push(weight)
      divisor = divisor + weight
    }
  }
  int_kernel(size, size, values, divisor=divisor)
}

///|
pub fn gaussian_blur(
  img : @image.GrayImage,
  radius? : Int = 1,
) -> @image.GrayImage raise @image.ImageError {
  convolve(img, gaussian_kernel_for_radius(radius))
}
