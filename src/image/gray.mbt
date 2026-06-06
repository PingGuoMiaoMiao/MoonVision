///|
pub(all) suberror ImageError {
  InvalidDimensions(String)
  InvalidBufferLength(Int, Int)
  OutOfBounds(Int, Int)
} derive(Eq, Show)

///|
struct GrayImage {
  width : Int
  height : Int
  data : FixedArray[Byte]
} derive(Eq, Show)

fn ensure_non_negative(width : Int, height : Int) -> Unit raise ImageError {
  if width <= 0 || height <= 0 {
    raise InvalidDimensions(
      "image width and height must both be greater than zero",
    )
  }
}

fn pixel_count_or_panic(width : Int, height : Int) -> Int {
  width * height
}

fn GrayImage::index_of(self : GrayImage, x : Int, y : Int) -> Int raise ImageError {
  if x < 0 || y < 0 || x >= self.width || y >= self.height {
    raise OutOfBounds(x, y)
  }
  y * self.width + x
}

///|
pub fn gray(width : Int, height : Int, fill? : Byte = b'\x00') -> GrayImage raise ImageError {
  ensure_non_negative(width, height)
  {
    width,
    height,
    data: FixedArray::make(pixel_count_or_panic(width, height), fill),
  }
}

///|
pub fn gray_from_array(
  width : Int,
  height : Int,
  pixels : Array[Byte],
) -> GrayImage raise ImageError {
  ensure_non_negative(width, height)
  let expected = pixel_count_or_panic(width, height)
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
pub fn GrayImage::width(self : GrayImage) -> Int {
  self.width
}

///|
pub fn GrayImage::height(self : GrayImage) -> Int {
  self.height
}

///|
pub fn GrayImage::pixel_count(self : GrayImage) -> Int {
  self.width * self.height
}

///|
pub fn GrayImage::get(self : GrayImage, x : Int, y : Int) -> Byte raise ImageError {
  self.data[self.index_of(x, y)]
}

///|
pub fn GrayImage::set(
  self : GrayImage,
  x : Int,
  y : Int,
  value : Byte,
) -> Unit raise ImageError {
  self.data[self.index_of(x, y)] = value
}

///|
pub fn GrayImage::fill(self : GrayImage, value : Byte) -> Unit {
  for i = 0; i < self.data.length(); i = i + 1 {
    self.data[i] = value
  }
}

///|
pub fn GrayImage::copy(self : GrayImage) -> GrayImage {
  let copied = FixedArray::make(self.data.length(), b'\x00')
  for i = 0; i < self.data.length(); i = i + 1 {
    copied[i] = self.data[i]
  }
  { width: self.width, height: self.height, data: copied }
}

///|
pub fn GrayImage::to_array(self : GrayImage) -> Array[Byte] {
  Array::makei(self.data.length(), fn(i) { self.data[i] })
}
