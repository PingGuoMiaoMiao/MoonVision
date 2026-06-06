let output_dir = "examples/output/"
let asset_path = "examples/assets/edge_detection_input.png"

fn write_rgb_png(path : String, img : @image.RgbImage) -> Unit {
  try! @demoio.write_bytes_to_file(path, @export.encode_rgb_png(img))
}

fn write_gray_png(path : String, img : @image.GrayImage) -> Unit {
  try! @demoio.write_bytes_to_file(path, @export.encode_gray_png(img))
}

fn main {
  let input = try! @image.rgb_from_png_bytes(try! @demoio.read_bytes_from_file(asset_path))
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
        "input asset: " + asset_path,
        "input size: " + input.width().to_string() + "x" + input.height().to_string(),
        "output: gradient magnitude edge map",
      ],
      [
        @export.report_image("input asset", input_name),
        @export.report_image("edge magnitude", edges_name),
      ],
    ),
  )

  println("edge detection output: " + output_dir + edges_name)
}
