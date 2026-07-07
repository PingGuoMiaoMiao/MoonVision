///|
fn distance_index(width : Int, x : Int, y : Int) -> Int {
  y * width + x
}

///|
pub fn distance_transform_manhattan(
  img : @image.GrayImage,
) -> @image.GrayImage raise @image.ImageError {
  let width = img.width()
  let height = img.height()
  let max_distance = width + height + 1
  let distances = Array::make(img.pixel_count(), 0)
  for y = 0; y < height; y = y + 1 {
    for x = 0; x < width; x = x + 1 {
      let idx = distance_index(width, x, y)
      if img.get(x, y) == b'\x00' {
        distances[idx] = 0
      } else {
        distances[idx] = max_distance
      }
    }
  }
  for y = 0; y < height; y = y + 1 {
    for x = 0; x < width; x = x + 1 {
      let idx = distance_index(width, x, y)
      if distances[idx] == 0 {
        continue
      }
      let mut best = distances[idx]
      if x == 0 || y == 0 {
        best = 1
      }
      if x > 0 {
        best = Int::min(best, distances[distance_index(width, x - 1, y)] + 1)
      }
      if y > 0 {
        best = Int::min(best, distances[distance_index(width, x, y - 1)] + 1)
      }
      distances[idx] = best
    }
  }
  for y = height - 1; y >= 0; y = y - 1 {
    for x = width - 1; x >= 0; x = x - 1 {
      let idx = distance_index(width, x, y)
      if distances[idx] == 0 {
        continue
      }
      let mut best = distances[idx]
      if x == width - 1 || y == height - 1 {
        best = 1
      }
      if x + 1 < width {
        best = Int::min(best, distances[distance_index(width, x + 1, y)] + 1)
      }
      if y + 1 < height {
        best = Int::min(best, distances[distance_index(width, x, y + 1)] + 1)
      }
      distances[idx] = best
    }
  }
  let out = @image.gray(width, height)
  for y = 0; y < height; y = y + 1 {
    for x = 0; x < width; x = x + 1 {
      out.set(x, y, @image.clamp_byte(distances[distance_index(width, x, y)]))
    }
  }
  out
}

///|
pub fn max_distance(img : @image.GrayImage) -> Int raise @image.ImageError {
  let mut best = 0
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let value = img.get(x, y).to_int()
      if value > best {
        best = value
      }
    }
  }
  best
}
