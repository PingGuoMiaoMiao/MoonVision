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

fn edge_scene() -> @image.RgbImage {
  let img = try! @image.rgb(128, 96, fill=@image.rgb_pixel(b'\x14', b'\x22', b'\x30'))
  try! fill_rect(img, 12, 12, 28, 56, @image.rgb_pixel(b'\xf4', b'\x6f', b'\x4f'))
  try! fill_rect(img, 52, 10, 50, 18, @image.rgb_pixel(b'\xff', b'\xec', b'\x99'))
  try! fill_rect(img, 60, 34, 26, 42, @image.rgb_pixel(b'\x8f', b'\xff', b'\xd4'))
  try! fill_rect(img, 94, 34, 12, 42, @image.rgb_pixel(b'\xff', b'\xff', b'\xff'))
  for i = 0; i < 24; i = i + 1 {
    try! fill_rect(img, 22 + i * 2, 74 - i, 2, 2, @image.rgb_pixel(b'\xff', b'\xff', b'\xff'))
  }
  img
}

fn write_rgb_png(path : String, img : @image.RgbImage) -> Unit {
  try! @demoio.write_bytes_to_file(path, @export.encode_rgb_png(img))
}

fn write_gray_png(path : String, img : @image.GrayImage) -> Unit {
  try! @demoio.write_bytes_to_file(path, @export.encode_gray_png(img))
}

fn main {
  let input = edge_scene()
  let gray = try! @ops.grayscale(input)
  let blurred = try! @filter.gaussian_blur(gray, radius=1)
  let edges = try! @edge.gradient_magnitude(blurred)

  let input_name = "edge_detection_input.png"
  let edges_name = "edge_detection_edges.png"
  let report_name = "edge_detection_report.html"

  write_rgb_png(output_dir + input_name, input)
  write_gray_png(output_dir + edges_name, edges)
  try! @demoio.write_string_to_file(
    output_dir + report_name,
    @export.html_report(
      "MoonVision Edge Detection",
      [
        "pipeline: grayscale -> gaussian blur -> sobel gradient magnitude",
        "input size: 128x96",
        "output: gradient magnitude edge map",
      ],
      [
        @export.report_image("synthetic input", input_name),
        @export.report_image("edge magnitude", edges_name),
      ],
    ),
  )

  println("edge detection output: " + output_dir + edges_name)
}
