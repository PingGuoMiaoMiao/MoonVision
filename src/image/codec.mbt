fn rgb_from_rgba_image_data(data : @codec.ImageData) -> RgbImage raise ImageError {
  let width = data.width
  let height = data.height
  let expected = width * height * 4
  if data.data.length() != expected {
    raise InvalidBufferLength(expected, data.data.length())
  }
  let rgb_data = FixedArray::make(width * height * 3, b'\x00')
  for i = 0; i < width * height; i = i + 1 {
    let src = i * 4
    let dst = i * 3
    rgb_data[dst] = data.data[src]
    rgb_data[dst + 1] = data.data[src + 1]
    rgb_data[dst + 2] = data.data[src + 2]
  }
  { width, height, data: rgb_data }
}

///|
pub fn rgb_from_png_bytes(data : Bytes) -> RgbImage raise @codec.DecodeError {
  let decoded = @codec.decode_png(data)
  try! rgb_from_rgba_image_data(decoded)
}
