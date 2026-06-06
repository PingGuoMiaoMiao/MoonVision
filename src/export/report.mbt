struct ReportImage {
  label : String
  path : String
} derive(Eq, Show)

///|
pub fn report_image(label : String, path : String) -> ReportImage {
  { label, path }
}

///|
pub fn ReportImage::label(self : ReportImage) -> String {
  self.label
}

///|
pub fn ReportImage::path(self : ReportImage) -> String {
  self.path
}

///|
pub fn svg_bounding_boxes(
  width : Int,
  height : Int,
  components : Array[@components.Component],
  title? : String = "MoonVision Detection Overlay",
) -> String {
  let mut out =
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 " +
    width.to_string() +
    " " +
    height.to_string() +
    "\" width=\"" +
    width.to_string() +
    "\" height=\"" +
    height.to_string() +
    "\">\n  <title>" +
    title +
    "</title>\n"
  for component in components {
    let bbox = component.bbox()
    out = out +
      "  <rect x=\"" +
      bbox.x().to_string() +
      "\" y=\"" +
      bbox.y().to_string() +
      "\" width=\"" +
      bbox.width().to_string() +
      "\" height=\"" +
      bbox.height().to_string() +
      "\" fill=\"none\" stroke=\"#ff3b30\" stroke-width=\"1\" />\n" +
      "  <text x=\"" +
      bbox.x().to_string() +
      "\" y=\"" +
      Int::max(0, bbox.y() - 1).to_string() +
      "\" fill=\"#ff3b30\" font-size=\"4\">id=" +
      component.label_id().to_string() +
      " area=" +
      component.area().to_string() +
      "</text>\n"
  }
  out + "</svg>"
}

///|
pub fn html_report(
  title : String,
  summary_lines : Array[String],
  images : Array[ReportImage],
) -> String {
  let mut out =
    "<!doctype html>\n<html lang=\"en\">\n<head>\n" +
    "  <meta charset=\"utf-8\" />\n" +
    "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />\n" +
    "  <title>" +
    title +
    "</title>\n" +
    "  <style>\n" +
    "    body { font-family: \"Segoe UI\", sans-serif; margin: 24px; color: #1f2933; background: #f7fafc; }\n" +
    "    h1 { margin-bottom: 12px; }\n" +
    "    ul { padding-left: 20px; }\n" +
    "    .gallery { display: grid; gap: 16px; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); }\n" +
    "    figure { background: white; padding: 12px; border: 1px solid #d9e2ec; border-radius: 8px; }\n" +
    "    img { max-width: 100%; height: auto; display: block; background: #eef2f7; }\n" +
    "    figcaption { margin-bottom: 8px; font-weight: 600; }\n" +
    "  </style>\n" +
    "</head>\n<body>\n" +
    "  <h1>" +
    title +
    "</h1>\n" +
    "  <ul>\n"
  for line in summary_lines {
    out = out + "    <li>" + line + "</li>\n"
  }
  out = out + "  </ul>\n  <div class=\"gallery\">\n"
  for image in images {
    out = out +
      "    <figure>\n" +
      "      <figcaption>" +
      image.label() +
      "</figcaption>\n" +
      "      <img src=\"" +
      image.path() +
      "\" alt=\"" +
      image.label() +
      "\" />\n" +
      "    </figure>\n"
  }
  out + "  </div>\n</body>\n</html>"
}
