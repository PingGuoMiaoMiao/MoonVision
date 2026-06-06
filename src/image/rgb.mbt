///|
struct Rgb {
  r : Byte
  g : Byte
  b : Byte
} derive(Eq, Show)

///|
struct RgbImage {
  width : Int
  height : Int
  data : FixedArray[Byte]
} derive(Eq, Show)

///|
pub fn rgb_pixel(r : Byte, g : Byte, b : Byte) -> Rgb {
  { r, g, b }
}

fn RgbImage::rgb_index_of(self : RgbImage, x : Int, y : Int) -> Int raise ImageError {
  if x < 0 || y < 0 || x >= self.width || y >= self.height {
    raise OutOfBounds(x, y)
  }
  (y * self.width + x) * 3
}

///|
pub fn rgb(
  width : Int,
  height : Int,
  fill? : Rgb = rgb_pixel(b'\x00', b'\x00', b'\x00'),
) -> RgbImage raise ImageError {
  ensure_non_negative(width, height)
  let data = FixedArray::make(pixel_count_or_panic(width, height) * 3, b'\x00')
  for i = 0; i < width * height; i = i + 1 {
    let base = i * 3
    data[base] = fill.r
    data[base + 1] = fill.g
    data[base + 2] = fill.b
  }
  { width, height, data }
}

///|
pub fn rgb_from_array(
  width : Int,
  height : Int,
  pixels : Array[Byte],
) -> RgbImage raise ImageError {
  ensure_non_negative(width, height)
  let expected = pixel_count_or_panic(width, height) * 3
  if pixels.length() != expected {
    raise InvalidBufferLength(expected, pixels.length())
  }
  let data = FixedArray::make(expected, b'\x00')
  for i = 0; i < expected; i = i + 1 {
    data[i] = pixels[i]
  }
  { width, height, data }
}

///|
pub fn RgbImage::width(self : RgbImage) -> Int {
  self.width
}

///|
pub fn RgbImage::height(self : RgbImage) -> Int {
  self.height
}

///|
pub fn RgbImage::get(self : RgbImage, x : Int, y : Int) -> Rgb raise ImageError {
  let base = self.rgb_index_of(x, y)
  { r: self.data[base], g: self.data[base + 1], b: self.data[base + 2] }
}

///|
pub fn Rgb::r(self : Rgb) -> Byte {
  self.r
}

///|
pub fn Rgb::g(self : Rgb) -> Byte {
  self.g
}

///|
pub fn Rgb::b(self : Rgb) -> Byte {
  self.b
}

///|
pub fn RgbImage::set(
  self : RgbImage,
  x : Int,
  y : Int,
  value : Rgb,
) -> Unit raise ImageError {
  let base = self.rgb_index_of(x, y)
  self.data[base] = value.r
  self.data[base + 1] = value.g
  self.data[base + 2] = value.b
}

///|
pub fn RgbImage::copy(self : RgbImage) -> RgbImage {
  let copied = FixedArray::make(self.data.length(), b'\x00')
  for i = 0; i < self.data.length(); i = i + 1 {
    copied[i] = self.data[i]
  }
  { width: self.width, height: self.height, data: copied }
}
