let output_dir = "examples/output/"

fn fill_rect(
  img : @image.RgbImage,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  color : @image.Rgb,
) -> Unit raise @image.ImageError {
  for py = y; py < y + height; py = py + 1 {
    for px = x; px < x + width; px = px + 1 {
      img.set(px, py, color)
    }
  }
}

fn document_scene() -> @image.RgbImage {
  let img = try! @image.rgb(128, 96, fill=@image.rgb_pixel(b'\x52', b'\x5d', b'\x6b'))
  try! fill_rect(img, 18, 10, 92, 72, @image.rgb_pixel(b'\xe6', b'\xe1', b'\xd7'))
  try! fill_rect(img, 28, 22, 48, 5, @image.rgb_pixel(b'\x34', b'\x34', b'\x34'))
  try! fill_rect(img, 28, 32, 64, 4, @image.rgb_pixel(b'\x3a', b'\x3a', b'\x3a'))
  try! fill_rect(img, 28, 41, 58, 4, @image.rgb_pixel(b'\x3f', b'\x3f', b'\x3f'))
  try! fill_rect(img, 28, 50, 66, 4, @image.rgb_pixel(b'\x3c', b'\x3c', b'\x3c'))
  try! fill_rect(img, 28, 59, 38, 4, @image.rgb_pixel(b'\x38', b'\x38', b'\x38'))
  try! fill_rect(img, 84, 18, 14, 14, @image.rgb_pixel(b'\xb2', b'\xb2', b'\xb2'))
  try! img.set(24, 18, @image.rgb_pixel(b'\xff', b'\xff', b'\xff'))
  try! img.set(31, 46, @image.rgb_pixel(b'\xff', b'\xff', b'\xff'))
  try! img.set(76, 61, @image.rgb_pixel(b'\x10', b'\x10', b'\x10'))
  try! img.set(102, 70, @image.rgb_pixel(b'\xff', b'\xff', b'\xff'))
  img
}

fn write_rgb_png(path : String, img : @image.RgbImage) -> Unit {
  try! @demoio.write_bytes_to_file(path, @export.encode_rgb_png(img))
}

fn write_gray_png(path : String, img : @image.GrayImage) -> Unit {
  try! @demoio.write_bytes_to_file(path, @export.encode_gray_png(img))
}

fn main {
  let input = document_scene()
  let gray = try! @ops.grayscale(input)
  let boosted = try! @ops.adjust_brightness(gray, 12)
  let contrasted = try! @ops.adjust_contrast(boosted, 1.35)
  let thresholded = try! @ops.threshold(contrasted, 150)
  let opened = try! @morphology.open_binary(thresholded, radius=1)
  let enhanced = try! @morphology.close_binary(opened, radius=1)

  let input_name = "document_enhancement_input.png"
  let output_name = "document_enhancement_output.png"
  let report_name = "document_enhancement_report.html"

  write_rgb_png(output_dir + input_name, input)
  write_gray_png(output_dir + output_name, enhanced)
  try! @demoio.write_string_to_file(
    output_dir + report_name,
    @export.html_report(
      "MoonVision Document Enhancement",
      [
        "pipeline: grayscale -> brightness -> contrast -> threshold -> opening -> closing",
        "input size: 128x96",
        "output: denoised binary document",
      ],
      [
        @export.report_image("synthetic document photo", input_name),
        @export.report_image("enhanced document", output_name),
      ],
    ),
  )

  println("document enhancement output: " + output_dir + output_name)
}
