let output_dir = "examples/output/"
let asset_path = "examples/assets/object_counting_input.png"

fn write_rgb_png(path : String, img : @image.RgbImage) -> Unit {
  try! @demoio.write_bytes_to_file(path, @export.encode_rgb_png(img))
}

fn write_gray_png(path : String, img : @image.GrayImage) -> Unit {
  try! @demoio.write_bytes_to_file(path, @export.encode_gray_png(img))
}

fn main {
  let input = try! @image.rgb_from_png_bytes(try! @demoio.read_bytes_from_file(asset_path))
  let gray = try! @ops.grayscale(input)
  let baseline_binary = try! @ops.threshold(gray, 120)
  let smoothed = try! @filter.median_blur(gray, radius=1)
  let binary = try! @ops.otsu_threshold(smoothed)
  let baseline_components = try! @components.connected_components(
    baseline_binary,
    min_area=20,
  )
  let components = try! @components.connected_components(binary, min_area=20)

  let input_name = "object_counting_input.png"
  let baseline_binary_name = "object_counting_binary_v1_0.png"
  let binary_name = "object_counting_binary.png"
  let overlay_name = "object_counting_overlay.svg"
  let report_name = "object_counting_report.html"

  write_rgb_png(output_dir + input_name, input)
  write_gray_png(output_dir + baseline_binary_name, baseline_binary)
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
        "v1.0 pipeline: grayscale -> fixed threshold(120) -> connected components",
        "v1.1 pipeline: grayscale -> median blur(radius=1) -> otsu threshold -> connected components",
        "v1.0 detected objects: " + baseline_components.length().to_string(),
        "detected objects: " + components.length().to_string(),
        "input asset: " + asset_path,
        "minimum area filter: 20 pixels",
      ],
      [
        @export.report_image("input asset", input_name),
        @export.report_image("v1.0 binary mask", baseline_binary_name),
        @export.report_image("v1.1 binary mask", binary_name),
        @export.report_image("bounding box overlay", overlay_name),
      ],
    ),
  )

  println("v1.0 detected objects: " + baseline_components.length().to_string())
  println("v1.1 detected objects: " + components.length().to_string())
  println("report: " + output_dir + report_name)
}
