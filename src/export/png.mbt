fn gray_to_rgba_bytes(img : @image.GrayImage) -> Bytes {
  let rgba = FixedArray::make(img.pixel_count() * 4, b'\x00')
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let value = try! img.get(x, y)
      let base = (y * img.width() + x) * 4
      rgba[base] = value
      rgba[base + 1] = value
      rgba[base + 2] = value
      rgba[base + 3] = b'\xff'
    }
  }
  Bytes::from_array(rgba)
}

fn rgb_to_rgba_bytes(img : @image.RgbImage) -> Bytes {
  let rgba = FixedArray::make(img.width() * img.height() * 4, b'\x00')
  for y = 0; y < img.height(); y = y + 1 {
    for x = 0; x < img.width(); x = x + 1 {
      let pixel = try! img.get(x, y)
      let base = (y * img.width() + x) * 4
      rgba[base] = pixel.r()
      rgba[base + 1] = pixel.g()
      rgba[base + 2] = pixel.b()
      rgba[base + 3] = b'\xff'
    }
  }
  Bytes::from_array(rgba)
}

///|
pub fn gray_to_image_data(
  img : @image.GrayImage,
) -> @codec.ImageData {
  {
    width: img.width(),
    height: img.height(),
    data: gray_to_rgba_bytes(img),
  }
}

///|
pub fn rgb_to_image_data(
  img : @image.RgbImage,
) -> @codec.ImageData {
  {
    width: img.width(),
    height: img.height(),
    data: rgb_to_rgba_bytes(img),
  }
}

///|
pub fn encode_gray_png(
  img : @image.GrayImage,
) -> Bytes {
  try! @codec.encode_png(gray_to_image_data(img))
}

///|
pub fn encode_rgb_png(
  img : @image.RgbImage,
) -> Bytes {
  try! @codec.encode_png(rgb_to_image_data(img))
}
