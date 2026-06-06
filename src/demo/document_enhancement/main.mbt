let output_dir = "examples/output/"
let asset_path = "examples/assets/document_enhancement_input.png"

fn write_rgb_png(path : String, img : @image.RgbImage) -> Unit {
  try! @demoio.write_bytes_to_file(path, @export.encode_rgb_png(img))
}

fn write_gray_png(path : String, img : @image.GrayImage) -> Unit {
  try! @demoio.write_bytes_to_file(path, @export.encode_gray_png(img))
}

fn main {
  let input = try! @image.rgb_from_png_bytes(try! @demoio.read_bytes_from_file(asset_path))
  let gray = try! @ops.grayscale(input)
  let boosted = try! @ops.adjust_brightness(gray, 12)
  let contrasted = try! @ops.adjust_contrast(boosted, 1.35)
  let baseline_thresholded = try! @ops.threshold(contrasted, 150)
  let baseline_opened = try! @morphology.open_binary(baseline_thresholded, radius=1)
  let baseline_enhanced = try! @morphology.close_binary(baseline_opened, radius=1)
  let denoised = try! @filter.median_blur(contrasted, radius=1)
  let adaptive = try! @ops.adaptive_threshold_mean(denoised, 5, 7)
  let opened = try! @morphology.open_binary(adaptive, radius=1)
  let enhanced = try! @morphology.close_binary(opened, radius=1)

  let input_name = "document_enhancement_input.png"
  let baseline_name = "document_enhancement_output_v1_0.png"
  let output_name = "document_enhancement_output.png"
  let report_name = "document_enhancement_report.html"

  write_rgb_png(output_dir + input_name, input)
  write_gray_png(output_dir + baseline_name, baseline_enhanced)
  write_gray_png(output_dir + output_name, enhanced)
  try! @demoio.write_string_to_file(
    output_dir + report_name,
    @export.html_report(
      "MoonVision Document Enhancement",
      [
        "v1.0 pipeline: grayscale -> brightness -> contrast -> threshold(150) -> opening -> closing",
        "v1.1 pipeline: grayscale -> brightness -> contrast -> median blur(radius=1) -> adaptive threshold mean(block=5, c=7) -> opening -> closing",
        "input asset: " + asset_path,
        "input size: " + input.width().to_string() + "x" + input.height().to_string(),
        "comparison: v1.0 fixed threshold output is preserved alongside the optimized v1.1 output",
      ],
      [
        @export.report_image("input asset", input_name),
        @export.report_image("v1.0 enhanced document", baseline_name),
        @export.report_image("v1.1 enhanced document", output_name),
      ],
    ),
  )

  println("document enhancement output: " + output_dir + output_name)
}
