let output_dir = "examples/output/"
let asset_path = "examples/assets/object_counting_input.png"

fn write_rgb_png(path : String, img : @image.RgbImage) -> Unit {
  try! @demoio.write_bytes_to_file(path, @export.encode_rgb_png(img))
}

fn write_gray_png(path : String, img : @image.GrayImage) -> Unit {
  try! @demoio.write_bytes_to_file(path, @export.encode_gray_png(img))
}

fn contour_mask(
  width : Int,
  height : Int,
  contours : Array[@components.Contour],
) -> @image.GrayImage {
  let mask = try! @image.gray(width, height)
  // Debug note: contour masks make it easier to inspect whether the extracted
  // boundary pixels agree with the component count shown in the report.
  for contour in contours {
    for point in contour.points() {
      try! mask.set(point.x(), point.y(), b'\xff')
    }
  }
  mask
}

fn largest_contour_area(contours : Array[@components.Contour]) -> Int {
  let mut largest = 0
  for contour in contours {
    let area = @components.contour_area(contour)
    if area > largest {
      largest = area
    }
  }
  largest
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
  let contours = try! @components.find_contours(binary)
  let contour_image = contour_mask(binary.width(), binary.height(), contours)

  let input_name = "object_counting_input.png"
  let baseline_binary_name = "object_counting_binary_v1_0.png"
  let binary_name = "object_counting_binary.png"
  let contour_name = "object_counting_contours.png"
  let overlay_name = "object_counting_overlay.svg"
  let report_name = "object_counting_report.html"

  write_rgb_png(output_dir + input_name, input)
  write_gray_png(output_dir + baseline_binary_name, baseline_binary)
  write_gray_png(output_dir + binary_name, binary)
  write_gray_png(output_dir + contour_name, contour_image)
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
        "v1.2 contour analysis: find_contours(binary, connectivity=8) -> contour stats",
        "v1.0 detected objects: " + baseline_components.length().to_string(),
        "v1.1 detected objects: " + components.length().to_string(),
        "v1.2 contours: " + contours.length().to_string(),
        "largest contour area: " + largest_contour_area(contours).to_string(),
        "input asset: " + asset_path,
        "minimum area filter: 20 pixels",
      ],
      [
        @export.report_image("input asset", input_name),
        @export.report_image("v1.0 binary mask", baseline_binary_name),
        @export.report_image("v1.1 binary mask", binary_name),
        @export.report_image("v1.2 contour mask", contour_name),
        @export.report_image("bounding box overlay", overlay_name),
      ],
    ),
  )

  println("v1.0 detected objects: " + baseline_components.length().to_string())
  println("v1.1 detected objects: " + components.length().to_string())
  println("v1.2 contours: " + contours.length().to_string())
  println("report: " + output_dir + report_name)
}
