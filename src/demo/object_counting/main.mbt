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

fn object_scene() -> @image.RgbImage {
  let img = try! @image.rgb(120, 90, fill=@image.rgb_pixel(b'\x08', b'\x0f', b'\x18'))
  try! fill_rect(img, 10, 10, 14, 16, @image.rgb_pixel(b'\xff', b'\xdb', b'\x70'))
  try! fill_rect(img, 34, 18, 18, 20, @image.rgb_pixel(b'\xff', b'\x9f', b'\x43'))
  try! fill_rect(img, 66, 14, 12, 28, @image.rgb_pixel(b'\xd8', b'\xff', b'\x84'))
  try! fill_rect(img, 20, 52, 24, 14, @image.rgb_pixel(b'\xa0', b'\xff', b'\xff'))
  try! fill_rect(img, 72, 56, 26, 18, @image.rgb_pixel(b'\xff', b'\xff', b'\xff'))
  try! img.set(105, 8, @image.rgb_pixel(b'\xff', b'\xff', b'\xff'))
  img
}

fn write_rgb_png(path : String, img : @image.RgbImage) -> Unit {
  try! @demoio.write_bytes_to_file(path, @export.encode_rgb_png(img))
}

fn write_gray_png(path : String, img : @image.GrayImage) -> Unit {
  try! @demoio.write_bytes_to_file(path, @export.encode_gray_png(img))
}

fn main {
  let input = object_scene()
  let gray = try! @ops.grayscale(input)
  let binary = try! @ops.threshold(gray, 120)
  let components = try! @components.connected_components(binary, min_area=20)

  let input_name = "object_counting_input.png"
  let binary_name = "object_counting_binary.png"
  let overlay_name = "object_counting_overlay.svg"
  let report_name = "object_counting_report.html"

  write_rgb_png(output_dir + input_name, input)
  write_gray_png(output_dir + binary_name, binary)
  try! @demoio.write_string_to_file(
    output_dir + overlay_name,
    @export.svg_bounding_boxes(binary.width(), binary.height(), components),
  )
  try! @demoio.write_string_to_file(
    output_dir + report_name,
    @export.html_report(
      "MoonVision Object Counting",
      [
        "pipeline: grayscale -> threshold -> connected components",
        "detected objects: " + components.length().to_string(),
        "minimum area filter: 20 pixels",
      ],
      [
        @export.report_image("synthetic input", input_name),
        @export.report_image("binary mask", binary_name),
        @export.report_image("bounding box overlay", overlay_name),
      ],
    ),
  )

  println("detected objects: " + components.length().to_string())
  println("report: " + output_dir + report_name)
}
