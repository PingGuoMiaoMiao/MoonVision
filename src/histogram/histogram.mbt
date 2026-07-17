///|
pub fn gray_histogram(
  img : @image.GrayImage,
) -> Array[Int] raise @image.ImageError {
  let bins = Array::make(256, 0)
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let value = img.get(x, y).to_int()
      bins[value] = bins[value] + 1
    }
  }
  bins
}

///|
pub fn cumulative_histogram(
  hist : Array[Int],
) -> Array[Int] raise @image.ImageError {
  if hist.length() != 256 {
    raise InvalidBufferLength(256, hist.length())
  }
  let out = Array::make(256, 0)
  let mut acc = 0
  for i = 0; i < 256; i = i + 1 {
    acc = acc + hist[i]
    out[i] = acc
  }
  out
}

///|
pub fn normalize_histogram(
  hist : Array[Int],
  scale : Int,
) -> Array[Int] raise @image.ImageError {
  if hist.length() != 256 {
    raise InvalidBufferLength(256, hist.length())
  }
  if scale < 0 {
    raise InvalidDimensions("histogram scale must be non-negative")
  }
  let mut max_count = 0
  for count in hist {
    if count > max_count {
      max_count = count
    }
  }
  let out = Array::make(256, 0)
  if max_count == 0 || scale == 0 {
    return out
  }
  for i = 0; i < 256; i = i + 1 {
    out[i] = (hist[i] * scale + max_count / 2) / max_count
  }
  out
}

///|
pub fn equalize_histogram(
  img : @image.GrayImage,
) -> @image.GrayImage raise @image.ImageError {
  let hist = gray_histogram(img)
  let cumulative = cumulative_histogram(hist)
  let total = img.pixel_count()
  let mut cdf_min = 0
  let mut found = false
  for i = 0; i < 256; i = i + 1 {
    if !found && cumulative[i] > 0 {
      cdf_min = cumulative[i]
      found = true
    }
  }
  let out = @image.gray(img.width(), img.height())
  let denominator = total - cdf_min
  if !found || denominator <= 0 {
    return out
  }
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let value = img.get(x, y).to_int()
      let mapped = ((cumulative[value] - cdf_min) * 255 + denominator / 2) /
        denominator
      out.set(x, y, @image.clamp_byte(mapped))
    }
  }
  out
}
