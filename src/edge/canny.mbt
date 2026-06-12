fn edge_index(width : Int, x : Int, y : Int) -> Int {
  y * width + x
}

fn validate_canny_thresholds(
  low_threshold : Int,
  high_threshold : Int,
) -> Unit raise @image.ImageError {
  if low_threshold < 0 || low_threshold > 255 {
    raise @image.InvalidDimensions("canny low_threshold must be in the range 0..255")
  }
  if high_threshold < 0 || high_threshold > 255 {
    raise @image.InvalidDimensions("canny high_threshold must be in the range 0..255")
  }
  if low_threshold >= high_threshold {
    raise @image.InvalidDimensions(
      "canny low_threshold must be less than high_threshold",
    )
  }
}

fn direction_bucket(gx : Int, gy : Int) -> Int {
  let ax = Int::abs(gx)
  let ay = Int::abs(gy)
  if ay * 100 <= ax * 41 {
    0
  } else if ay * 100 >= ax * 241 {
    90
  } else if (gx >= 0 && gy >= 0) || (gx < 0 && gy < 0) {
    45
  } else {
    135
  }
}

fn neighbor_magnitude(
  magnitudes : Array[Int],
  width : Int,
  height : Int,
  x : Int,
  y : Int,
) -> Int {
  if x < 0 || y < 0 || x >= width || y >= height {
    0
  } else {
    magnitudes[edge_index(width, x, y)]
  }
}

///|
pub fn canny_edges(
  img : @image.GrayImage,
  low_threshold : Int,
  high_threshold : Int,
) -> @image.GrayImage raise @image.ImageError {
  validate_canny_thresholds(low_threshold, high_threshold)

  let width = img.width()
  let height = img.height()
  let pixel_count = img.pixel_count()
  let magnitudes = Array::make(pixel_count, 0)
  let directions = Array::make(pixel_count, 0)

  for y = 0; y < height; y = y + 1 {
    for x = 0; x < width; x = x + 1 {
      let pair = sobel_pair_at(img, x, y)
      let gx = pair.gx.to_double()
      let gy = pair.gy.to_double()
      let magnitude = (gx * gx + gy * gy).sqrt()
      let idx = edge_index(width, x, y)
      magnitudes[idx] = (magnitude + 0.5).to_int()
      directions[idx] = direction_bucket(pair.gx, pair.gy)
    }
  }

  let suppressed = Array::make(pixel_count, 0)
  for y = 0; y < height; y = y + 1 {
    for x = 0; x < width; x = x + 1 {
      let idx = edge_index(width, x, y)
      let magnitude = magnitudes[idx]
      let (left_x, left_y, right_x, right_y) = match directions[idx] {
        0 => (x - 1, y, x + 1, y)
        45 => (x - 1, y - 1, x + 1, y + 1)
        90 => (x, y - 1, x, y + 1)
        _ => (x - 1, y + 1, x + 1, y - 1)
      }
      let left = neighbor_magnitude(magnitudes, width, height, left_x, left_y)
      let right = neighbor_magnitude(magnitudes, width, height, right_x, right_y)
      suppressed[idx] = if magnitude > left && magnitude >= right {
        magnitude
      } else {
        0
      }
    }
  }

  let states = Array::make(pixel_count, 0)
  let stack_xs = []
  let stack_ys = []
  for y = 0; y < height; y = y + 1 {
    for x = 0; x < width; x = x + 1 {
      let idx = edge_index(width, x, y)
      let magnitude = suppressed[idx]
      if magnitude >= high_threshold {
        states[idx] = 2
        stack_xs.push(x)
        stack_ys.push(y)
      } else if magnitude >= low_threshold {
        states[idx] = 1
      }
    }
  }

  // Debug note: hysteresis grows only from strong edges so weak responses survive
  // only when they are actually connected to a confident edge segment.
  while stack_xs.length() > 0 {
    let last = stack_xs.length() - 1
    let x = stack_xs[last]
    let y = stack_ys[last]
    ignore(stack_xs.pop())
    ignore(stack_ys.pop())
    for ny = y - 1; ny <= y + 1; ny = ny + 1 {
      for nx = x - 1; nx <= x + 1; nx = nx + 1 {
        if nx == x && ny == y {
          continue
        }
        if nx < 0 || ny < 0 || nx >= width || ny >= height {
          continue
        }
        let neighbor_idx = edge_index(width, nx, ny)
        if states[neighbor_idx] == 1 {
          states[neighbor_idx] = 2
          stack_xs.push(nx)
          stack_ys.push(ny)
        }
      }
    }
  }

  let out = @image.gray(width, height)
  for y = 0; y < height; y = y + 1 {
    for x = 0; x < width; x = x + 1 {
      let value = if states[edge_index(width, x, y)] == 2 {
        b'\xff'
      } else {
        b'\x00'
      }
      out.set(x, y, value)
    }
  }
  out
}
