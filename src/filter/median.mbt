fn validate_median_radius(radius : Int) -> Unit raise @image.ImageError {
  if radius < 0 {
    raise @image.InvalidDimensions("median blur radius must not be negative")
  }
}

fn insertion_sort(values : Array[Int]) -> Unit {
  for i = 1; i < values.length(); i = i + 1 {
    let next = values[i]
    let mut j = i - 1
    while j >= 0 && values[j] > next {
      values[j + 1] = values[j]
      j = j - 1
    }
    values[j + 1] = next
  }
}

///|
pub fn median_blur(
  img : @image.GrayImage,
  radius? : Int = 1,
) -> @image.GrayImage raise @image.ImageError {
  validate_median_radius(radius)
  if radius == 0 {
    return img.copy()
  }

  let out = @image.gray(img.width(), img.height())
  let size = radius * 2 + 1
  let area = size * size
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let window = Array::make(area, 0)
      let mut index = 0
      for ky = y - radius; ky <= y + radius; ky = ky + 1 {
        for kx = x - radius; kx <= x + radius; kx = kx + 1 {
          window[index] = sample_with_border_copy(img, kx, ky).to_int()
          index = index + 1
        }
      }
      insertion_sort(window)
      out.set(x, y, window[area / 2].to_byte())
    }
  }
  out
}
