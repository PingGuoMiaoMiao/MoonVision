///|
pub fn sharpen(img : @image.GrayImage) -> @image.GrayImage raise @image.ImageError {
  let kernel = int_kernel(
    3,
    3,
    [0, -1, 0, -1, 5, -1, 0, -1, 0],
  )
  convolve(img, kernel)
}
