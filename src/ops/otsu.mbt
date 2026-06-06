fn histogram_for_gray(
  img : @image.GrayImage,
) -> FixedArray[Int] raise @image.ImageError {
  let histogram : FixedArray[Int] = FixedArray::make(256, 0)
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let value = img.get(x, y).to_int()
      histogram[value] = histogram[value] + 1
    }
  }
  histogram
}

fn otsu_threshold_level(img : @image.GrayImage) -> Int raise @image.ImageError {
  let histogram = histogram_for_gray(img)
  let mut total_sum = 0.0
  for i = 0; i < 256; i = i + 1 {
    total_sum = total_sum + i.to_double() * histogram[i].to_double()
  }

  let total_pixels = img.pixel_count().to_double()
  let mut background_weight = 0.0
  let mut background_sum = 0.0
  let mut best_threshold = 0
  let mut best_variance = -1.0

  for threshold = 0; threshold < 255; threshold = threshold + 1 {
    let count = histogram[threshold].to_double()
    background_weight = background_weight + count
    background_sum = background_sum + threshold.to_double() * count

    if background_weight == 0.0 {
      continue
    }

    let foreground_weight = total_pixels - background_weight
    if foreground_weight == 0.0 {
      break
    }

    let background_mean = background_sum / background_weight
    let foreground_mean = (total_sum - background_sum) / foreground_weight
    let mean_gap = background_mean - foreground_mean
    let variance = background_weight * foreground_weight * mean_gap * mean_gap

    if variance > best_variance {
      best_variance = variance
      best_threshold = threshold
    }
  }

  best_threshold
}

///|
pub fn otsu_threshold(img : @image.GrayImage) -> @image.GrayImage raise @image.ImageError {
  threshold(img, otsu_threshold_level(img) + 1)
}
